#lang racket

;; 第9章 構造体とパターンマッチ — サンプルコード

(require racket/match)

;; struct の基本
(struct point (x y) #:transparent)
(define p (point 3 4))
(displayln (point-x p))   ; 3
(displayln (point-y p))   ; 4
(displayln (point? p))    ; #t

;; 不変更新
(define p2 (struct-copy point p [x 100]))
(displayln p)   ; (point 3 4)
(displayln p2)  ; (point 100 4)

;; 継承
(struct point3d point (z) #:transparent)
(define q (point3d 1 2 3))
(displayln q)   ; (point3d 1 2 3)
(displayln (point? q))   ; #t
(displayln (point3d-z q)) ; 3

;; match による分岐
(struct shape () #:transparent)
(struct circle shape (r) #:transparent)
(struct rect shape (w h) #:transparent)
(struct triangle shape (a b c) #:transparent)

(define (area s)
  (match s
    [(circle r) (* 3.14 r r)]
    [(rect w h) (* w h)]
    [(triangle a b c)
     (define s0 (/ (+ a b c) 2))
     (sqrt (* s0 (- s0 a) (- s0 b) (- s0 c)))]))

;; ハッシュ(不変)
(define h (hash 'a 1 'b 2 'c 3))
(displayln (hash-ref h 'b))                    ; 2
(displayln (hash-ref h 'missing 'not-found))   ; 'not-found
(displayln (hash-set h 'd 4))

;; ベクタ
(define v (vector 'a 'b 'c 'd))
(vector-set! v 2 'Z)
(displayln v)   ; #(a b Z d)

;; 集合
(require racket/set)
(define s (set 'a 'b 'c))
(displayln (set-union s (set 'c 'd)))

;; for/fold でワードカウント
(define (word-count words)
  (for/fold ([h (hash)]) ([w (in-list words)])
    (hash-update h w add1 0)))

(module+ main
  (displayln (area (circle 5)))
  (displayln (area (rect 3 4)))
  (displayln (area (triangle 3 4 5)))
  (displayln (word-count '("a" "b" "a" "c" "b" "a"))))

(module+ test
  (require rackunit)
  (check-equal? (area (rect 3 4)) 12)
  (check-= (area (circle 5)) 78.5 0.01)
  (check-equal? (word-count '("a" "b" "a")) (hash "a" 2 "b" 1)))
