# はじめよう

## この章の目標

この章では実際のPureScriptの開発環境を立ち上げ、
いくつかの演習を解き、
この本で提供されているテストを使って答えを確認します。
もし学習の仕方が合っていれば
[この章を通して進めるビデオ](https://www.youtube.com/watch?v=GPjPwb6d-70)
が役に立つでしょう。

## 環境構築

最初にドキュメンテーションリポジトリにあるこの
[Getting Started
Guide](https://github.com/purescript/documentation/blob/master/guides/Getting-Started.md)
を通しで進め、環境の構築と言語の基礎を学んでください。
[Project Euler](http://projecteuler.net/problem=1)
への解答例にあるコードがわかりにくかったり見慣れない構文を含んでいたとしても心配要りません。
来たる章でこの全ての内容をとても詳細に押さえていきます。

## 演習を解く

ここまでで必要な開発ツールをインストールできているので、この本のリポジトリをクローンしてください。

```sh
git clone https://github.com/purescript-contrib/purescript-book.git
```

本のリポジトリにはPureScriptのコード例とそれぞれの章に付属する演習のための単体テストが含まれます。
演習の解法を白紙に戻すために必要な初期設定があり、こうすることで解く準備ができます。
`resetSolutions.sh`スクリプトを使ってこの工程を簡単にできます。
その間に`removeAnchors.sh`スクリプトで全てのアンカーコメントを取り除いておくのもよいでしょう。
（これらのアンカーはコードスニペットを本の変換後のMarkdownにコピーするために使われており、
自分のローカルリポジトリではこのアンカーが散らかっていないほうがよいでしょう。）

```sh
cd purescript-book
./scripts/resetSolutions.sh
./scripts/removeAnchors.sh
git add .
git commit --all --message "Exercises ready to be solved"
```

それではこの章のテストを走らせましょう。

```sh
cd exercises/chapter2
spago test
```

以下の成功したテスト出力が出るでしょう。

```sh
→ Suite: Euler - Sum of Multiples
  ✓ Passed: below 10
  ✓ Passed: below 1000

All 2 tests passed! 🎉
```

なお、`answer`節（`src/Euler.purs`にあります）は、
あらゆる整数以下の3と5の倍数を見付けるように変更されています。
この`answer`関数のためのテストスート（`test/Main.purs`にあります）は
Getting Started Guideの冒頭にあるテストよりも網羅的です。
はじめの章を読んでいる間はこのテストフレームワークの仕組みを理解しようと思い詰めなくて大丈夫です。

本の残りの部分には多くの演習が含まれます。
`Test.MySolutions`モジュール (`test/MySolutions.purs`) に自分の解法を書けば、
提供されているテストスートを使って確認できます。

テスト駆動開発のスタイルでこの次の演習を一緒に進めてみましょう。

## 演習

1. （普通）直角三角形の対角線（あるいは斜辺）の長さを
   他の2つの辺の長さを使って計算する`diagonal`関数を書いてください。

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

まずはこの関数が欠陥のあるバージョンであるときに何が起こるのか見てみましょう。
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
ピタゴラスの定理を正しい適用することでこれを修正しましょう。
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

成功です！
これで次の演習を自力で解くための準備ができました。

## 演習

 1. （簡単）指定された半径の円の面積を計算する関数`circleArea`を書いてみましょう。
    `Numbers`モジュールで定義されている `pi`定数を使用してください。
    **ヒント**： `import Data.Number`文を修正して、 `pi`をインポートすることを忘れないようにしましょう。
 1. （普通）`Int`を取って`100`で割ったあとの余りを返す関数`leftoverCents`を書いてみましょう。
    `rem`関数を使ってください。
    [Pursuit](https://pursuit.purescript.org/)でこの関数を検索して、
    使用法とどのモジュールからインポートしてくるか調べましょう。
    **補足**：自動補完の提案を受け付ければ、IDEでこの関数の自動的なインポートがサポートされているかもしれません。

## まとめ

この章ではPureScriptコンパイラとSpagoツールをインストールしました。
演習の解答の書き方と正しさの確認方法も学びました。

この先の章にはより多くの演習があり、それらに取り組むうちに学習の助けになっているでしょう。
演習のどこかでお手あげになったら、
この本の[困ったときは](chapter1.ja.md#getting-help)の節に挙げられている
コミュニティの資料のどれでも見てみるか、
この[本のリポジトリ](https://github.com/purescript-contrib/purescript-book/issues)にイシューを報告することさえできます。
こうした演習の敷居を下げることに繋がる読者のフィードバックが、本の向上の助けになっています。

章の全ての演習を解いたら、`no-peeking/Solutions.purs`にあるものと解答とを比べられます。
ただしカンニングしてはだめで、これらの演習を誠実に自力で解く労力を払わないことがないようにしてください。
そしてたとえ行き詰まったにしても、まずはコミュニティメンバーに尋ねてみるようにしてください。
演習のネタバレをするよりも、小さなヒントをあげたいからです。
もっとエレガントな解法（とはいえ本の内容で押さえられている知識のみを必要とするもの）を見つけたときはPRを送ってください。

リポジトリは継続して改訂されているため、それぞれの新しい章を始める前に更新を確認するようにしてください。
