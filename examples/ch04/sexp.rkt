#lang racket

;; 第4章 S式と評価モデル — サンプルコード

;; 基本の評価
(+ 1 (* 2 3))                 ; => 7

;; quote: 評価を止める
(define expr1 '(+ 1 2))        ; リストとして保持
(displayln expr1)              ; => (+ 1 2)

;; eval: 評価を戻す(新しい名前空間を用意)
(displayln (eval expr1 (make-base-namespace)))  ; => 3

;; quasiquote: 部分評価
(displayln `(1 ,(+ 1 1) 3))                 ; => (1 2 3)
(displayln `(head ,@(list 'a 'b 'c) tail))  ; => (head a b c tail)

;; symbol: 名前そのものを値に
(displayln (symbol->string 'hello))         ; => "hello"
(displayln (eq? 'hello (string->symbol "hello"))) ; => #t
