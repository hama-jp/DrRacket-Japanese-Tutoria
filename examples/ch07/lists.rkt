#lang racket

;; 第7章 リストとコンスセル — サンプルコード

;; リストの生成
(displayln (cons 1 (cons 2 (cons 3 '()))))  ; '(1 2 3)
(displayln (list 1 2 3))                     ; '(1 2 3)

;; car/cdr
(displayln (car '(a b c)))   ; 'a
(displayln (cdr '(a b c)))   ; '(b c)
(displayln (cadr '(a b c)))  ; 'b
(displayln (caddr '(a b c))) ; 'c

;; ドット対(非リスト)
(displayln (cons 1 2))       ; '(1 . 2)

;; リスト操作
(displayln (append '(1 2) '(3 4 5)))    ; '(1 2 3 4 5)
(displayln (reverse '(1 2 3)))           ; '(3 2 1)
(displayln (length '(a b c d)))          ; 4
(displayln (list-ref '(a b c d) 2))      ; 'c
(displayln (member 3 '(1 2 3 4)))        ; '(3 4)
(displayln (assoc 'b '((a 1) (b 2) (c 3)))) ; '(b 2)

;; 不変性と共有
(define xs '(1 2 3))
(define ys (cons 0 xs))
(displayln ys) ; '(0 1 2 3)
(displayln xs) ; '(1 2 3) ← 変わっていない

;; 自前の再帰
(define (my-length xs)
  (if (null? xs) 0 (+ 1 (my-length (cdr xs)))))

(define (my-reverse xs)
  (let loop ([xs xs] [acc '()])
    (if (null? xs) acc (loop (cdr xs) (cons (car xs) acc)))))

(define (only-positive xs)
  (cond [(null? xs) '()]
        [(positive? (car xs)) (cons (car xs) (only-positive (cdr xs)))]
        [else (only-positive (cdr xs))]))

(module+ main
  (displayln (my-length '(a b c d)))                    ; 4
  (displayln (my-reverse '(1 2 3)))                     ; '(3 2 1)
  (displayln (only-positive '(1 -2 3 -4 5))))           ; '(1 3 5)

(module+ test
  (require rackunit)
  (check-equal? (my-length '()) 0)
  (check-equal? (my-length '(1 2 3)) 3)
  (check-equal? (my-reverse '()) '())
  (check-equal? (my-reverse '(1 2 3)) '(3 2 1))
  (check-equal? (only-positive '(1 -2 3 -4 5)) '(1 3 5)))
