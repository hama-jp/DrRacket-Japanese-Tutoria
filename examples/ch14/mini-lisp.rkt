#lang racket

;; =================================================================
;; 小さな Lisp 処理系 (mini-lisp)
;;
;; このファイルだけで、以下をサポートする Lisp 方言が動きます。
;;
;;   - 数値・真偽値・文字列・シンボル
;;   - 変数束縛: (define x 10) / (define (f x) ...)
;;   - 関数    : (lambda (x y) (+ x y))
;;   - 分岐    : (if c a b)
;;   - 局所束縛: (let ([x 1] [y 2]) body ...)
;;   - クォート: 'foo, '(a b c)
;;   - 算術    : +, -, *, /, =, <, >
;;   - リスト  : cons, car, cdr, list, null?
;;
;; 全体像:
;;   (run program)         ; ← トップレベル。S 式のリストを順に処理
;;     └─> (mini-eval expr e)   ; ← 1 つの式 + 環境 → 値
;;           └─> (apply-proc f args) ; ← 関数呼び出しの実行
;;
;; Lisp インタプリタの王道設計で、「式と環境を受け取って値を返す
;; 関数 mini-eval」を中心に組み立てます。
;; =================================================================

;; match パターンマッチを使うので明示的に require する。
;; (#lang racket なら自動で読み込まれているが、意図を示すため書いておく)
(require racket/match)

;; -----------------------------------------------------------------
;; 環境 (environment)
;; -----------------------------------------------------------------
;; インタプリタの心臓部。「変数名 → 値」の対応表です。
;;
;; mini-lisp では 2 段構成の環境を持ちます。
;;
;;   frames  : 局所束縛のスタック。(let ...) や関数呼び出しで増える。
;;             各フレームは連想リスト ((name1 . value1) (name2 . value2) ...)
;;             で、これを list として重ねる: (frame1 frame2 frame3 ...)
;;
;;   globals : トップレベル定義用の mutable ハッシュ。
;;             (define ...) の結果や組み込み手続き (+, car, ...) を置く。
;;             mutable でないと「自分を呼ぶ再帰関数」が上手く動かない
;;             (クロージャを作った時点のスナップショットに自分が
;;             含まれないため)。
;;
;; #:transparent を付けると、デバッグ時に中身がそのまま表示され、
;; equal? も構造的に比較されるので便利。
(struct env (frames globals) #:transparent)

;; ルート環境を新しく作る。グローバルには組み込み手続きを先に登録。
;; シンボル '+ に Racket の関数 + を、のように紐付けておくと、
;; 評価器側では「変数参照」として処理できて特別扱いが不要になる。
(define (make-root-env)
  (define g (make-hash))
  (hash-set*! g
              ;; 算術系
              '+ + '- - '* * '/ /
              ;; 比較系
              '= = '< < '> >
              ;; リスト操作
              'cons cons 'car car 'cdr cdr 'list list
              ;; 述語 (predicates)
              'null? null? 'not not)
  ;; 初期状態では局所フレームは空 (`'()`)、globals だけが中身を持つ
  (env '() g))

;; 環境を 1 フレーム拡張する。
;; names と values は同じ長さのリスト。
;; 例: (extend-env e '(x y) '(10 20))
;;      → 一番手前に ((x . 10) (y . 20)) という連想リストが積まれる
(define (extend-env e names values)
  (env (cons (map cons names values) ; 新しいフレームを先頭に
             (env-frames e))          ; 既存のフレームはその後ろ
       (env-globals e)))              ; globals はそのまま共有

;; グローバルへの書き込み。(define ...) の実装で使う。
;; ハッシュが mutable なので破壊的更新。
(define (env-set-global! e name value)
  (hash-set! (env-globals e) name value))

;; 変数参照の処理。局所フレームを手前から探索し、なければ globals。
;;
;; cond の `=> cdr` は Scheme 由来の記法で、
;;   「テスト式の値が真なら、その値を関数に渡して呼ぶ」
;; という意味。つまり次と等価:
;;   [(assoc sym (car frames))
;;    => (lambda (matched) (cdr matched))]
;; assoc が見つけたペア (name . value) の value 側を取り出している。
;;
;; 全てのフレームに無ければグローバルを引き、そこにも無ければエラー。
;; hash-ref の第 3 引数に thunk (引数 0 の関数) を渡すと、
;; キーが無いときに呼ばれる「デフォルト生成」ハンドラになる。
(define (env-lookup e sym)
  (let loop ([frames (env-frames e)])
    (cond
      [(null? frames)
       (hash-ref (env-globals e) sym
                 (lambda () (error 'lookup "unbound: ~v" sym)))]
      [(assoc sym (car frames)) => cdr]
      [else (loop (cdr frames))])))

;; -----------------------------------------------------------------
;; 評価器 (evaluator)
;; -----------------------------------------------------------------
;; mini-eval: 式 expr と環境 e を受け取り、式の評価結果を返す中核関数。
;;
;; match の節は「上から順」にマッチングされる。よって
;;   ・自己評価式 (数値・真偽値・文字列)
;;   ・変数参照 (シンボル)
;;   ・特殊フォーム (quote, if, lambda, let)
;;   ・関数呼び出し (一般の cons)
;; の順に並べ、最後の「関数呼び出し」節が漏れを拾う構造にする。
;; 特殊フォームを関数呼び出しより後ろに書くと、`lambda` などの
;; シンボルが変数として解釈されてしまうので要注意。
(define (mini-eval expr e)
  (match expr
    ;; --- 自己評価式: 数値/真偽値/文字列はそれ自身が値 ---
    [(? number?)   expr]
    [(? boolean?)  expr]
    [(? string?)   expr]

    ;; --- 変数参照: シンボルは環境を引く ---
    [(? symbol?)   (env-lookup e expr)]

    ;; --- (quote datum): 評価せずそのまま返す ---
    ;; '(a b c) は reader により (quote (a b c)) に変換されている。
    [(list 'quote datum) datum]

    ;; --- (if c a b): 条件分岐。false のときだけ b、それ以外は a ---
    ;; Racket では #f だけが偽、それ以外 (0 や '() も!) は真。
    [(list 'if c a b)
     (if (mini-eval c e)
         (mini-eval a e)
         (mini-eval b e))]

    ;; --- (lambda (params...) body...): クロージャを作る ---
    ;; list* は「最後の要素がリスト」な cons 連鎖: 例えば
    ;;   (list* 'lambda params body) = (cons 'lambda (cons params body))
    ;; これで body には「本体式のリスト」がマッチする (複数式 OK)。
    ;;
    ;; クロージャ = ラムダ本体 + 「定義時点の環境 e」 をセットで
    ;; 保持したタグ付きリスト。タグ 'closure を付けることで apply-proc
    ;; 側で「ユーザ定義関数」と判別できる。
    [(list* 'lambda params body)
     (list 'closure params body e)]

    ;; --- (let ((x e1) (y e2) ...) body...): 局所束縛 ---
    ;; ポイント: 束縛式 e1, e2, ... は「現在の環境 e」で評価する
    ;; (= 同時束縛, Scheme の let と同じ動き)。本体は拡張後の環境で評価。
    ;; ※ もし「直前の束縛を後ろの束縛が使える」ようにしたければ let*。
    [(list* 'let bindings body)
     (define names (map car  bindings))                         ; 変数名のリスト
     (define vals  (map (lambda (b) (mini-eval (cadr b) e))     ; 右辺を評価
                        bindings))
     (eval-body body (extend-env e names vals))]

    ;; --- (f arg1 arg2 ...): 関数呼び出し ---
    ;; すべての特殊フォームにマッチしなかった cons はここに来る。
    ;; 引数を左から右に評価してから apply-proc に渡す (値呼び / eager)。
    [(cons f args)
     (apply-proc (mini-eval f e)
                 (map (lambda (a) (mini-eval a e)) args))]))

;; 関数やletの本体 (複数式の列) を順に評価し、最後の式の値を返す。
;; 途中の式は副作用目的なので値を捨てる。
(define (eval-body exprs e)
  (cond
    ;; 最後の 1 式: その評価結果を本体の値として返す
    [(null? (cdr exprs)) (mini-eval (car exprs) e)]
    ;; まだ続きがある: 今の式を評価 (値は捨てる) して再帰
    [else
     (mini-eval (car exprs) e)
     (eval-body (cdr exprs) e)]))

;; 関数適用。proc は 2 種類あり得る:
;;   1. ユーザ定義関数: ('closure params body captured-env) の 4 要素リスト
;;   2. 組み込み関数  : Racket の procedure そのまま
(define (apply-proc proc args)
  (match proc
    ;; ユーザ定義: クロージャ作成時の環境に、引数束縛を 1 フレーム
    ;; 積んで本体を評価する。これがレキシカルスコープの実装。
    [(list 'closure params body captured-env)
     (eval-body body (extend-env captured-env params args))]
    ;; 組み込み: Racket 側で apply を呼ぶだけで良い。
    [(? procedure?)
     (apply proc args)]
    ;; それ以外は「関数でないものを呼ぼうとしている」エラー
    [else (error 'apply "not a procedure: ~v" proc)]))

;; -----------------------------------------------------------------
;; トップレベル評価 (run)
;; -----------------------------------------------------------------
;; program はフォーム (= 式) のリスト。順に評価し、「最後の式の値」を返す。
;; for/last は各反復のうち最後の反復で評価された値を返す専用 for。
;;
;; define は「特殊フォームだがトップレベル限定」扱いにして、ここだけで
;; 処理してしまうのが楽。以下の 2 形をサポート:
;;
;;   (define (name params...) body...)   ; 関数定義 (短縮形)
;;   (define name expr)                   ; 値を名前に束縛する汎用形
;;
;; 前者は quasiquote を使って `(lambda ,params ,@body) を組み立て、
;; 結局ラムダを name に束縛するだけ = 糖衣構文であることが読める。
;; `,@body` は body というリストを「展開して埋め込む」記法。
(define (run program)
  (define e (make-root-env))
  (for/last ([form (in-list program)])
    (match form
      ;; (define (name p1 p2 ...) body ...) 形 ― 関数定義
      [(list 'define (cons name params) body ...)
       (env-set-global! e name
                        (mini-eval `(lambda ,params ,@body) e))
       (void)] ; define 自体の値は未定義 (void) にする
      ;; (define name expr) 形 ― 値の束縛
      [(list 'define name expr)
       (env-set-global! e name (mini-eval expr e))
       (void)]
      ;; それ以外は普通の式 → 評価して値を返す
      [else (mini-eval form e)])))

;; 他のファイルから利用できるようにエクスポート。
;; 評価器と環境操作関数も提供しておくと、第 15 章以降で
;; mini-lisp を Web から呼び出すときに再利用しやすい。
(provide run mini-eval make-root-env extend-env env-set-global!)

;; =================================================================
;; 使用例 — `racket mini-lisp.rkt` で実行されるモジュール
;; =================================================================
(module+ main
  ;; mini-lisp のプログラムは「S 式のリスト」。Racket のリーダが
  ;; ソースコードからリストへの変換を済ませてくれているので、
  ;; ここではクォートで書き下すだけで完成する。
  (define program
    '(;; 二乗関数
      (define (square x) (* x x))
      ;; 階乗 (再帰)。グローバルが mutable なので自分自身を呼べる
      (define (fact n)
        (if (< n 2) 1 (* n (fact (- n 1)))))
      ;; 組み込みに map は無いので自前で書く。これが動けば高階関数 OK
      (define (my-map f xs)
        (if (null? xs) '()
            (cons (f (car xs)) (my-map f (cdr xs)))))
      ;; プログラム全体の結果。この値が run の戻り値になる
      (list (square 7)
            (fact 6)
            (my-map square '(1 2 3 4 5)))))
  ;; 期待値: (49 720 (1 4 9 16 25))
  (displayln (run program)))

;; =================================================================
;; テスト — `raco test mini-lisp.rkt` で実行
;; =================================================================
(module+ test
  (require rackunit)
  ;; 組み込み + を可変長引数で呼ぶ
  (check-equal? (run '((+ 1 2 3))) 6)
  ;; ユーザ定義関数
  (check-equal? (run '((define (sq x) (* x x))
                       (sq 9))) 81)
  ;; 再帰 (相互再帰も同じ仕掛けで動く)
  (check-equal? (run '((define (fact n) (if (< n 2) 1 (* n (fact (- n 1)))))
                       (fact 6))) 720)
  ;; let による局所束縛
  (check-equal? (run '((let ([x 10] [y 20]) (+ x y)))) 30)
  ;; 即時呼び出し lambda (IIFE 的な書き方)
  (check-equal? (run '(((lambda (x) (* x x)) 7))) 49))
