# DrRacket 日本語ハンズオン

Racket / DrRacket を、他言語の経験はあるが Lisp はこれからという人のために、腰を据えて学ぶための日本語ハンズオン資料です。公式の *Quick: An Introduction to Racket with Pictures* よりも一段厚く、**「Lisp 的な考え方」** が手を動かしながら腑に落ちることを目標にしています。

> 本資料は筆者(hama-jp)が自分用に書いたノートを、同じように DrRacket を学び始める人にも役立つよう整えたものです。間違いや分かりにくい箇所があれば Issue / Pull Request で指摘してもらえると嬉しいです。

## この本の対象読者

- 他の言語(Python / JavaScript / Java / Go / Ruby など)で、関数定義・if 文・ループ・配列くらいは書いたことがある
- Lisp 系の言語(Scheme / Common Lisp / Clojure / Emacs Lisp)は **ほとんど触ったことがない、あるいは括弧で挫折した**
- 「Lisp がなぜ特別なのか」「S式とは何なのか」「関数型ってどう考えるのか」を、単語ではなく手触りで理解したい
- せっかくなら **DSL やマクロ、小さな処理系** まで書いてみたい

逆に以下のような読者は、別の資料の方が合います。

- プログラミング自体が完全に初めて → 公式の *How to Design Programs* の方が丁寧です
- Clojure / Common Lisp だけを使いたい → 本書は Racket / DrRacket に強く特化しています

## 読み進め方

1. まず「第 0 部 はじめに」→「第 1 部 最初の一歩」を順に読み、開発環境を整える
2. 第 2 部「Lisp の考え方を身につける」は **飛ばさず順番に** 読むのがおすすめ
3. 第 3 部以降は興味のあるところから取り組んで構わない
4. 各章の末尾にある **「手を動かしてみよう」** は必ず DrRacket で実行する

## 目次

### 第 0 部 はじめに

- [はじめに](book/00-preface.md) — 本書の方針、凡例、Racket の版
- [第 1 章 DrRacket / Racket / Lisp の地図](book/01-welcome.md) — なぜ Racket か、そして Lisp とは

### 第 1 部 最初の一歩

- [第 2 章 DrRacket のインストールと画面ツアー](book/02-setup.md)
- [第 3 章 はじめてのプログラム](book/03-first-steps.md) — REPL と Definitions Window、`#lang` の意味

### 第 2 部 Lisp の考え方を身につける

- [第 4 章 S式と評価モデル](book/04-s-expressions.md) — 前置記法はなぜ自然か
- [第 5 章 関数を値として扱う](book/05-functions.md) — `define` / `lambda` / クロージャ
- [第 6 章 再帰で考える](book/06-recursion.md) — ループがない世界、末尾再帰
- [第 7 章 リストとコンスセル](book/07-lists.md) — `cons` / `car` / `cdr` と不変リスト
- [第 8 章 高階関数とデータ変換](book/08-higher-order.md) — `map` / `filter` / `foldl`、関数合成

### 第 3 部 データと構造

- [第 9 章 構造体とパターンマッチ](book/09-data-structures.md) — `struct` / `match` / ベクタ / ハッシュ
- [第 10 章 状態・入出力・例外](book/10-state-io.md) — 副作用を意識的に扱う

### 第 4 部 プロジェクトとして書く

- [第 11 章 モジュールとパッケージ](book/11-modules.md) — `#lang` / `require` / `raco pkg`
- [第 12 章 テストと契約プログラミング](book/12-testing-contracts.md) — `rackunit` と `contract-out`

### 第 5 部 ハンズオン:作って理解する

- [第 13 章 画像 DSL を書く](book/13-picture-dsl.md) — 関数合成で絵を描く
- [第 14 章 小さな Lisp 処理系を作る](book/14-mini-lisp.md) — 評価器を自分で書く
- [第 15 章 Web アプリで遊ぶ](book/15-web-app.md) — `web-server/servlet-env`

### 第 6 部 さらに深く

- [第 16 章 マクロ入門](book/16-macros.md) — `define-syntax` / `syntax-rules` / `syntax-parse`
- [第 17 章 発展トピック](book/17-advanced.md) — 継続、Typed Racket、遅延、`for` フォーム
- [付録 さらに学ぶために](book/99-bibliography.md)

## ディレクトリ構成

```
DrRacket-Japanese-Tutoria/
├── README.md           # この目次
├── book/               # 本文(章ごとに Markdown)
├── examples/           # 各章の実行可能サンプル(*.rkt)
│   └── chNN/           # 章番号ごとに格納
└── images/             # 図や PNG など
```

## 動作確認環境

本書の実行例は以下で動作確認しています。

- Racket v8.10 (CS) 以降
- DrRacket v8.10 以降
- Ubuntu 24.04 / macOS 14 / Windows 11

Racket はバージョン間の互換性が高いので、v8.x 系であればほぼそのまま動作するはずです。v7 系や Racket BC(バイトコード VM 版)では一部の例が動かないことがあります。

## 凡例

- コードブロックは原則として実行可能。示している出力は **実際に Racket で実行した結果** です。
- `>` で始まる行は REPL への入力、続く行が出力です。
- Mermaid 図は GitHub 上の Markdown でそのまま描画されます。
- 章末の「**手を動かしてみよう**」は、本文で学んだことを自分の言葉で確かめるための演習です。

## ライセンス

本文・サンプルコードともに MIT License で配布します。詳しくは [LICENSE](LICENSE) を参照してください。
