#lang racket

(provide (contract-out
          [square (-> number? number?)]
          [hypot  (-> number? number? number?)]))

(define (square x) (* x x))

(define (hypot a b)
  (sqrt (+ (square a) (square b))))
