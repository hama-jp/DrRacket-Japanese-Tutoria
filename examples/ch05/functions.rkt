#lang racket

;; 第5章 関数を値として扱う — サンプルコード

;; 関数定義の略記とフル形は同じ
(define (square x) (* x x))
(define square2 (lambda (x) (* x x)))
(displayln (square 7))   ; 49
(displayln (square2 7))  ; 49

;; 複数引数・可変長引数
(define (hypot a b) (sqrt (+ (square a) (square b))))
(define (sum . xs) (apply + xs))
(displayln (hypot 3 4))  ; 5
(displayln (sum 1 2 3 4 5))  ; 15

;; キーワード引数
(define (greet name #:lang [lang "ja"])
  (if (equal? lang "ja")
      (string-append "こんにちは、" name)
      (string-append "hello, " name)))
(displayln (greet "レキ"))
(displayln (greet "Reki" #:lang "en"))

;; 高階関数
(define (twice f) (lambda (x) (f (f x))))
(define (inc x) (+ x 1))
(displayln ((twice inc) 10))  ; 12

;; 関数合成
(define (compose2 f g) (lambda (x) (f (g x))))
(displayln ((compose2 inc square) 3))  ; 10

;; クロージャ
(define (make-adder n) (lambda (x) (+ x n)))
(define add5 (make-adder 5))
(displayln (add5 3))  ; 8

;; 隠された状態
(define (make-counter)
  (define n 0)
  (lambda ()
    (set! n (+ n 1))
    n))
(define c (make-counter))
(displayln (c))
(displayln (c))
(displayln (c))

;; cond の例
(define (sign x)
  (cond [(positive? x) 'positive]
        [(negative? x) 'negative]
        [else 'zero]))
(displayln (sign 5))
(displayln (sign -1))
(displayln (sign 0))
