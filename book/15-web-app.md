# 第 15 章 Web アプリで遊ぶ — ハンズオン 3

Racket には本格的な Web サーバが標準同梱されています。この章ではそれを使って、ブラウザからアクセスできる小さなアプリを作ります。

## 15.1 `web-server/servlet-env` の最小形

```racket
#lang racket
(require web-server/servlet
         web-server/servlet-env)

(define (start req)
  (response/xexpr
   `(html (head (meta ((charset "utf-8"))) (title "Hello"))
          (body (h1 "Hello, Racket!")))))

(serve/servlet start
               #:servlet-regexp #rx""
               #:port 8000
               #:listen-ip "127.0.0.1"
               #:command-line? #t)
```

`serve/servlet` を呼ぶと:

- `http://127.0.0.1:8000/` で HTTP サーバが起動
- `start` に `request` オブジェクトが渡される
- `response/xexpr` で HTML 応答を返す

`#:servlet-regexp #rx""` は「**すべてのパス** を `start` に任せる」という意味。これがないとデフォルトで `/servlets/…` 以外は静的ファイル扱いになります。

`#:command-line? #t` は、起動時にブラウザを自動で開くのを抑止する設定。サーバ用途やテスト時に便利です。

DrRacket で `Run` するとブラウザが自動で開きます。`Ctrl+C` か DrRacket の Stop ボタンで終了。

## 15.2 X式(xexpr)— HTML を S式で書く

上で `` `(html (head ...) (body ...)) `` のように書いたものが **X式(xexpr)** です。HTML の木構造を **S 式** で表現します。

| HTML | X式 |
| --- | --- |
| `<h1>Hello</h1>` | `` `(h1 "Hello") `` |
| `<a href="/">home</a>` | `` `(a ((href "/")) "home") `` |
| `<ul><li>a</li><li>b</li></ul>` | `` `(ul (li "a") (li "b")) `` |

属性は `((name value) ...)` の形で **2 つ目** の要素。ない場合は省略できます。

```text
> (require xml)
> (xexpr->string '(html (head (title "Hello"))
                        (body (h1 "Hello")
                              (ul (li "one") (li "two")))))
"<html><head><title>Hello</title></head><body><h1>Hello</h1><ul><li>one</li><li>two</li></ul></body></html>"
```

`xexpr->string` で普通の HTML 文字列に落とせます。X式 はマクロや `for/list` と組み合わせると、**Jinja2 のようなテンプレートエンジンなしで** 動的に HTML を組み上げられます。これは「コードもデータも同じ S 式」であるおかげです。

## 15.3 ルーティングとクエリ

`examples/ch15/hello-web.rkt` の例。

```racket
#lang racket
(require web-server/servlet web-server/servlet-env)

(define (dispatch req)
  (define bindings (request-bindings req))
  (define path (map path/param-path (url-path (request-uri req))))
  (cond
    [(equal? path '("hello"))
     (define name (or (extract-binding/single 'name bindings) "みなさん"))
     (response/xexpr
      `(html (head (meta ((charset "utf-8"))) (title "Greet"))
             (body (h1 ,(format "こんにちは、~aさん!" name))
                   (p ((style "color:gray"))
                      ,(format "いまのサーバ時刻は ~a" (current-seconds))))))]
    [else
     (response/xexpr
      `(html (head (meta ((charset "utf-8"))) (title "Welcome"))
             (body (h1 "Welcome to Mini Racket Web")
                   (ul (li (a ((href "/hello?name=Reki")) "GET /hello?name=Reki"))
                       (li (a ((href "/hello?name=ゆい"))  "GET /hello?name=ゆい"))))))]))

(module+ main
  (serve/servlet dispatch
                 #:servlet-regexp #rx""
                 #:port 8000
                 #:listen-ip "127.0.0.1"
                 #:command-line? #t))
```

### 起動と動作確認(curl)

```text
$ racket examples/ch15/hello-web.rkt &
$ curl -s http://127.0.0.1:8000/
<html><head><meta charset="utf-8"/><title>Welcome</title></head><body><h1>Welcome to Mini Racket Web</h1>...
$ curl -s "http://127.0.0.1:8000/hello?name=%E3%83%AC%E3%82%AD"
<html>...<h1>こんにちは、レキさん!</h1>...
```

日本語もちゃんと返ります。

### 中で使った道具

- `request-bindings` — クエリ・フォームの値(連想リスト風)
- `extract-binding/single` — キーから文字列を 1 つ取り出す
- `request-uri` / `url-path` — パスを分解
- `path/param-path` — 1 セグメントから文字列を取り出す
- `response/xexpr` — X式を HTTP レスポンスに

## 15.4 POST と状態 — ミニ TODO

フォーム POST を受け、メモリ上にデータを保持するシンプルな TODO アプリ。

`examples/ch15/todo-web.rkt` の重要部分:

```racket
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
```

### 動作確認

```text
$ racket examples/ch15/todo-web.rkt &
$ curl -s http://127.0.0.1:8001/ | head -1
<html><head><meta charset="utf-8"/><title>Mini TODO</title>...<ul></ul></body></html>
$ curl -sL -X POST -d 'text=%E7%89%9B%E4%B9%B3%E3%82%92%E8%B2%B7%E3%81%86' \
       http://127.0.0.1:8001/add > /dev/null
$ curl -s http://127.0.0.1:8001/ | head -1
<html>...<ul><li>牛乳を買う ...</li></ul></body></html>
```

POST で追加 → リダイレクト → 再描画。一般的な POST/Redirect/GET パターンが 50 行ほどで動いています。

### 注意点

- `todos` はメモリ上のグローバル変数なので、サーバ再起動で消えます
- 永続化するなら `racquel`(ORM)や `db` パッケージで SQLite などに書き出す
- マルチスレッドからの `hash-set!` は **安全ではない** ので、真面目にやるならロックが要る

学習目的にはこれで十分ですが、本番運用では次のライブラリが候補になります。

- `web-server/dispatch` — 宣言的ルーティング
- `racquel` / `db` — データベース接続
- `racket/contract` — 入出力の契約
- `json` — JSON API
- `racket/format` — フォーマット

## 15.5 継続(Continuation)による「ページまたぎ」

Racket の Web サーバは「継続ベース」の応用例で有名です。1 つのリクエストの途中で `(send/suspend ...)` を呼ぶと、**その先の計算を URL として凍結** し、ユーザがリンクをクリックした瞬間に凍結状態から再開できます。

極端に単純化すると:

```racket
(define (ask req)
  (define req2 (send/suspend
                (lambda (k-url)
                  (response/xexpr
                   `(html (body (form ((action ,k-url) (method "post"))
                                      "name: " (input ((name "n")))
                                      (button ((type "submit")) "OK"))))))))
  (define n (extract-binding/single 'n (request-bindings req2)))
  (response/xexpr `(html (body (h1 ,(format "hello, ~a!" n))))))
```

普通の関数型プログラムを書くように「入力を受け取って進める」フローが書けます。ステートフルな Web アプリを `Session` や `State Machine` なしで表現できる、Racket ならではの仕組みです。

## 15.6 JSON API のかたち

REST API を書くなら、`response/jsexpr` を使うと楽です(`json` ライブラリ)。

```racket
(require json)

(define (api-hello req)
  (response/jsexpr
   (hasheq 'message "こんにちは"
           'time (current-seconds))))
```

```text
$ curl -s http://localhost:8000/api/hello
{"message":"こんにちは","time":1776726859}
```

`hasheq` はシンボルキー用のハッシュ。`json` モジュールがそのまま JSON に落とします。

## 15.7 まとめ

- `web-server/servlet-env` で 10 行ほどで HTTP サーバが立つ
- X 式なら HTML をコードそのものとして書ける
- フォーム・クエリ・POST の基本が `extract-binding` で取れる
- 状態は最初メモリで、本格化したら DB へ
- `send/suspend` による継続ベースの書き方は Racket の独自技能

---

## 手を動かしてみよう

1. `hello-web.rkt` に `/sum?a=1&b=2` → `3` を JSON で返すエンドポイントを追加しなさい。`json` ライブラリの `response/jsexpr` を使うこと。

2. `todo-web.rkt` を拡張し、各 TODO に **完了フラグ** を持たせなさい。`POST /toggle` で真偽を切り替える。
   - データ構造: `id -> (list text done?)`
   - 完了済みは `<s>テキスト</s>` で取り消し線表示

3. `todo-web.rkt` の内容を JSON ファイル `/tmp/todos.json` に保存/復元するようにしなさい。起動時に `file-exists?` で確認し、あれば `read-json` で読み込み、なければ空で始める。

次章は、ここまでに学んだすべての上にある Racket 最大の武器 **マクロ** に進みます。
