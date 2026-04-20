#lang racket

;; =================================================================
;; 小さな Lisp 処理系 (mini-lisp)
;;
;; 機能:
;;   - 数値・真偽値・文字列・シンボル
;;   - 変数束縛: (define x 10) / (define (f x) ...)
;;   - 関数: (lambda (x y) (+ x y))
;;   - 分岐: (if c a b)
;;   - 局所束縛: (let ([x 1] [y 2]) body ...)
;;   - クォート: 'foo, '(a b c)
;;   - 算術: +, -, *, /, =, <, >
;;   - リスト: cons, car, cdr, list, null?
;; =================================================================

(require racket/match)

;; --- 環境 ---
;; 局所フレームの連想リストと、トップレベル用の mutable ハッシュを持つ
(struct env (frames globals) #:transparent)

(define (make-root-env)
  (define g (make-hash))
  (hash-set*! g
              '+ + '- - '* * '/ /
              '= = '< < '> >
              'cons cons 'car car 'cdr cdr 'list list
              'null? null? 'not not)
  (env '() g))

(define (extend-env e names values)
  (env (cons (map cons names values) (env-frames e))
       (env-globals e)))

(define (env-set-global! e name value)
  (hash-set! (env-globals e) name value))

(define (env-lookup e sym)
  (let loop ([frames (env-frames e)])
    (cond
      [(null? frames)
       (hash-ref (env-globals e) sym
                 (lambda () (error 'lookup "unbound: ~v" sym)))]
      [(assoc sym (car frames)) => cdr]
      [else (loop (cdr frames))])))

;; --- 評価器 ---
(define (mini-eval expr e)
  (match expr
    [(? number?)   expr]
    [(? boolean?)  expr]
    [(? string?)   expr]
    [(? symbol?)   (env-lookup e expr)]
    [(list 'quote datum) datum]
    [(list 'if c a b)
     (if (mini-eval c e)
         (mini-eval a e)
         (mini-eval b e))]
    [(list* 'lambda params body)
     (list 'closure params body e)]
    [(list* 'let bindings body)
     (define names  (map car  bindings))
     (define vals   (map (lambda (b) (mini-eval (cadr b) e)) bindings))
     (eval-body body (extend-env e names vals))]
    [(cons f args)
     (apply-proc (mini-eval f e)
                 (map (lambda (a) (mini-eval a e)) args))]))

(define (eval-body exprs e)
  (cond
    [(null? (cdr exprs)) (mini-eval (car exprs) e)]
    [else
     (mini-eval (car exprs) e)
     (eval-body (cdr exprs) e)]))

(define (apply-proc proc args)
  (match proc
    [(list 'closure params body captured-env)
     (eval-body body (extend-env captured-env params args))]
    [(? procedure?)
     (apply proc args)]
    [else (error 'apply "not a procedure: ~v" proc)]))

;; --- トップレベル評価 ---
(define (run program)
  (define e (make-root-env))
  (for/last ([form (in-list program)])
    (match form
      [(list 'define (cons name params) body ...)
       (env-set-global! e name
                        (mini-eval `(lambda ,params ,@body) e))
       (void)]
      [(list 'define name expr)
       (env-set-global! e name (mini-eval expr e))
       (void)]
      [else (mini-eval form e)])))

(provide run mini-eval make-root-env extend-env env-set-global!)

;; =================================================================
;; 使用例
;; =================================================================
(module+ main
  (define program
    '((define (square x) (* x x))
      (define (fact n)
        (if (< n 2) 1 (* n (fact (- n 1)))))
      (define (my-map f xs)
        (if (null? xs) '()
            (cons (f (car xs)) (my-map f (cdr xs)))))
      (list (square 7)
            (fact 6)
            (my-map square '(1 2 3 4 5)))))
  (displayln (run program)))

(module+ test
  (require rackunit)
  (check-equal? (run '((+ 1 2 3))) 6)
  (check-equal? (run '((define (sq x) (* x x))
                       (sq 9))) 81)
  (check-equal? (run '((define (fact n) (if (< n 2) 1 (* n (fact (- n 1)))))
                       (fact 6))) 720)
  (check-equal? (run '((let ([x 10] [y 20]) (+ x y)))) 30)
  (check-equal? (run '(((lambda (x) (* x x)) 7))) 49))
