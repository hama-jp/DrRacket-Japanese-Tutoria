#lang racket

;; 第3章 はじめてのプログラム — ファイル実行サンプル

(define (greet name)
  (string-append "こんにちは、" name "さん!"))

;; トップレベルの「式」は racket/base の print によって表示される。
;; 文字列はダブルクォート付きで出る。
(greet "レキ")

;; displayln は「人間向けの表示」。クォートなしで改行付き。
(displayln (greet "ゆい"))

;; printf は C 風のフォーマット付き出力。
(printf "~a さんと ~a さんに挨拶しました。~n" "レキ" "ゆい")
