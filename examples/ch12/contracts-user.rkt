#lang racket

;; 第12章 契約違反を本当に発火させるデモ。
;; contract-out の契約はモジュール境界で有効になる。
;; contracts.rkt を別モジュールから require することで違反を検出できる。

(require "contracts.rkt")

(define (demo title thunk)
  (printf "~a → " title)
  (with-handlers ([exn:fail:contract?
                   (lambda (e)
                     (displayln (exn-message e))
                     (newline))])
    (printf "~a~n" (thunk))))

(demo "safe-sqrt -1"
      (lambda () (safe-sqrt -1)))
(demo "divide 10 0"
      (lambda () (divide 10 0)))
(demo "nonempty-head '()"
      (lambda () (nonempty-head '())))
(demo "nth '(a b c) 5"
      (lambda () (nth '(a b c) 5)))
