# 再帰、マップ、畳み込み

> 一時的な注意事項：本章に取り組まれているようでしたら、2023年11月に第4章と第5章とが入れ替わっていることにお気を付けください。

## この章の目標

この章では、アルゴリズムを構造化するときに再帰関数をどのように使うかについて見ていきましょう。
再帰は関数型プログラミングの基本的な手法であり、本書全体に亙って使われます。

また、PureScriptの標準ライブラリから標準的な関数を幾つか取り扱います。
`map`や`fold`といった関数だけでなく、`filter`や`concatMap`といった特別な場合において便利なものについても見ていきます。

この章では、仮想的なファイルシステムを操作する関数のライブラリを動機付けに用います。
この章で学ぶ技術を応用し、ファイルシステムのモデルにより表現されるファイルのプロパティを計算する関数を書きます。

## プロジェクトの準備

この章のソースコードは`src/Data/Path.purs`と`test/Examples.purs`に含まれています。
`Data.Path`モジュールは仮想ファイルシステムのモデルを含みます。
このモジュールの内容を変更する必要はありません。
演習への解答は`Test.MySolutions`モジュールに実装してください。
それぞれの演習を完了させつつ都度`Test.Main`モジュールにある対応するテストを有効にし、`spago
test`を走らせることで解答を確認してください。

このプロジェクトには以下の依存関係があります。

- `maybe`: `Maybe`型構築子が定義されています。
- `arrays`: 配列を扱うための関数が定義されています。
- `strings`: JavaScriptの文字列を扱うための関数が定義されています。
- `foldable-traversable`: 配列やその他のデータ構造を畳み込む関数が定義されています。
- `console`: コンソールへの出力を扱うための関数が定義されています。

## 導入

再帰は一般のプログラミングでも重要な手法ですが、特に純粋関数型プログラミングでは当たり前のように用いられます。この章で見ていくように、再帰はプログラムの変更可能な状態を減らすために役立つからです。

再帰は*分割統治*戦略と密接な関係があります。
分割統治とはすなわち、何らかの入力としての問題を解くにあたり、入力を小さな部分に分割してそれぞれの部分について問題を解き、部分毎の答えから最終的な答えを組み立てるということです。

それでは、PureScriptにおける再帰の簡単な例を幾つか見てみましょう。

次に示すのは*階乗関数*のありふれた例です。

```haskell
{{#include ../exercises/chapter5/test/Examples.purs:factorial}}
```

このように、問題を部分問題へ分割することによって階乗関数の計算方法が見てとれます。
より小さい数の階乗を計算していくということです。
ゼロに到達すると、答えは直ちに求まります。

次は、*フィボナッチ関数*を計算するという、これまたよくある例です。

```haskell
{{#include ../exercises/chapter5/test/Examples.purs:fib}}
```

やはり、部分問題の解決策を考えることで全体を解決していることがわかります。
このとき、`fib (n - 1)`と`fib (n - 2)`という式に対応した、2つの部分問題があります。
これらの2つの部分問題が解決されていれば、この部分的な答えを加算することで、全体の答えを組み立てることができます。

## 配列上での再帰

再帰関数の定義は`Int`型だけに限定されるものではありません。
本書の後半で*パターン照合*を扱うときに、いろいろなデータ型の上での再帰関数について見ていきますが、ここでは数と配列に限っておきます。

入力がゼロでないかどうかについて分岐するのと同じように、配列の場合も、配列が空でないかどうかについて分岐していきます。再帰を使用して配列の長さを計算する次の関数を考えてみます。

```haskell
import Prelude

import Data.Array (null, tail)
import Data.Maybe (fromMaybe)

{{#include ../exercises/chapter5/test/Examples.purs:length}}
```

この関数では、配列が空かどうかに基づいて分岐しています。
`null`関数は、空配列については`true`を返します。
空配列は長さ0を、非空配列は尾鰭の長さより1大きい長さを持ちます。

`tail`関数は与えられた配列から最初の要素を除いたものを`Maybe`に包んで返します。
配列が空であれば（つまり尾鰭がなければ）`Nothing`が返ります。
`fromMaybe`関数は既定値と`Maybe`値を取ります。
後者が`Nothing`であれば既定値を返し、そうでなければ`Just`に包まれた値を返します。

JavaScriptで配列の長さを調べるのには、この例はどう見ても実用的な方法とはいえませんが、次の演習を完遂するための手掛かりとしては充分でしょう。

## 演習

 1. （簡単）入力が偶数であるとき、かつそのときに限り`true`に返す再帰関数`isEven`を書いてみましょう。
 2. （普通）配列内の偶数の整数を数える再帰関数`countEven`を書いてみましょう。
    *手掛かり*：`head`関数（これも`Data.Array`モジュールから手に入ります）を使うと、空でない配列の最初の要素を見つけられます。

## マップ

`map`関数は配列に対する再帰関数の一例です。
配列の各要素に順番に関数を適用し、配列の要素を変換するのに使われます。
そのため、配列の*内容*は変更されますが、その*形状*（ここでは「長さ」）は保存されます。

本書の後半で*型クラス*の内容を押さえるとき、`map`関数が形状を保存する関数のより一般的な様式の一例であることを見ていきます。
この関数は*関手*と呼ばれる型構築子のクラスを変換するものです。

それでは、PSCiで`map`関数を試してみましょう。

```text
$ spago repl

> import Prelude
> map (\n -> n + 1) [1, 2, 3, 4, 5]
[2, 3, 4, 5, 6]
```

`map`がどのように使われているかに注目してください。
最初の引数には配列上で「写す」関数、第2引数には配列そのものを渡します。

## 中置演算子

バッククォートで関数名を囲むと、写す関数と配列の間に、`map`関数を書くことができます。

```text
> (\n -> n + 1) `map` [1, 2, 3, 4, 5]
[2, 3, 4, 5, 6]
```

この構文は _中置関数適用_ と呼ばれ、どんな関数でもこのように中置できます。普通は2引数の関数に対して使うのが最適でしょう。

配列を扱う際は`map`関数と等価な`<$>`という演算子が存在します。

```text
> (\n -> n + 1) <$> [1, 2, 3, 4, 5]
[2, 3, 4, 5, 6]
```

それでは`map`の型を見てみましょう。

```text
> :type map
forall (f :: Type -> Type) (a :: Type) (b :: Type). Functor f => (a -> b) -> f a -> f b
```

実は`map`の型は、この章で必要とされているものよりも一般的な型になっています。今回の目的では、`map`は次のようなもっと具体的な型であるかのように考えるとよいでしょう。

```text
forall (a :: Type) (b :: Type). (a -> b) -> Array a -> Array b
```

この型では、`map`関数に適用するときには`a`と`b`という2つの型を自由に選ぶことができる、ということも示されています。
`a`は元の配列の要素の型で、`b`は目的の配列の要素の型です。
もっと言えば、`map`が配列の要素の型を保存する必要があるわけではありません。
例えば`map`を使用すると数値を文字列に変換できます。

```text
> show <$> [1, 2, 3, 4, 5]

["1","2","3","4","5"]
```

中置演算子`<$>`は特別な構文のように見えるかもしれませんが、実はPureScriptの普通の関数の別称です。
中置構文を使用した単なる*適用*にすぎません。
実際、括弧でその名前を囲むと、この関数を通常の関数のように使用できます。
これは、`map`代わりに、括弧で囲まれた`(<$>)`という名前が使えるということです。

```text
> (<$>) show [1, 2, 3, 4, 5]
["1","2","3","4","5"]
```

中置関数は既存の関数名の別称として定義されます。
例えば`Data.Array`モジュールでは次のように`range`関数の同義語として中置演算子`(..)`を定義しています。

```haskell
infix 8 range as ..
```

この演算子は次のように使うことができます。

```text
> import Data.Array

> 1 .. 5
[1, 2, 3, 4, 5]

> show <$> (1 .. 5)
["1","2","3","4","5"]
```

*補足*：独自の中置演算子は、自然な構文を備える領域特化言語を定義する上で優れた手段になりえます。ただし、乱用すると初心者が読めないコードになることがありますから、新たな演算子の定義には慎重になるのが賢明です。

上記の例では、`1 .. 5`という式は括弧で囲まれていましたが、実際にはこれは必要ありません。
なぜなら、`Data.Array`モジュールは、`<$>`に割り当てられた優先順位より高い優先順位を`..`演算子に割り当てているからです。
上の例では、`..`の優先順位は、キーワード`infix`のあとに書かれた数の`8` と定義されていました。
ここでは`<$>`の優先順位よりも高い優先順位を`..`に割り当てており、このため括弧を付け加える必要がないということです。

```text
> show <$> 1 .. 5
["1","2","3","4","5"]
```

中置演算子に（左または右の）*結合性*を与えたい場合は、代わりにキーワード`infixl`と`infixr`を使います。
`infix`を使うと何ら結合性は割り当てられず、同じ演算子を複数回使ったり複数の同じ優先度の演算子を使ったりするときに、式を括弧で囲まなければいけなくなります。

## 配列の絞り込み

`Data.Array`モジュールでは他にも、よく`map`と一緒に使われる関数`filter`も提供しています。
この関数は、述語関数に照合する要素のみを残し、既存の配列から新しい配列を作成する機能を提供します。

例えば1から10までの数で、偶数であるような数の配列を計算したいとします。
これは次のようにできます。

```text
> import Data.Array

> filter (\n -> n `mod` 2 == 0) (1 .. 10)
[2,4,6,8,10]
```

## 演習

 1. （簡単）`map`関数や`<$>`関数を使用して、 配列に格納された数のそれぞれの平方を計算する関数`squared`を書いてみましょう。
    *手掛かり*：`map`や`<$>`といった関数を使ってください。
 1. （簡単）`filter`関数を使用して、数の配列から負の数を取り除く関数`keepNonNegative`を書いてみましょう。
    *手掛かり*：`filter`関数を使ってください。
 1. （普通）
    - `filter`の中置同義語`<$?>`を定義してください。
      *補足*：中置同義語はREPLでは定義できないかもしれませんが、ファイルでは定義できます。
    - 関数`keepNonNegativeRewrite`を書いてください。この関数は`filter`を独自の新しい中置演算子`<$?>`で置き換えたところ以外、`keepNonNegative`と同じです。
    - PSCiで独自の演算子の優先度合いと結合性を試してください。
      *補足*：この問題のための単体試験はありません。

## 配列の平坦化

配列に関する標準的な関数として`Data.Array`で定義されているものには、`concat`関数もあります。`concat`は配列の配列を1つの配列へと平坦化します。

```text
> import Data.Array

> :type concat
forall (a :: Type). Array (Array a) -> Array a

> concat [[1, 2, 3], [4, 5], [6]]
[1, 2, 3, 4, 5, 6]
```

関連する関数として、`concat`と`map`を組み合わせた`concatMap`と呼ばれる関数もあります。
`map`は（相異なる型の可能性がある）値からの値への関数を引数に取りますが、それに対して`concatMap`は値から値の配列への関数を取ります。

実際に動かして見てみましょう。

```text
> import Data.Array

> :type concatMap
forall (a :: Type) (b :: Type). (a -> Array b) -> Array a -> Array b

> concatMap (\n -> [n, n * n]) (1 .. 5)
[1,1,2,4,3,9,4,16,5,25]
```

ここでは、数をその数とその数の平方の2つの要素からなる配列に写す関数`\n -> [n, n * n]`を引数に`concatMap`を呼び出しています。
結果は10個の整数の配列です。
配列は1から5の数とそのそれぞれの数の平方からなります。

`concatMap`がどのように結果を連結しているのかに注目してください。渡された関数を元の配列のそれぞれの要素について一度ずつ呼び出し、その関数はそれぞれ配列を生成します。最後にそれらの配列を単一の配列に押し潰したものが結果となります。

`map`と`filter`、`concatMap`は、「配列内包表記」(array comprehensions)
と呼ばれる、配列に関するあらゆる関数の基盤を形成します。

## 配列内包表記

数`n`の2つの因数を見つけたいとしましょう。
こうするための簡単な方法としては、総当りで調べる方法があります。
つまり、`1`から`n`の数の全ての組み合わせを生成し、それを乗算してみるわけです。
もしその積が`n`なら、`n`の因数の組み合わせを見つけたということになります。

配列内包表記を使用するとこれを計算できます。
PSCiを対話式の開発環境として使用し、1つずつこの手順を進めていきましょう。

最初の工程では`n`以下の数の組み合わせの配列を生成しますが、これには`concatMap`を使えばよいです。

`1 .. n`のそれぞれの数を配列`1 .. n`へと対応付けるところから始めましょう。

```text
> pairs n = concatMap (\i -> 1 .. n) (1 .. n)
```

この関数をテストしてみましょう。

```text
> pairs 3
[1,2,3,1,2,3,1,2,3]
```

これは求めているものとは全然違います。
単にそれぞれの組み合わせの2つ目の要素を返すのではなく、対全体を保持できるように、内側の`1 .. n`の複製について関数を対応付ける必要があります。

```text
> :paste
… pairs' n =
…   concatMap (\i ->
…     map (\j -> [i, j]) (1 .. n)
…   ) (1 .. n)
… ^D

> pairs' 3
[[1,1],[1,2],[1,3],[2,1],[2,2],[2,3],[3,1],[3,2],[3,3]]
```

いい感じになってきました。
しかし、`[1, 2]`と`[2, 1]`の両方があるように、重複した組み合わせが生成されています。
`j`を`i`から`n`の範囲に限定することで、2つ目の場合を取り除くことができます。

```text
> :paste
… pairs'' n =
…   concatMap (\i ->
…     map (\j -> [i, j]) (i .. n)
…   ) (1 .. n)
… ^D
> pairs'' 3
[[1,1],[1,2],[1,3],[2,2],[2,3],[3,3]]
```

すばらしいです。
因数の候補の全ての組み合わせを手に入れたので、`filter`を使えば、その積が`n`であるような組み合わせを選び出すことができます。

```text
> import Data.Foldable

> factors n = filter (\pair -> product pair == n) (pairs'' n)

> factors 10
[[1,10],[2,5]]
```

このコードでは、`foldable-traversable`ライブラリの`Data.Foldable`モジュールにある`product`関数を使っています。

うまくいきました。
因数の組み合わせの正しい集合を重複なく見つけることができました。

## do記法

しかし、このコードの可読性は大幅に向上できます。`map`や`concatMap`は基本的な関数であり、 _do記法_ (do notation)
と呼ばれる特別な構文の基礎になっています（もっと厳密にいえば、それらの一般化である`map`と`bind`が基礎をなしています）。

> *補足*：`map`と`concatMap`があることで*配列内包表記*を書けるように、もっと一般的な演算子である`map`と`bind`があることで*モナド内包表記*と呼ばれているものが書けます。
> 本書の後半では*モナド*の例をたっぷり見ていくことになりますが、この章では配列のみを考えます。

do記法を使うと、先ほどの`factors`関数を次のように書き直すことができます。

```haskell
{{#include ../exercises/chapter5/test/Examples.purs:factors}}
```

キーワード`do`はdo記法を使うコードのブロックを導入します。
このブロックは幾つかの種類の式で構成されています。

- 配列の要素を名前に束縛する式。
  これは後ろ向きの矢印`<-`で示されており、左側には名前が、右側には配列の型を持つ式があります。
- 名前に配列の要素を束縛しない式。
  `do`の*結果*はこの種類の式の一例であり、最後の行の`pure [i, j]`に示されています。
- `let`キーワードを使用し、式に名前を与える式。

この新しい記法を使うと、アルゴリズムの構造がわかりやすくなることがあります。
頭の中で`<-`を「選ぶ」という単語に置き換えるとすると、「1からnの間の要素`i`を選び、それからiからnの間の要素`j`を選び、`[i, j]`を返す」というように読むことができるでしょう。

最後の行では、`pure`関数を使っています。この関数はPSCiで評価できますが、型を明示する必要があります。

```text
> pure [1, 2] :: Array (Array Int)
[[1, 2]]
```

配列の場合、`pure`は単に1要素の配列を作成します。
`factors`関数を変更して、`pure`の代わりにこの形式も使うようにできます。

```haskell
{{#include ../exercises/chapter5/test/Examples.purs:factorsV2}}
```

そして、結果は同じになります。

## ガード

`factors`関数を更に改良する方法としては、このフィルタを配列内包表記の内側に移動するというものがあります。
これは`control`ライブラリにある`Control.Alternative`モジュールの`guard`関数を使用することで可能になります。

```haskell
import Control.Alternative (guard)

{{#include ../exercises/chapter5/test/Examples.purs:factorsV3}}
```

`pure`と同じように、どのように動作するかを理解するために、PSCiで`guard`関数を適用して調べてみましょう。
`guard`関数の型は、ここで必要とされるものよりもっと一般的な型になっています。

```text
> import Control.Alternative

> :type guard
forall (m :: Type -> Type). Alternative m => Boolean -> m Unit
```

> `Unit`型は何ら計算する内容の無い値を表現します。
> すなわち具体的で意味のある値が存在しないということです。
>
> `Unit`はよく型構築子に「包んで」計算の返却型として使います。
> その計算は具体的な値のためではなく、計算の*作用*（ないし結果の「形状」）のみに関心があるのです。
>
> 例えば、`main`関数は型`Effect Unit`を持ちます。
> この関数はプロジェクトへの入口であり、直接呼ぶものではありません。
>
> 型シグネチャ中の`m`の意味については第6章で説明します。

今回の場合は、PSCiは次の型を報告するものと考えてください。

```haskell
Boolean -> Array Unit
```

目的からすると、次の計算の結果から配列における`guard`関数について今知りたいことは全てわかります。

```text
> import Data.Array

> length $ guard true
1

> length $ guard false
0
```

つまり、`guard`が`true`に評価される式を渡された場合、単一の要素を持つ配列を返すのです。
もし式が`false`と評価された場合は、その結果は空です。

ガードが失敗した場合、配列内包表記の現在の分岐は、結果なしで早めに終了されることを意味します。
これは、`guard`の呼び出しが、途中の配列に対して`filter`を使用するのと同じだということです。
実践での場面にもよりますが、`filter`の代わりに`guard`を使いたいことは多いでしょう。
これらが同じ結果になることを確認するために、`factors`の2つの定義を試してみてください。

## 演習

 1. （簡単）関数`isPrime`を書いてください。
    この関数は整数の引数が素数であるかを調べます。
    *手掛かり*：`factors`関数を使ってください。
 1. （普通）do記法を使い、2つの配列の*直積集合*を見つけるための関数`cartesianProduct`を書いてみましょう。
    直積集合とは、要素`a`、`b`の全ての組み合わせの集合のことです。
    ここで`a`は最初の配列の要素、`b`は2つ目の配列の要素です。
 1. （普通）関数`triples :: Int -> Array (Array Int)`を書いてください。
    この関数は数値 \\( n \\) を取り、構成要素（値 \\( a \\)、 \\( b \\)、 \\( c \\)）がそれぞれ \\( n
    \\) 以下であるような全てのピタゴラスの3つ組 (pythagorean triples) を返します。
    *ピタゴラスの3つ組*は \\( a ^ 2 + b ^ 2 = c ^ 2 \\) であるような数値の配列 \\( [ a, b, c ]
    \\) です。
    *手掛かり*：配列内包表記で`guard`関数を使ってください。
 1. （難しい）`factors`関数を使用して、`n`の[素因数分解](https://www.mathsisfun.com/prime-factorization.html)を求める関数`primeFactors`を定義してみましょう。
    `n`の素因数分解とは、積が`n`であるような素数の配列のことです。
    *手掛かり*：1より大きい整数について、問題を2つの部分問題に分解してください。
    最初の因数を探し、それから残りの因数を探すのです。

## 畳み込み

配列における左右の畳み込みは、再帰を用いて実装できる別の興味深い一揃いの関数を提供します。

PSCiを使って、`Data.Foldable`モジュールをインポートし、`foldl`と`foldr`関数の型を調べることから始めましょう。

```text
> import Data.Foldable

> :type foldl
forall (f :: Type -> Type) (a :: Type) (b :: Type). Foldable f => (b -> a -> b) -> b -> f a -> b

> :type foldr
forall (f :: Type -> Type) (a :: Type) (b :: Type). Foldable f => (a -> b -> b) -> b -> f a -> b
```

これらの型は、現在興味があるものよりも一般化されています。
この章では単純化して以下の（より具体的な）型シグネチャと見て構いません。

```text
-- foldl
forall a b. (b -> a -> b) -> b -> Array a -> b

-- foldr
forall a b. (a -> b -> b) -> b -> Array a -> b
```

どちらの場合でも、型`a`は配列の要素の型に対応しています。
型`b`は「累算器」の型として考えることができます。
累算器とは配列を走査しつつ結果を累算するものです。

`foldl`関数と`foldr`関数の違いは走査の方向です。
`foldr`が「右から」配列を畳み込むのに対して、`foldl`は「左から」配列を畳み込みます。

実際にこれらの関数の動きを見てみましょう。
`foldl`を使用して数の配列の和を求めてみます。
型`a`は`Int`になり、結果の型`b`も`Int`として選択できます。
ここでは3つの引数を与える必要があります。
1つ目は次の要素を累算器に加算する`Int -> Int -> Int`という型の関数です。
2つ目は累算器の`Int`型の初期値です。
3つ目は和を求めたい`Int`の配列です。
最初の引数としては、加算演算子を使用できますし、累算器の初期値はゼロになります。

```text
> foldl (+) 0 (1 .. 5)
15
```

この場合では、引数が逆になっていても`(+)`関数は同じ結果を返すので、`foldl`と`foldr`のどちらでも問題ありません。

```text
> foldr (+) 0 (1 .. 5)
15
```

違いを説明するために、畳み込み関数の選択が大事になってくる例も書きましょう。
加算関数の代わりに、文字列連結を使用して文字列を構築しましょう。

```text
> foldl (\acc n -> acc <> show n) "" [1,2,3,4,5]
"12345"

> foldr (\n acc -> acc <> show n) "" [1,2,3,4,5]
"54321"
```

これは、2つの関数の違いを示しています。左畳み込み式は、以下の関数適用と同等です。

```text
((((("" <> show 1) <> show 2) <> show 3) <> show 4) <> show 5)
```

それに対し、右畳み込みは以下と等価です。

```text
((((("" <> show 5) <> show 4) <> show 3) <> show 2) <> show 1)
```

## 末尾再帰

再帰はアルゴリズムを指定する強力な手法ですが、問題も抱えています。
JavaScriptで再帰関数を評価するとき、入力が大き過ぎるとスタックオーバーフローでエラーを起こす可能性があるのです。

PSCiで次のコードを入力すると、この問題を簡単に検証できます。

```text
> :paste
… f n =
…   if n == 0
…     then 0
…     else 1 + f (n - 1)
… ^D

> f 10
10

> f 100000
RangeError: Maximum call stack size exceeded
```

これは問題です。
関数型プログラミングの標準的な手法として再帰を採用しようとするなら、境界がない再帰がありうるときでも扱える方法が必要です。

PureScriptは*末尾再帰最適化*の形でこの問題に対する部分的な解決策を提供しています。

> *補足*：この問題へのより完全な解決策としては、いわゆる*トランポリン*を使用するライブラリで実装できますが、それはこの章で扱う範囲を超えています。
> 興味のある読者は[`free`](https://pursuit.purescript.org/packages/purescript-free)や[`tailrec`](https://pursuit.purescript.org/packages/purescript-tailrec)パッケージのドキュメントをあたると良いでしょう。

末尾再帰最適化を可能にする上で鍵となる観点は以下となります。
*末尾位置*にある関数の再帰的な呼び出しは*ジャンプ*に置き換えられます。
このジャンプではスタックフレームが確保されません。
関数が戻るより前の最後の呼び出しであるとき、呼び出しが*末尾位置*にあるといいます。
先の例でスタックオーバーフローが見られたのはこれが理由です。
`f`の再帰呼び出しが末尾位置*でなかった*からです。

実際には、PureScriptコンパイラは再帰呼び出しをジャンプに置き換えるのではなく、再帰的な関数全体を _whileループ_ に置き換えます。

以下は全ての再帰呼び出しが末尾位置にある再帰関数の例です。

```haskell
{{#include ../exercises/chapter5/test/Examples.purs:factorialTailRec}}
```

`factorialTailRec`への再帰呼び出しがこの関数の最後にある点に注目してください。
つまり末尾位置にあるのです。

## 累算器

末尾再帰ではない関数を末尾再帰関数に変える一般的な方法は、*累算器引数*を使用することです。
累算器引数は関数に追加される余剰の引数で、返り値を*累算*するものです。
これは結果を累算するために返り値を使うのとは対照的です。

例えば章の初めに示した`length`関数を再考しましょう。

```haskell
{{#include ../exercises/chapter5/test/Examples.purs:length}}
```

この実装は末尾再帰ではないので、大きな入力配列に対して実行されると、生成されたJavaScriptはスタックオーバーフローを発生させるでしょう。
しかし代わりに、結果を蓄積するための2つ目の引数を関数に導入することで、これを末尾再帰に変えることができます。

```haskell
{{#include ../exercises/chapter5/test/Examples.purs:lengthTailRec}}
```

ここでは補助関数`length'`に委譲しています。
この関数は末尾再帰です。
その唯一の再帰呼び出しは、最後の場合の末尾位置にあります。
つまり、生成されるコードは*whileループ*となり、大きな入力でもスタックが溢れません。

`lengthTailRec`の実装を理解する上では、補助関数`length'`が基本的に累算器引数を使って追加の状態を保持していることに注目してください。
追加の状態とは、部分的な結果です。
0から始まり、入力の配列中の全ての各要素について1ずつ足されて大きくなっていきます。

なお、累算器を「状態」と考えることもできますが、直接には変更されていません。

## 明示的な再帰より畳み込みを選ぼう

末尾再帰を使用して再帰関数を記述できれば末尾再帰最適化の恩恵を受けられるので、全ての関数をこの形で書こうとする誘惑に駆られます。
しかし、多くの関数は配列やそれに似たデータ構造に対する折り畳みとして直接書くことができることを忘れがちです。
`map`や`fold`のような組み合わせの部品を使って直接アルゴリズムを書くことには、コードの単純さという利点があります。
これらの部品はよく知られており、だからこそ明示的な再帰よりもアルゴリズムの*意図*がより良く伝わるのです。

例えば`foldr`を使って配列を反転できます。

```text
> import Data.Foldable

> :paste
… reverse :: forall a. Array a -> Array a
… reverse = foldr (\x xs -> xs <> [x]) []
… ^D

> reverse [1, 2, 3]
[3,2,1]
```

`foldl`を使って`reverse`を書くことは、読者への課題として残しておきます。

## 演習

 1. （簡単）`foldl`を使って真偽値配列の値が全て真か検査する関数`allTrue`を書いてください。
 2. （普通。テストなし）関数`foldl (==) false xs`が真を返すような配列`xs`とはどのようなものか説明してください。
    言い換えると、「関数は`xs`が……を含むときに`true`を返す」という文を完成させることになります。
 3. （普通）末尾再帰の形式を取っていること以外は`fib`と同じような関数`fibTailRec`を書いてください。
    *手掛かり*：累算器引数を使ってください。
 4. （普通）`foldl`を使って`reverse`を書いてみましょう。

## 仮想ファイルシステム

この節ではこれまで学んだことを応用してファイルシステムのモデルを扱う関数を書きます。
事前に定義されたAPIを扱う上でマップ、畳み込み、及びフィルタを使用します。

`Data.Path`モジュールでは、次のように仮想ファイルシステムのAPIが定義されています。

- ファイルシステム内のパスを表す型`Path`があります。
- ルートディレクトリを表すパス`root`があります。
- `ls`関数はディレクトリ内のファイルを列挙します。
- `filename`関数は`Path`のファイル名を返します。
- `size`関数はファイルを表す`Path`のファイルの大きさを返します。
- `isDirectory`関数はファイルかディレクトリかを調べます。

型について言うと、次のような型定義があります。

```haskell
root :: Path

ls :: Path -> Array Path

filename :: Path -> String

size :: Path -> Maybe Int

isDirectory :: Path -> Boolean
```

PSCiでこのAPIを試してみましょう。

```text
$ spago repl

> import Data.Path

> root
/

> isDirectory root
true

> ls root
[/bin/,/etc/,/home/]
```

`Test.Examples`モジュールでは`Data.Path` APIを使用する関数を定義しています。
`Data.Path`モジュールを変更したり定義を理解したりする必要はありません。
全て`Test.Examples`モジュールだけで作業します。

## 全てのファイルの一覧

それでは、ディレクトリの中身を含めた全てのファイルを深く列挙する関数を書いてみましょう。
この関数は以下のような型を持つでしょう。

```haskell
{{#include ../exercises/chapter5/test/Examples.purs:allFiles_signature}}
```

再帰を使ってこの関数を定義できます。
`ls`を使うとディレクトリ直下の子が列挙されます。
それぞれの子について再帰的に`allFiles`を適用すると、それぞれパスの配列が返ります。
`concatMap`を使うと、`allFiles`を適用して平坦化するまでを一度にできます。

最後に、cons演算子`:`を使って現在のファイルも含めます。

```haskell
{{#include ../exercises/chapter5/test/Examples.purs:allFiles_implementation}}
```

> *補足*：実はcons演算子`:`は、不変な配列に対して効率性が悪いので、一般的には推奨されません。
> 連結リストやシーケンスなどの他のデータ構造を使用すると、効率性を向上させられます。

それではPSCiでこの関数を試してみましょう。

```text
> import Test.Examples
> import Data.Path

> allFiles root

[/,/bin/,/bin/cp,/bin/ls,/bin/mv,/etc/,/etc/hosts, ...]
```

すばらしいです。
do記法で配列内包表記を使ってもこの関数を書くことができるので見ていきましょう。

逆向きの矢印は配列から要素を選択するのに相当することを思い出してください。
最初の工程は引数の直接の子から要素を選択することです。
それからそのファイルに対して再帰関数を呼び出します。
do記法を使用しているので`concatMap`が暗黙に呼び出されています。
この関数は再帰的な結果を全て連結します。

新しいバージョンは次のようになります。

```haskell
{{#include ../exercises/chapter5/test/Examples.purs:allFiles_2}}
```

PSCiで新しいコードを試してみてください。
同じ結果が返ってくるはずです。
どちらのほうがわかりやすいかの選定はお任せします。

## 演習

 1. （簡単）ディレクトリの全てのサブディレクトリの中にある（ディレクトリを除く）全てのファイルを返すような関数`onlyFiles`を書いてみてください。
 2. （普通）ファイルを名前で検索する関数`whereIs`を書いてください。
    この関数は型`Maybe Path`の値を返すものとします。
    この値が存在するなら、そのファイルがそのディレクトリに含まれているということを表します。
    この関数は次のように振る舞う必要があります。

     ```text
     > whereIs root "ls"
     Just (/bin/)

     > whereIs root "cat"
     Nothing
     ```

     *手掛かり*：do記法を使う配列内包表記で、この関数を書いてみましょう。
 3. （難しい）関数`largestSmallest`を書いてください。
    `Path`を1つ取り、その`Path`中の最大のファイルと最小のファイルが1つずつ含まれる配列を返します。
    *補足*：
    `Path`のファイル数がゼロや1個の場合も考慮してください。
    それぞれ、空配列や1要素の配列を返すとよいでしょう。

## まとめ

この章ではアルゴリズムを簡潔に表現するためにPureScriptでの再帰の基本を押さえました。
また、独自の中置演算子や、マップ、絞り込みや畳み込みなどの配列に対する標準関数、及びこれらの概念を組み合わせた配列内包表記を導入しました。
最後に、スタックオーバーフローエラーを回避するために末尾再帰を使用することの重要性、累算器引数を使用して末尾再帰形に関数を変換する方法を示しました。
