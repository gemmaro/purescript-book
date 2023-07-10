# はじめよう

## この章の目標

この章では実際のPureScriptの開発環境を立ち上げ、幾つかの演習を解き、この本で提供されているテストを使って答えを確認します。
もし映像を見る学習の仕方が合っているようでしたら、[この章を通しで進めるビデオ](https://www.youtube.com/watch?v=GPjPwb6d-70)が役に立つでしょう。

## 環境構築

最初にドキュメンテーションリポジトリにあるこの[はじめの手引き](https://github.com/purescript/documentation/blob/master/guides/Getting-Started.md)を通しで進め、環境の構築と言語の基礎を学んでください。[Project
Euler](http://projecteuler.net/problem=1)の解答例にあるコードがわかりにくかったり見慣れない構文を含んでいたとしても心配要りません。来たる章でこの全ての内容をとても丁寧に押さえていきます。

### エディタの対応

PureScriptを書く上で（例えば本書の演習を解くなど）お好みのエディタを使えます。
[エディタの対応についてのドキュメント](https://github.com/purescript/documentation/blob/master/ecosystem/Editor-and-tool-support.md#editor-support)を参照してください。

> なお、完全なIDEの対応をするために、開いたプロジェクトのルートに`spago.dhall`があることを期待するエディタもあります。
> 例えば本章の演習に取り組む場合、`chapter2`ディレクトリを開くとよいでしょう。
>
> VS Codeを使っている場合、提供されているワークスペースを使って全ての章を同時に開くことができます。

## 演習を解く

ここまでで必要な開発ツールをインストールできているので、この本のリポジトリをクローンしてください。

```sh
git clone https://github.com/purescript-contrib/purescript-book.git
```

The book repo contains PureScript example code and unit tests for the
exercises that accompany each chapter. There's some initial setup required
to reset the exercise solutions so they are ready to be solved by you. Use
the `resetSolutions.sh` script to simplify this process. While at it, you
should also strip out all the anchor comments with the `removeAnchors.sh`
script (these anchors are used for copying code snippets into the book's
rendered markdown, and you probably don't need this clutter in your local
repo):

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

以下の成功した旨のテスト出力が出るでしょう。

```sh
→ Suite: Euler - Sum of Multiples
  ✓ Passed: below 10
  ✓ Passed: below 1000

All 2 tests passed! 🎉
```

Note that the `answer` function (found in `src/Euler.purs`) has been
modified to find the multiples of 3 and 5 below any integer. The test suite
(located in `test/Main.purs`) for this `answer` function is more
comprehensive than the test in the earlier getting-started guide. Don't
worry about understanding how this test framework code works while reading
these early chapters.

本の残りの部分には多くの演習が含まれます。
`Test.MySolutions`モジュール (`test/MySolutions.purs`)
に自分の解法を書けば、提供されているテストスートを使って確認できます。

Let's work through this next exercise together in a test-driven-development
style.

## 演習

1. （普通）直角三角形の対角線（あるいは斜辺）の長さを他の2つの辺の長さを使って計算する`diagonal`関数を書いてください。

## 解法

We'll start by enabling the tests for this exercise. Move the start of the
block-comment down a few lines, as shown below. Block comments start with
`{-` and end with `-}`:

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

Let's first look at what happens with a faulty version of this function. Add
the following code to `test/MySolutions.purs`:

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

There will be many more exercises in the chapters ahead, and working through
those helps with learning the material. If any of the exercises stumps you,
please reach out to any of the community resources listed in the [Getting
Help](https://book.purescript.org/chapter1.html#getting-help) section of
this book, or even file an issue in this [book's
repo](https://github.com/purescript-contrib/purescript-book/issues). This
reader feedback on which exercises could be made more approachable helps us
improve the book.

Once you solve all the exercises in a chapter, you may compare your answers
against those in the `no-peeking/Solutions.purs`. No peeking, please,
without putting in an honest effort to solve these yourself. And even if you
are stuck, try asking a community member for help first, as we would prefer
to give you a small hint rather than spoil the exercise. If you found a more
elegant solution (that only requires knowledge of the covered content),
please send us a PR.

リポジトリは継続して改訂されているため、それぞれの新しい章を始める前に更新を確認するようにしてください。
