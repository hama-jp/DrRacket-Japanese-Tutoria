# 第 9 章 構造体とパターンマッチ

リストは万能ですが、**複数のフィールドに名前を付けたい** ときには向きません。ここからは Racket の構造体(`struct`)、パターンマッチ(`match`)、ハッシュ、ベクタといったデータ道具を学びます。

## 9.1 `struct` — 名前付きの複合データ

```racket
(struct point (x y))
```

これだけで以下がすべて生成されます。

- コンストラクタ `point` : `(point 3 4)`
- 述語 `point?` : そのオブジェクトが point かどうか
- アクセサ `point-x`, `point-y`

REPL:

```text
> (struct point (x y))
> (define p (point 3 4))
> (point-x p)
3
> (point-y p)
4
> (point? p)
#t
> (point? 42)
#f
```

他の言語で `class Point { int x; int y; }` と書くのと似ていますが、メソッドは別で定義する点が違います。「データと振る舞いを分けて書く」というのが Racket 流です。

### `#:transparent` で中身を見せる

標準では構造体は **非透過(opaque)** で、REPL での表示も `#<point>` のように中身が隠れます。デバッグしやすくするため、本書ではほぼ常に `#:transparent` を付けます。

```racket
(struct person (name age) #:transparent)
```

```text
> (define a (person "Reki" 17))
> (define b (person "Reki" 17))
> a
(person "Reki" 17)
> (equal? a b)
#t
```

`#:transparent` を付けると、**内容に基づく `equal?` 比較** ができるようになります。これは非常に嬉しい効果です。

### 不変 vs 可変

デフォルトのフィールドは **不変** です。更新したいときは「新しい構造体を作る」のが Racket 流。

```racket
(define p (point 3 4))
(define p2 (struct-copy point p [x 100]))
```

```text
> p
(point 3 4)
> p2
(point 100 4)
```

`struct-copy` は、指定フィールドだけ上書きした **新しい構造体** を返します。もとの `p` はそのまま。

どうしても可変で書きたければ `#:mutable` を付けますが、本書では徹底して不変で進めます。

### 継承

構造体は継承できます。構文は `(struct 子 親 (追加フィールド...) オプション...)` です。

```racket
(struct point (x y) #:transparent)
(struct point3d point (z) #:transparent)
```

```text
> (define q (point3d 1 2 3))
> q
(point3d 1 2 3)
> (point-x q)
1
> (point-y q)
2
> (point3d-z q)
3
> (point3d? q)
#t
> (point? q)
#t
```

`point3d` は `point` のフィールドを継承し、自前の `z` を足しています。`point?` も真。

注意点:

- コンストラクタの引数順は **親のフィールドが先**。`(point3d 1 2 3)` は x, y, z の順。
- アクセサは `親-フィールド名` / `子-フィールド名` と、それぞれの定義元で別になる。`(point-z q)` とは書かない。
- 親が `#:transparent` でないと、子の `equal?` が期待通り動かない。本書の例では親も子も両方 `#:transparent` を付ける。

オブジェクト指向的な継承と見た目は似ていますが、**データの構造だけを継承する** のが Racket 流です。メソッドやポリモーフィズムは `match` と関数ディスパッチで表現します(本章 9.2 で見た通り)。

### `#:prefab` — シリアライズ可能

`#:prefab` を使うと、**読み取り可能なリテラル表現** を持つ構造体になります。

```text
> (struct person* (name age) #:prefab)
> (person* "Reki" 17)
'#s(person* "Reki" 17)
```

この `'#s(person* ...)` 形式は `read` / `write` で往復できるので、ファイルに保存したりネットワークで送ったりする用途に向きます。

## 9.2 `match` — パターンマッチ

構造体やリストの構造に応じた処理分岐は、`match` で劇的に綺麗に書けます。

```racket
(require racket/match)

(struct shape () #:transparent)
(struct circle shape (r) #:transparent)
(struct rect shape (w h) #:transparent)

(define (area s)
  (match s
    [(circle r) (* 3.14 r r)]
    [(rect w h) (* w h)]))
```

```text
> (area (circle 5))
78.5
> (area (rect 3 4))
12
```

Python 3.10+ の `match` 文や Rust/Haskell/OCaml のパターンマッチを触ったことがあれば、ほぼそのままの感覚で使えます。

### マッチできるパターン

| パターン | 例 | 意味 |
| --- | --- | --- |
| リテラル | `42`, `"hi"`, `'x` | 完全一致 |
| 変数 | `x` | なんでもマッチし束縛 |
| `_` | `_` | なんでもマッチするが捨てる |
| リスト | `(list 1 2 x)` | 長さ 3 で先頭 2 要素が一致 |
| クォートリスト | `'(1 2 3)` | クォートされた形 |
| 構造体 | `(circle r)` | 構造体コンストラクタに一致 |
| `?` 述語 | `(? number?)` | 述語が真ならマッチ |
| `and` | `(and x (? positive?))` | 複数条件 |
| `or` | `(or 1 2 3)` | いずれかにマッチ |
| `quasi` | `` `(1 ,x) `` | 準クォート |

例を続けます。

```racket
(define (sum xs)
  (match xs
    ['() 0]
    [(cons x rest) (+ x (sum rest))]))
```

```text
> (sum '(1 2 3 4 5))
15
```

`cons` パターンは「先頭要素と残り」にそのまま分解してくれます。第 7 章の素朴な再帰より宣言的に書けていることに注目。

### ガード付きパターン

`#:when` で追加条件を付けられます。

```racket
(define (classify x)
  (match x
    [(? number? n) #:when (positive? n) 'positive-number]
    [(? number? _)                      'non-positive-number]
    [(? string? _)                      'string]
    [_                                  'other]))
```

```text
> (classify 10)
'positive-number
> (classify -1)
'non-positive-number
> (classify "hi")
'string
> (classify 'foo)
'other
```

この書き方は大きな `cond` や型分岐より読みやすく、バグを混入させにくいです。

## 9.3 ハッシュテーブル

Key-Value のペアを高速に管理するならハッシュ。Racket には **不変ハッシュ** と **可変ハッシュ** の 2 種類があります。

### 不変ハッシュ

```text
> (define h (hash 'a 1 'b 2 'c 3))
> h
'#hash((a . 1) (b . 2) (c . 3))
> (hash-ref h 'b)
2
> (hash-set h 'd 4)
'#hash((a . 1) (b . 2) (c . 3) (d . 4))
> h
'#hash((a . 1) (b . 2) (c . 3))
> (hash-ref h 'missing 'not-found)
'not-found
> (hash-count h)
3
```

- `(hash-set h k v)` は **新しい** ハッシュを返す。`h` 自体は変わらない
- `hash-ref` の 3 引数目はデフォルト値(省略するとキーなしで例外)
- 内部的に **永続データ構造**(hash array mapped trie)になっているので O(log n)

### 可変ハッシュ

```text
> (define mh (make-hash))
> (hash-set! mh 'x 10)
> (hash-set! mh 'y 20)
> (hash-ref mh 'x)
10
> mh
'#hash((x . 10) (y . 20))
```

`make-hash` / `hash-set!` / `hash-remove!` を使います。高頻度更新や外部との通信で必要なときに限って使いましょう。

### イテレーション

```text
> (hash-keys h)
'(a b c)
> (hash-values h)
'(1 2 3)
> (hash->list h)
'((c . 3) (b . 2) (a . 1))
> (for/list ([(k v) (in-hash h)]) (list k v))
'((a 1) (b 2) (c 3))
```

`in-hash` は key と value を同時に回せます。

## 9.4 ベクタ

配列のように、要素にランダムアクセスできる固定長コンテナ。

```text
> (define v (vector 'a 'b 'c 'd))
> (vector-ref v 2)
'c
> (vector-length v)
4
> (vector-set! v 2 'Z)
> v
'#(a b Z d)
```

- `vector` リテラルは `#(a b c d)` の形で REPL に表示される
- **ベクタは標準で可変**(`vector-set!` が使える)
- 不変版が欲しいときは `vector-immutable`

```text
> (for/vector ([i (in-range 5)]) (* i i))
'#(0 1 4 9 16)
```

`for/vector` はリストの `for/list` と同様、ベクタを集めます。

### リスト vs ベクタの使い分け

| 操作 | リスト | ベクタ |
| --- | --- | --- |
| 先頭に追加 | O(1) | O(n) |
| 末尾に追加 | O(n) | O(n)(再確保) |
| n 番目アクセス | O(n) | O(1) |
| 不変 | デフォルト | オプション |

**「順次処理主体 → リスト」「ランダムアクセス主体 → ベクタ」** が目安です。

## 9.5 セット

標準の `racket/set` には集合もあります。

```text
> (require racket/set)
> (define s (set 'a 'b 'c))
> (set-member? s 'b)
#t
> (set-union s (set 'c 'd))
(set 'a 'b 'c 'd)
> (set-intersect s (set 'b 'c 'z))
(set 'b 'c)
```

不変集合と可変集合(`mutable-set`)があります。

## 9.6 値の等価性 — `eq?` / `eqv?` / `equal?`

値が「等しい」とは何かを Racket は 3 段階で区別します。

| 述語 | 意味 |
| --- | --- |
| `eq?` | **同じオブジェクト**(同一性) |
| `eqv?` | `eq?` に加え、同じ数値・文字なら真 |
| `equal?` | **構造的に同じ**(推奨。リストや透過構造体の中身比較) |

```text
> (eq? '(1 2) '(1 2))
#f
> (equal? '(1 2) '(1 2))
#t
> (eq? 'a 'a)
#t
> (eqv? 1.0 1.0)
#t
> (eq? 1.0 1.0)
#f
```

普段は **`equal?` を使えばほぼ困りません**。

## 9.7 `match` で構造化データを分解する実例

JSON 風のデータをパターンマッチで処理するミニ例です。

```racket
(define sample
  (hash 'name "Reki"
        'skills '("Racket" "Python")
        'age 17))

(define (summary p)
  (match p
    [(hash-table ['name n] ['skills ss] ['age a])
     (format "~a (~a歳) - 得意: ~a"
             n a (string-join ss ", "))]))
```

```text
> (summary sample)
"Reki (17歳) - 得意: Racket, Python"
```

`hash-table` パターンは「指定キーがすべて存在して、値が対応するパターンにマッチ」という意味です。**JSON の分解** が 3 行で書けてしまいます。

他の言語で同じことをするなら、「`p["name"]` を取って、存在確認して、型チェックして、別の変数に代入して……」という分解と検証を手で書くことになります。Racket の `match` はパターンを「期待するデータの形」として宣言するだけで、マッチが成立しないときは分かりやすい例外に落ちます。

> 注意: 順序は任意です。`[(hash-table ['age a] ['name n] ['skills ss])]` でも同じ意味。**キーに指定したものだけを見る** ので、他に余分なキーがあってもマッチは成功します。「完全一致」を要求したいなら、`(hash-count p)` などで個別に検査します。

## 9.8 本章のまとめ

- `struct` は不変が基本、`#:transparent` を付けると比較・表示が便利
- 継承・プリファブ・可変は必要なときだけ
- `match` は Lisp で書いた関数を圧倒的に読みやすくする
- ハッシュとベクタを目的に応じて使い分ける
- 等価性は原則 `equal?` を使えばよい

---

## 手を動かしてみよう

1. `book` という構造体を作ります。フィールドは `title`, `author`, `price` の 3 つ、透過にすること。5 冊の蔵書リストを作り、価格の合計を `for/sum` と `foldl` の両方で計算してみなさい。

2. 円・長方形・三角形を `struct` で表現し、`match` を使って面積と外周を同時に返す関数を書きなさい。
   ```racket
   (struct circle   (r)   #:transparent)
   (struct rect     (w h) #:transparent)
   (struct triangle (a b c) #:transparent)

   (define (info s)
     (match s
       [(circle r) (list (* 3.14 r r) (* 2 3.14 r))]
       [(rect w h) (list (* w h) (* 2 (+ w h)))]
       [(triangle a b c)
        (define s0 (/ (+ a b c) 2))
        (list (sqrt (* s0 (- s0 a) (- s0 b) (- s0 c)))
              (+ a b c))]))
   ```

3. 「単語 → 登場回数」のハッシュを、文字列リストから作る関数を書きなさい。
   ```racket
   (define (word-count words)
     (for/fold ([h (hash)]) ([w (in-list words)])
       (hash-update h w add1 0)))
   ```
   ```text
   > (word-count '("a" "b" "a" "c" "b" "a"))
   '#hash(("a" . 3) ("b" . 2) ("c" . 1))
   ```
   `hash-update` は `(hash-update h key updater default)` の形で使えます。

次章では、これらデータ構造を **外の世界**(ファイル・ユーザ入力・例外)とつなぎます。
