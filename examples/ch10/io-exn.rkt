#lang racket

;; 第10章 状態・入出力・例外 — サンプルコード

;; display / write / print / printf
(display "hello") (newline)
(write "hello")   (newline)
(print "hello")   (newline)
(printf "x=~a / y=~s~n" 42 "str")

;; 文字列 → 数値
(displayln (string->number "42"))    ; 42
(displayln (string->number "oops"))  ; #f

;; ファイル書き込み → 読み込み
(define tmp "/tmp/ch10-demo.txt")
(with-output-to-file tmp #:exists 'replace
  (lambda ()
    (displayln "line 1")
    (displayln "line 2")))

(displayln (file->lines tmp))  ; '("line 1" "line 2")

;; 文字列キャプチャ
(define captured (with-output-to-string (lambda () (printf "x=~a" 42))))
(displayln captured)  ; "x=42"

;; 例外処理
(define (safe-div a b)
  (with-handlers ([exn:fail? (lambda (e) 'error)])
    (/ a b)))
(displayln (safe-div 10 2))   ; 5
(displayln (safe-div 10 0))   ; 'error

;; dynamic-wind
(dynamic-wind
  (lambda () (displayln "before"))
  (lambda () (displayln "body") 42)
  (lambda () (displayln "after")))

(module+ test
  (require rackunit)
  (check-equal? (safe-div 10 2) 5)
  (check-equal? (safe-div 10 0) 'error)
  (check-equal? (string->number "oops") #f))
