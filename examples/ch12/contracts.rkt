#lang racket

;; 第12章 テストと契約 — サンプルコード

(provide (contract-out
          [safe-sqrt (-> (>=/c 0) (>=/c 0))]
          [divide    (-> number? (and/c number? (not/c zero?)) number?)]
          [nonempty-head (-> (and/c list? (not/c empty?)) any/c)]
          [nth (->i ([xs (listof any/c)]
                     [i (xs) (and/c exact-nonnegative-integer?
                                    (</c (length xs)))])
                    [result any/c])]))

(define (safe-sqrt x) (sqrt x))
(define (divide a b) (/ a b))
(define (nonempty-head xs) (car xs))
(define (nth xs i) (list-ref xs i))

(module+ main
  (displayln (safe-sqrt 25))
  (displayln (divide 10 2))
  (displayln (nonempty-head '(1 2 3)))
  (displayln (nth '(a b c d) 2))
  ;; 契約違反を試したいが、module+ main は同一モジュール扱いなので契約は発火しない。
  ;; 実際に違反させたい場合は contracts-user.rkt から require する。
  (displayln "See contracts-user.rkt for real contract violations."))

(module+ test
  (require rackunit)
  ;; 注意:contract-out の契約は「モジュール境界を跨ぐときに」有効になる。
  ;; `module+ test` は同一モジュール内部からの利用扱いなので契約違反は発火しない。
  ;; 契約違反を確かめたい場合は、別の .rkt ファイルから require すること。
  (check-equal? (safe-sqrt 0) 0)
  (check-equal? (safe-sqrt 25) 5)
  (check-equal? (divide 10 2) 5)
  (check-equal? (nonempty-head '(1 2 3)) 1)
  (check-equal? (nth '(a b c) 1) 'b))
