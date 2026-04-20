#lang racket

;; 第6章 再帰 — サンプルコード

;; 素朴な再帰
(define (fact n)
  (if (<= n 1) 1 (* n (fact (- n 1)))))

;; 末尾再帰版(累算引数)
(define (fact-iter n)
  (let loop ([n n] [acc 1])
    (if (<= n 1) acc (loop (- n 1) (* n acc)))))

;; 素朴フィボナッチ(指数時間)
(define (fib n)
  (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))

;; 末尾再帰フィボナッチ
(define (fib-iter n)
  (let loop ([i 0] [a 0] [b 1])
    (if (= i n) a (loop (+ i 1) b (+ a b)))))

;; 相互再帰
(define (evens? n) (if (= n 0) #t (odds? (- n 1))))
(define (odds?  n) (if (= n 0) #f (evens? (- n 1))))

;; ハノイの塔(手数を返す)
(define (hanoi n from to via)
  (cond [(= n 0) 0]
        [else (+ (hanoi (- n 1) from via to)
                 1
                 (hanoi (- n 1) via to from))]))

;; ハノイの塔(手順を出力)
(define (hanoi-trace n from to via)
  (cond [(= n 0) (void)]
        [else
         (hanoi-trace (- n 1) from via to)
         (printf "move ~a -> ~a~n" from to)
         (hanoi-trace (- n 1) via to from)]))

(module+ main
  (displayln (fact 10))         ; 3628800
  (displayln (fact-iter 10))    ; 3628800
  (displayln (fib 20))          ; 6765
  (displayln (fib-iter 50))     ; 12586269025
  (displayln (evens? 100))      ; #t
  (displayln (hanoi 10 'A 'C 'B)) ; 1023
  (hanoi-trace 3 'A 'C 'B))

(module+ test
  (require rackunit)
  (check-equal? (fact 0) 1)
  (check-equal? (fact 5) 120)
  (check-equal? (fact-iter 10) (fact 10))
  (check-equal? (fib-iter 10) 55)
  (check-equal? (fib-iter 20) (fib 20))
  (check-equal? (hanoi 5 'A 'C 'B) 31))
