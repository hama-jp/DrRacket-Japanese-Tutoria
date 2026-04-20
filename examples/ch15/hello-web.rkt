#lang racket

;; web-server/servlet-env の簡単なハンズオン用サーバ。
;; DrRacket / `racket hello-web.rkt` で起動すると http://localhost:8000/ で待ち受ける。

(require web-server/servlet
         web-server/servlet-env)

;; GET / → シンプルな挨拶
;; GET /hello?name=レキ → 「こんにちは、レキさん」
(define (dispatch req)
  (define bindings (request-bindings req))
  (define path (map path/param-path (url-path (request-uri req))))
  (cond
    [(equal? path '("hello"))
     (define name (or (extract-binding/single 'name bindings) "みなさん"))
     (response/xexpr
      `(html (head (meta ((charset "utf-8")))
                   (title "Greet"))
             (body (h1 ,(format "こんにちは、~aさん!" name))
                   (p ((style "color:gray"))
                      ,(format "いまのサーバ時刻は ~a"
                               (current-seconds))))))]
    [else
     (response/xexpr
      `(html (head (meta ((charset "utf-8")))
                   (title "Welcome"))
             (body (h1 "Welcome to Mini Racket Web")
                   (ul (li (a ((href "/hello?name=Reki")) "GET /hello?name=Reki"))
                       (li (a ((href "/hello?name=ゆい"))  "GET /hello?name=ゆい"))))))]))

(module+ main
  (serve/servlet dispatch
                 #:servlet-regexp #rx""    ; 全パスを dispatch に任せる
                 #:port 8000
                 #:listen-ip "127.0.0.1"
                 #:command-line? #t))
