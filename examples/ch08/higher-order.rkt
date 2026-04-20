#lang racket

;; 第8章 高階関数とデータ変換 — サンプルコード

;; map / filter / foldl・foldr
(displayln (map (lambda (x) (* x x)) '(1 2 3 4 5)))   ; '(1 4 9 16 25)
(displayln (filter odd? '(1 2 3 4 5 6)))              ; '(1 3 5)
(displayln (foldl + 0 '(1 2 3 4 5)))                  ; 15
(displayln (foldr cons '() '(1 2 3)))                 ; '(1 2 3)
(displayln (foldl cons '() '(1 2 3)))                 ; '(3 2 1)

;; map は複数リスト
(displayln (map + '(1 2 3) '(10 20 30)))              ; '(11 22 33)

;; apply
(displayln (apply + '(1 2 3 4)))                       ; 10

;; partition
(define-values (evens odds) (partition even? '(1 2 3 4 5 6)))
(displayln evens)  ; '(2 4 6)
(displayln odds)   ; '(1 3 5)

;; sort
(displayln (sort '(3 1 4 1 5 9 2 6) <))
(displayln (sort '("pear" "apple" "banana") < #:key string-length))

;; 関数合成
(define (inc x) (+ x 1))
(define (sq  x) (* x x))
(displayln ((compose inc sq) 3))     ; 10

;; カリー化
(define add3 ((curry + ) 3))
(displayln (add3 100))  ; 103

;; for/list / for/sum / for/hash
(displayln (for/list ([x (in-range 5)]) (* x x)))
(displayln (for/sum ([x (in-range 1 11)]) x))
(displayln (for/hash ([k '(a b c)] [v '(1 2 3)]) (values k v)))

;; my-map / my-filter を foldr で
(define (my-map f xs)
  (foldr (lambda (x acc) (cons (f x) acc)) '() xs))

(define (my-filter pred xs)
  (foldr (lambda (x acc) (if (pred x) (cons x acc) acc)) '() xs))

(module+ main
  (displayln (my-map sq '(1 2 3 4 5)))
  (displayln (my-filter even? '(1 2 3 4 5 6))))

(module+ test
  (require rackunit)
  (check-equal? (my-map sq '(1 2 3)) '(1 4 9))
  (check-equal? (my-filter odd? '(1 2 3 4 5)) '(1 3 5)))
