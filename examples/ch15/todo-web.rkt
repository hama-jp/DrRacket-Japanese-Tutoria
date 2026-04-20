#lang racket

;; 超最小 TODO アプリ(メモリ保存のみ)。
;; GET  /       ページ表示 + 追加フォーム
;; POST /add    item を追加
;; POST /delete id を削除

(require web-server/servlet
         web-server/servlet-env)

(define todos (make-hash))     ; id -> string
(define next-id 0)

(define (add-todo! text)
  (set! next-id (+ next-id 1))
  (hash-set! todos next-id text))

(define (delete-todo! id)
  (hash-remove! todos id))

(define (render-page)
  `(html
    (head (meta ((charset "utf-8"))) (title "Mini TODO"))
    (body
     (h1 "Mini TODO")
     (form ((method "POST") (action "/add"))
           (input ((type "text") (name "text")
                   (placeholder "new item") (required ""))) " "
           (button ((type "submit")) "Add"))
     (ul
      ,@(for/list ([(id text) (in-hash todos)])
          `(li ,text " "
               (form ((method "POST")
                      (action "/delete")
                      (style "display:inline"))
                     (input ((type "hidden") (name "id")
                             (value ,(number->string id))))
                     (button ((type "submit")) "✕"))))))))

(define (dispatch req)
  (define path (map path/param-path (url-path (request-uri req))))
  (define bindings (request-bindings req))
  (cond
    [(and (equal? path '("add"))
          (equal? (request-method req) #"POST"))
     (define txt (extract-binding/single 'text bindings))
     (when txt (add-todo! txt))
     (redirect-to "/" temporarily)]
    [(and (equal? path '("delete"))
          (equal? (request-method req) #"POST"))
     (define id (string->number
                 (or (extract-binding/single 'id bindings) "0")))
     (delete-todo! id)
     (redirect-to "/" temporarily)]
    [else
     (response/xexpr (render-page))]))

(module+ main
  (serve/servlet dispatch
                 #:servlet-regexp #rx""
                 #:port 8001
                 #:listen-ip "127.0.0.1"
                 #:command-line? #t))
