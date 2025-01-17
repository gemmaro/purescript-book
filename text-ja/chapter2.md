# はじめよう

## この章の目標

本章では実際のPureScriptの開発環境を立ち上げ、幾つかの演習を解き、本書で提供されているテストを使って答えを確認します。
もし映像を見る学習の仕方が合っているようでしたら、[本章を通しで進めるビデオ](https://www.youtube.com/watch?v=GPjPwb6d-70)が役に立つでしょう。

## 環境構築

最初にドキュメンテーションリポジトリにあるこの[はじめの手引き](https://github.com/purescript/documentation/blob/master/guides/Getting-Started.md)を通しで進め、環境の構築と言語の基礎を学んでください。[Project
Euler](http://projecteuler.net/problem=1)の解答例にあるコードがわかりにくかったり見慣れない構文を含んでいたとしても心配要りません。来たる章でこの全ての内容をとても丁寧に押さえていきます。

### エディタの対応

PureScriptを書く上で（例えば本書の演習を解くなど）お好みのエディタを使えます。
[エディタの対応についてのドキュメント](https://github.com/purescript/documentation/blob/master/ecosystem/Editor-and-tool-support.md#editor-support)を参照してください。

> なお、完全なIDE対応のため、開いたプロジェクトのルートに`spago.dhall`があることを期待するエディタもあります。
> 例えば本章の演習に取り組む場合、`chapter2`ディレクトリを開くとよいでしょう。
>
> VS Codeを使っている場合、提供されているワークスペースを使って全ての章を同時に開くことができます。

## 演習を解く

ここまでで必要な開発ツールをインストールできているので、本書のリポジトリをクローンしてください。

```sh
git clone https://github.com/purescript-contrib/purescript-book.git
```

本書のリポジトリには各章に付属してPureScriptのコード例と演習のための単体テストが含まれます。
演習の解法を白紙に戻すために必要な初期設定があり、この設定をすることで解く準備ができます。
この工程は`prepareExercises.sh`スクリプトを使えば簡単にできます。

```sh
cd purescript-book
./scripts/prepareExercises.sh
git add .
git commit --all --message "Exercises ready to be solved"
```

それではこの章のテストを走らせましょう。

```sh
cd exercises/chapter2
spago test
```

以下の成功した旨のテスト出力が出るでしょう。

```sh
→ Suite: Euler - Sum of Multiples
  ✓ Passed: below 10
  ✓ Passed: below 1000

All 2 tests passed! 🎉
```

なお、（`src/Euler.purs`にある）`answer`関数は任意の整数以下の3と5の倍数を見付けるように変更されています。
（`test/Main.purs`にある）この`answer`関数のためのテストスートははじめの手引きの冒頭にあるテストよりも網羅的です。
前の方の章を読んでいる間はこのテストフレームワークの仕組みを理解しようと思い詰めなくて大丈夫です。

本書の残りの部分には多くの演習が含まれます。
`Test.MySolutions`モジュール (`test/MySolutions.purs`)
に自分の解法を書けば、提供されているテストスートを使って確認できます。

テスト駆動開発でこの次の演習を一緒に進めてみましょう。

## 演習

1. （普通）直角三角形の対角線（あるいは斜辺）の長さを他の2つの辺の長さを使って計算する`diagonal`関数を書いてください。

## 解法

この演習のテストを有効にするところから始めます。
以下に示すようにブロックコメントの開始を数行下に下げてください。
ブロックコメントは`{-`から始まり`-}`で終わります。

```hs
{{#include ../exercises/chapter2/test/Main.purs:diagonalTests}}
    {-  Move this block comment starting point to enable more tests
```

ここでテストを走らせようとすると、コンパイルエラーに直面します。
なぜなら`diagonal`関数をまだ実装していないからです。

```sh
$ spago test

Error found:
in module Test.Main
at test/Main.purs:21:27 - 21:35 (line 21, column 27 - line 21, column 35)

  Unknown value diagonal
```

まずはこの関数に欠陥があるときに何が起こるのか見てみましょう。
以下のコードを`test/MySolutions.purs`に追加してください。

```hs
import Data.Number (sqrt)

diagonal w h = sqrt (w * w + h)
```

そして`spago test`を走らせて確認してください。

```hs
→ Suite: diagonal
  ☠ Failed: 3 4 5 because expected 5.0, got 3.605551275463989
  ☠ Failed: 5 12 13 because expected 13.0, got 6.082762530298219

2 tests failed:
```

あーあ、全然正しくありませんでした。
ピタゴラスの定理を正しく適用して修正しましょう。
関数を以下のように変えます。

```hs
{{#include ../exercises/chapter2/test/no-peeking/Solutions.purs:diagonal}}
```

ここでもう一度`spago test`としてみると全てのテストが通っています。

```hs
→ Suite: Euler - Sum of Multiples
  ✓ Passed: below 10
  ✓ Passed: below 1000
→ Suite: diagonal
  ✓ Passed: 3 4 5
  ✓ Passed: 5 12 13

All 4 tests passed! 🎉
```

成功です。
これで次の演習を自力で解くための準備ができました。

## 演習

 1. （簡単）指定された半径の円の面積を計算する関数`circleArea`を書いてみましょう。
    `Numbers`モジュールで定義されている `pi`定数を使用してください。
    *手掛かり*： `import Data.Number`文を修正して、 `pi`をインポートすることを忘れないようにしましょう。
 1. （普通）`Int`を取って`100`で割ったあとの余りを返す関数`leftoverCents`を書いてみましょう。`rem`関数を使ってください。[Pursuit](https://pursuit.purescript.org/)でこの関数を検索して、使用法とどのモジュールからインポートしてくるか調べましょう。*補足*：自動補完の提案を有効にしていたら、IDE側でこの関数の自動的なインポートに対応しているかもしれません。

## まとめ

この章ではPureScriptコンパイラとSpagoツールをインストールしました。
演習の解答の書き方と正しさの確認方法も学びました。

この先の章にはもっと沢山の演習があり、それらに取り組むうちに内容を学ぶ助けになっているでしょう。
演習のどこかでお手上げになったら、本書の[困ったときは](chapter1.ja.md#getting-help)の節に挙げられているコミュニティの資料のどれかに手を伸ばしたり、[本書のリポジトリ](https://github.com/purescript-contrib/purescript-book/issues)でイシューを報告したりできます。
こうした演習の敷居を下げることに繋がる読者のフィードバックのお陰で本書が改善されています。

章の全ての演習を解いたら、`no-peeking/Solutions.purs`にあるものと解答とを比べられます。
カンニングはせず、演習を誠実に自力で解く労力を割いてください。
そしてたとえ行き詰まったにしても、まずはコミュニティメンバーに尋ねてみるようにしてください。
ネタバレをするよりも小さな手掛かりをあげたいからです。
もっとエレガントな解法（とはいえ本書で押さえられている知識のみで済むもの）を見つけたときはPRを送ってください。

リポジトリは継続して改訂されているため、それぞれの新しい章を始める前に更新を確認するようにしてください。
