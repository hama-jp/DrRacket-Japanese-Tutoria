# 第 17 章 発展トピック

ここまでで Racket の **基礎体力** は身に付きました。この章は次の学びへの橋渡しとして、強力だけど紙面の都合で深く追えなかった機能を、**雰囲気が掴める程度に** 並べます。どれも「章 1 つを使って語れる」テーマなので、興味を持ったものから公式ドキュメントへ潜ってみてください。

## 17.1 継続 — `call/cc`

**継続(continuation)** は「ここから先でするはずだった計算」を値として捉える仕組みです。`call/cc`(call-with-current-continuation)で、現在の継続を関数として受け取れます。

```text
> (call/cc (lambda (k) (+ 1 (k 42))))
42
```

- `k` は「この式の返り値の行き先」を表す関数
- `(k 42)` を呼ぶと、`call/cc` 全体が即座に `42` を返す
- `+ 1` は **飛ばされる**

### 早期 return 的な使い方

```racket
(define (find-first pred xs)
  (call/cc
   (lambda (return)
     (for ([x (in-list xs)])
       (when (pred x) (return x)))
     #f)))
```

```text
> (find-first even? '(1 3 5 4 7))
4
> (find-first negative? '(1 2 3))
#f
```

他言語の `return` 文のように、ループの途中で抜けられます。

### なぜ継続が強力か

「`call/cc` で得た `k` は **複数回** 呼んでもいい」。これによって:

- バックトラッキング(探索で失敗したら戻る)
- コルーチン・軽量スレッド
- Web サーバの「ページまたぎ」(第 15 章参照)
- 例外処理の実装
- 非決定的な計算

…といったありとあらゆる制御構造を **言語に組み込まなくても** 書けてしまいます。実装するより使う側の方が楽しいので、まずは `with-handlers` や `generator` といった、継続を裏で使っている高水準 API で雰囲気を掴むのがお勧めです。

## 17.2 遅延評価 — `delay` / `force`

Racket は既定では **正格(eager)** 評価ですが、`racket/promise` を使うと明示的に遅延できます。

```text
> (require racket/promise)
> (define p (delay (begin (displayln "computing") (+ 1 2))))
> (force p)
computing
3
> (force p)
3
```

- `delay` は式を包んで「プロミス」を作る(まだ評価されない)
- `force` で評価し、結果をメモ化
- 2 回目以降の `force` は **再計算せず** キャッシュを返す

### ストリーム

`racket/stream` を使うと、無限長の遅延リストが書けます。

```text
> (require racket/stream)
> (define nats (let loop ([n 0]) (stream-cons n (loop (+ n 1)))))
> (stream-ref nats 100)
100
> (for/list ([x (in-stream nats)] [i (in-range 5)]) x)
'(0 1 2 3 4)
```

`nats` は **自然数の無限ストリーム**。`stream-ref` は 100 番目を取ります。必要な分しか計算しないので、無限を扱っても安全。

## 17.3 Typed Racket — 静的型付き Racket

Racket の同一ファイルで使える、完全互換の静的型付き方言です。

```racket
#lang typed/racket
(: square (-> Integer Integer))
(define (square x) (* x x))
(square 7)          ;; => 49

(: sum (-> (Listof Integer) Integer))
(define (sum xs)
  (if (null? xs) 0 (+ (car xs) (sum (cdr xs)))))
(sum '(1 2 3 4 5))  ;; => 15
```

実行結果:

```text
$ racket typed-example.rkt
49
15
```

特徴:

- **`#lang typed/racket` にするだけ** で静的型検査が有効に
- `racket` のモジュールと **契約越しに** 相互運用可
- 型推論は強力(多くの場合 `(define x 10)` で整数と分かる)
- 多相 `(All (A) ...)`、直和型(Union)、Occurrence Typing(`pair?` の後はペアと推論)など機能豊富

Python の mypy や TypeScript のような「既存のコードに型を足せる」ツールと似ていますが、**言語として完全に別物で、相互運用を契約で担保** する点が Racket らしい設計です。

## 17.4 `for` フォーム再訪

第 8 章で触れた `for/list` 以外にも豊富なバリアントがあります。

| フォーム | 意味 |
| --- | --- |
| `for/sum` | 合計 |
| `for/product` | 積 |
| `for/and` / `for/or` | 論理積 / 論理和 |
| `for/last` | 最後の値 |
| `for/fold` | 累積(foldl の for 版) |
| `for/vector` | ベクタへ |
| `for/hash` / `for/hasheq` | ハッシュへ |
| `for/set` | セットへ |
| `for/stream` | ストリームへ(遅延) |
| `for/first` | 最初の値 |
| `for/lists` | 複数リストに同時に収集 |
| `for/mutable-hash` など | 可変コレクションへ |

イテレーション対象(シーケンス)も多様:

- `in-list`, `in-vector`, `in-hash`, `in-string`, `in-stream`
- `in-range`, `in-naturals`
- `in-port` / `in-lines`(ファイル読み)
- `in-producer`(ジェネレータ風)
- 多重ループ(`for*`)と同時ループ(`for`)

「まずは `for/list` と `for/fold`」 を覚えれば、残りはドキュメントを引けば十分です。

## 17.5 ジェネレータとコルーチン

`racket/generator` で Python の `yield` 相当が書けます。

```racket
(require racket/generator)
(define g (generator ()
  (for ([i (in-range 3)])
    (yield (* i i)))))
(g)   ;; => 0
(g)   ;; => 1
(g)   ;; => 4
```

内部は継続で実装されています。`call/cc` の典型的な応用例です。

## 17.6 並列・並行

Racket は以下の並行プリミティブを持ちます。

- **スレッド**(`thread`): OS スレッドではなく軽量スレッド。同一インタプリタ内で協調動作。
- **プレース**(`place`): OS スレッドに相当。並列に計算を行う。
- **チャネル**(`make-channel`): Go ライクなメッセージパッシング。
- **非同期チャネル**(`async-channel`): バッファ付き。

単純なパイプライン:

```racket
(define ch (make-channel))
(thread (lambda ()
          (for ([i 5]) (channel-put ch i))
          (channel-put ch 'done)))
(let loop ()
  (define m (channel-get ch))
  (unless (eq? m 'done)
    (printf "got ~a\n" m)
    (loop)))
```

## 17.7 FFI — C ライブラリを呼ぶ

`ffi/unsafe` で共有ライブラリの関数を呼べます。

```racket
(require ffi/unsafe)
(define libm (ffi-lib "libm" '("6")))
(define c-cos (get-ffi-obj "cos" libm (_fun _double -> _double)))
(c-cos 0.0)  ;; => 1.0
```

型を Racket の側に宣言する必要がありますが、ラッパ一層で C 関数を呼べます。ネイティブ性能が必要な場所で便利です。

## 17.8 GUI — `racket/gui`

ネイティブ GUI を組めます。簡単なウィンドウ:

```racket
(require racket/gui)
(define f (new frame% [label "Hello"] [width 200] [height 120]))
(new button% [parent f] [label "Click"]
     [callback (lambda (b e) (message-box "hi" "hello!"))])
(send f show #t)
```

DrRacket 自身がこのライブラリで作られています。

## 17.9 `scribble` — 文章も Racket で書く

ドキュメントを Racket のコードとして書く DSL です。

```text
#lang scribble/manual

@title{My Library}
@author{Reki}

@racket[map] は高階関数で、@racket[(map add1 '(1 2 3))] は @racketresult['(2 3 4)] を返す。
```

`raco scribble foo.scrbl` で HTML と PDF が生成されます。本書も将来は Scribble 化するかもしれません。

## 17.10 パッケージ、DSL、そして `#lang` の自作

Racket は「言語を作る言語」です。`raco pkg` で配布する独自 `#lang` を作るための標準的なパッケージが `br/quicklang`。

```racket
#lang br/quicklang

(define-macro (mylang-module-begin EXPR ...)
  #'(#%module-begin (displayln 'hi) EXPR ...))

(provide (rename-out [mylang-module-begin #%module-begin])
         #%app #%datum #%top)
```

こんな 10 行程度で「自作の `#lang`」が作れ、`.rkt` ファイルの先頭に書けます。

詳しくは Matthew Butterick の *Beautiful Racket* という良書があり、これが **「Racket で自作言語を作る」** 分野の決定版です。

## 17.11 本章のまとめ

- `call/cc` は継続を値として掴む強力な仕組み
- `delay` / `force` と `stream` で遅延評価
- Typed Racket で静的型、既存 Racket と契約越しに相互運用
- `for` フォームは種類豊富、`for/fold` を覚えると強い
- ジェネレータ・並行・FFI・GUI も一通り揃っている
- Scribble でドキュメント、`#lang` 自作で新言語
- 「言語を作る言語」としての Racket の奥行き

---

## 手を動かしてみよう

1. `call/cc` で「リストから指定条件を満たす要素 **全て** を集めたら失敗する(探索打ち切り)」のような処理を書き、早期終了の気持ちよさを確認しなさい。

2. `racket/stream` を使って、エラトステネスの篩を書きなさい。無限の素数列が得られるはず。ヒント:
   ```racket
   (define (sieve s)
     (stream-cons
       (stream-first s)
       (sieve (stream-filter
                (lambda (x) (not (zero? (modulo x (stream-first s)))))
                (stream-rest s)))))
   ```

3. Typed Racket で第 6 章の `fib-iter` に型注釈を付け、動くことを確認しなさい。ついでに「負の n を渡すとコンパイルが通らない」ようにできるか、`Nonnegative-Integer` を使って試行錯誤してみなさい。

お疲れさまでした。ここまで読み通したあなたは **もう Racket プログラマ** です。
次は付録で **さらに学ぶための地図** を広げましょう。
