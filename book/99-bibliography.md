# 付録 さらに学ぶために

本書で扱えなかったトピックは膨大です。ここでは「この先ここに行けば広がるぞ」という地図を広げます。

## A.1 公式ドキュメント

まず押さえるべきは公式。全部英語ですが、Racket のドキュメントは **世界有数の質** なので、英語を気にせず開く価値があります。

- [The Racket Guide](https://docs.racket-lang.org/guide/) — 言語全体のガイド。本書の範囲を大幅に超える
- [The Racket Reference](https://docs.racket-lang.org/reference/) — 辞書的リファレンス。`raco docs <word>` でも検索可
- [Pict: Functional Pictures](https://docs.racket-lang.org/pict/) — 第 13 章で触れた画像 DSL
- [Web Applications in Racket](https://docs.racket-lang.org/web-server/) — 第 15 章の続き
- [Typed Racket](https://docs.racket-lang.org/ts-guide/) — 静的型付けの手引き
- [Macros: The Racket Guide, Ch. 16](https://docs.racket-lang.org/guide/macros.html) — 公式のマクロ解説
- [Fear of Macros](https://www.greghendershott.com/fear-of-macros/) — マクロ恐怖症を治してくれる名文

## A.2 書籍

### 英語

1. **Matthias Felleisen, *How to Design Programs* (2nd ed.)** — Racket を作った人たちによる、プログラム設計の教科書。本書より「設計レシピ」寄りで、入門者・再入門者に圧倒的に効く
2. **Matthew Butterick, *Beautiful Racket*** — 「Racket で自作言語(`#lang`)を作る」分野の決定版。Web 公開あり
3. **Shriram Krishnamurthi, *Programming Languages: Application and Interpretation*** — インタプリタの書き方を Racket で学ぶ大学教科書。第 14 章を深めたい人向け
4. **Daniel Friedman & Matthias Felleisen, *The Little Schemer*** — Scheme の古典。読み物として楽しい
5. **Abelson & Sussman, *Structure and Interpretation of Computer Programs* (SICP)** — Scheme 系プログラミングの聖典。Racket でもほぼ動く

### 日本語

- 公式ドキュメント以外で、Racket 特化の日本語書籍は多くありません(だから本書を書く価値があるわけです)
- Lisp / 関数型の一般書としては
  - 『計算機プログラムの構造と解釈』(日本語訳 SICP)
  - 『Scheme 手習い』(The Little Schemer 日本語訳)
  - 『プログラミング Gauche』(Gauche Scheme だが Racket とも通じる)
  - 『関数プログラミング実践入門』(Haskell 主体だが、関数型思考に効く)

## A.3 コミュニティ

- **Discord**: <https://discord.gg/6Zq8sH5> — 公式 Discord。初心者質問も歓迎
- **Mailing list**: `racket-users@googlegroups.com`
- **Slack**: 公式 Discord へ移行中だが一部活発
- **GitHub**: <https://github.com/racket> — 処理系・標準ライブラリのソース。PR を読むだけでも勉強になる
- **Reddit**: `/r/Racket` で質問・発表が見られる

日本語では:

- `#Racket` / `#Scheme` タグで Qiita、Zenn、ブログに多少記事あり
- Lisp 系勉強会(Lisp Meet Up、Shibuya.lisp など)で Racket 話題も出る

## A.4 実際に手を動かし続けるコツ

本を読み終えた後こそが本番です。次のようなサイクルを回すと、Racket が手に馴染みます。

1. **何か作る** — 小さなツールや習作。本書の演習の続き、あるいは業務の一部を Racket に翻訳してみる
2. **ライブラリソースを読む** — `racket/list`, `racket/match` の中身は Racket で書かれている。標準的な書き方の宝庫
3. **公式 Blog / Racket News** — リリースノートで新機能・DSL の流行を追う
4. **AoC や Project Euler** — 小問題を Racket で解くと言語感覚が鍛えられる
5. **自作 `#lang`** — 一度作ると言語観が変わる。Beautiful Racket 推奨

## A.5 本書で触れなかったトピック一覧

- `generator` / `coroutine` の深い用法
- `plot` — 関数描画
- `2htdp/image` / `2htdp/universe` — 教育用のアニメーション・ゲームフレームワーク
- `data/` コレクション — 永続データ構造、優先度キュー、B 木 など
- `db` — SQL データベース接続
- `net/url`, `net/http-client`, `crypto` — ネットワーク・暗号
- `threading` / `threading-lib` — `->` / `->>` スレッドマクロ
- `racket/contract/combinator` — カスタム契約
- Typed Racket の `Refinement types`, `Occurrence Typing` 詳細
- `chaperone`, `impersonator`, `redirect` — オブジェクトの動的包み込み

これらはどれも独立した章を要するボリュームなので、**本書の第 2 版で追加する候補** です。

## A.6 最後に

「まず動くコード、次に読めるコード、最後にマクロで言語ごと変える」 — これが Racket のリズムです。
本書で身に付けた基礎を持って、ぜひ公式ドキュメントの海に潜ってみてください。そこには `#lang` が何十種類も並ぶ、他のどの言語にもない景色が広がっています。

Happy hacking!
