# 作用モナド

## この章の目標

前章では、オプショナルな型やエラーメッセージ、
データの検証など、**副作用**を扱いを抽象化するアプリカティブ関手を導入しました。
この章では、より表現力の高い方法で副作用を扱うための別の抽象化、**モナド**を導入します。

この章の目的は、なぜモナドが便利な抽象化なのかということと、
**do記法**との関係を説明することです。

## プロジェクトの準備

このプロジェクトでは、以下の依存関係が追加されています。

- `effect`: 章の後半の主題である`Effect`モナドを定義しています。この依存
  関係はあらゆるプロジェクトの始めに掲げられることがよくあるので（これま
  での全ての章でも依存関係にありました）、明示的にインストールしなければ
  いけないことは稀です。
- `react-basic-hooks`: アドレス帳アプリに使うWebフレームワークです。

## モナドとdo記法

do記法は**配列内包表記**を扱うときに最初に導入されました。配列内包表記は `Data.Array`モジュールの
`concatMap`関数の構文糖として提供されています。

次の例を考えてみましょう。２つのサイコロを振って出た目を数え、出た目の合計が
`n`のときそれを得点とすることを考えます。次のような非決定的なアルゴリズムを使うとこれを実現することができます。

- 最初の投擲で値 `x`を**選択**します。
- 2回目の投擲で値 `y`を**選択**します。
- もし `x`と `y`の和が `n`なら組 `[x, y]`を返し、そうでなければ失敗しま
  す。

配列内包表記を使うと、この非決定的アルゴリズムを自然に書くことができます。

```hs
import Prelude

import Control.Plus (empty)
import Data.Array ((..))

{{#include ../exercises/chapter8/test/Examples.purs:countThrows}}
```

PSCiでこの関数の動作を見てみましょう。

```text
> import Test.Examples

> countThrows 10
[[4,6],[5,5],[6,4]]

> countThrows 12
[[6,6]]
```

前の章では、**オプショナルな値**に対応したより大きなプログラミング言語へと
PureScriptの関数を埋め込む、
`Maybe` アプリカティブ関手についての直感的理解を養いました。
同様に**配列モナド**についても、
**非決定選択**に対応したより大きなプログラミング言語へ
PureScriptの関数を埋め込む、というような直感的理解を得ることができます。

一般に、ある型構築子 `m`のモナドは、
型 `m a`の値を持つdo記法を使う方法を提供します。
上の配列内包表記では、
すべての行に何らかの型 `a`についての型 `Array a`の計算が
含まれていることに注目してください。
一般に、do記法ブロックのすべての行は、
何らかの型 `a`とモナド `m`について、型 `m a`の計算を含んでいます。
モナド `m`はすべての行で同じでなければなりません
（つまり、副作用の種類は固定されます）が、
型 `a`は異なることもあります。
（言い換えると、個々の計算は異なる型の結果を持つことができます。）

型構築子 `Maybe`が適用された、do記法の別の例を見てみましょう。
XMLノードを表す型 `XML`と次の関数があるとします。

```hs
child :: XML -> String -> Maybe XML
```

この関数はノードの子の要素を探し、
もしそのような要素が存在しなければ `Nothing`を返します。

この場合、do記法を使うと深い入れ子になった要素を検索することができます。XML文書として符号化された利用者情報から、利用者の住んでいる市町村を読み取りたいとします。

```hs
userCity :: XML -> Maybe XML
userCity root = do
  prof <- child root "profile"
  addr <- child prof "address"
  city <- child addr "city"
  pure city
```

`userCity`関数は子の要素である `profile`を探し、 `profile`要素の中にある `address`要素、最後に
`address`要素から `city`要素を探します。これらの要素のいずれかが欠落している場合は、返り値は
`Nothing`になります。そうでなければ、返り値は `city`ノードから `Just`を使って構築されています。

最後の行にある`pure`関数は、すべての`Applicative`関手について定義されているのでした。`Maybe`の`Applicative`関手の`pure`関数は`Just`として定義されており、最後の行を
`Just city`へ変更しても同じように正しく動きます。

## モナド型クラス

`Monad`型クラスは次のように定義されています。

```hs
class Apply m <= Bind m where
  bind :: forall a b. m a -> (a -> m b) -> m b

class (Applicative m, Bind m) <= Monad m
```

ここで鍵となる関数は `Bind`型クラスで定義されている演算子 `bind`で、
`Functor`及び `Apply`型クラスにある `<$>`や `<*>`などの演算子と同じ様に
`Prelude`では `>>=`として `bind`の中置の別名が定義されています。

`Monad`型クラスは、すでに見てきた `Applicative`型クラスの操作で `Bind`を拡張します。

`Bind`型クラスの例をいくつか見てみるのがわかりやすいでしょう。配列についての `Bind`の妥当な定義は次のようになります。

```hs
instance bindArray :: Bind Array where
  bind xs f = concatMap f xs
```

これは以前にほのめかした配列内包表記と `concatMap`関数の関係を説明しています。

`Maybe`型構築子についての `Bind`の実装は次のようになります。

```hs
instance bindMaybe :: Bind Maybe where
  bind Nothing  _ = Nothing
  bind (Just a) f = f a
```

この定義は欠落した値がdo記法ブロックを通じて伝播するという直感的理解を裏付けるものです。

`Bind`型クラスとdo記法がどのように関係しているかを見て行きましょう。最初に何らかの計算結果からの値の束縛から始まる簡単なdo記法ブロックについて考えてみましょう。

```hs
do value <- someComputation
   whatToDoNext
```

PureScriptコンパイラはこのようなパターンを見つけるたびにコードを次にように置き換えます。

```hs
bind someComputation \value -> whatToDoNext
```

あるいは中置で書くと以下です。

```hs
someComputation >>= \value -> whatToDoNext
```

この計算 `whatToDoNext`は `value`に依存することができます。

複数の束縛が関係している場合、この規則は先頭のほうから複数回適用されます。例えば、先ほど見た `userCity`の例では次のように脱糖されます。

```hs
userCity :: XML -> Maybe XML
userCity root =
  child root "profile" >>= \prof ->
    child prof "address" >>= \addr ->
      child addr "city" >>= \city ->
        pure city
```

do記法を使って表現されたコードは、
`>>=`演算子を使って書かれた同じ意味のコードよりしばしば読みやすくなることも特筆すべき点です。
一方で、明示的に `>>=`を使って束縛が書くと、
よく**ポイントフリー**形式でコードが書けるようになります。
ただし、読みやすさにはやはり注意がいります。

## モナド則

`Monad`型クラスは**モナド則** (monad laws) と呼ばれる3つの規則を持っています。
これらは `Monad`型クラスの理にかなった実装から何を期待できるかを教えてくれます。

do記法を使用してこれらの規則を説明していくのが最も簡単でしょう。

### 単位元律

**右単位元則** (right-identity law) が3つの規則の中で最も簡単です。
この規則はdo記法ブロックの最後の式であれば、
`pure`の呼び出しを排除することができると言っています。

```hs
do
  x <- expr
  pure x
```

右単位元則は、この式は単なる `expr`と同じだと言っています。

**左単位元則** (left-identity law) は、もしそれがdo記法ブロックの最初の式であれば、
`pure`の呼び出しを除去することができると述べています。

```hs
do
  x <- pure y
  next
```

このコードは、名前`x`を式`y`で置き換えた`next`と同じです。

最後の規則は**結合則** (associativity law) です。
これは入れ子になったdo記法ブロックをどう扱うのかについて教えてくれます。
この規則が述べているのは以下のコード片のことです。

```hs
c1 = do
  y <- do
    x <- m1
    m2
  m3
```

上記のコード片は、次のコードと同じです。

```hs
c2 = do
  x <- m1
  y <- m2
  m3
```

これら計算にはそれぞれ、3つのモナドの式 `m1`、 `m2`、 `m3`が含まれています。どちらの場合でも `m1`の結果は名前 `x`に束縛され、
`m2`の結果は名前 `y`に束縛されます。

`c1`では2つの式 `m1`と `m2`がそれぞれのdo記法ブロック内にグループ化されています。

`c2`では `m1`、 `m2`、 `m3`の3つすべての式が同じdo記法ブロックに現れています。

結合規則は入れ子になったdo記法ブロックをこのように単純化しても
問題ないことを言っています。

**注意**: do記法を`bind`の呼び出しへと脱糖する定義により、 `c1`と `c2`はいずれも次のコードと同じです。

```hs
c3 = do
  x <- m1
  do
    y <- m2
    m3
```

## モナドで畳み込む

抽象的にモナドを扱う例として、
この節では `Monad`型クラスの何らかの型構築子に機能するある関数を示していきます。
これはモナドによるコードが副作用を伴う「より大きな言語」でのプログラミングと対応しているという直感的理解を補強しますし、モナドによるプログラミングがもたらす一般性も示しています。

これから `foldM`と呼ばれる関数を書いてみます。これは以前扱った
`foldl`関数をモナドの文脈へと一般化します。型シグネチャは次のようになっています。

```hs
foldM :: forall m a b. Monad m => (a -> b -> m a) -> a -> List b -> m a
foldl :: forall   a b.            (a -> b ->   a) -> a -> List b ->   a
```

モナド `m`が現れている点を除いて、 `foldl`の型と同じであることに注意しましょう。

直感的には、 `foldM`はさまざまな副作用の組み合わせに対応した文脈での配列の畳み込みを行うと捉えることができます。

例として `m`が `Maybe`であるとすると、この畳み込みはそれぞれの段階で
`Nothing`を返すことで失敗することができます。それぞれの段階ではオプショナルな結果を返しますから、それゆえ畳み込みの結果もオプショナルになります。

もし `m`として配列の型構築子
`Array`を選ぶとすると、畳み込みのそれぞれの段階で複数の結果を返すことができ、畳み込みは結果それぞれに対して次の手順を継続します。最後に、結果の集まりは、可能な経路すべての畳み込みから構成されることになります。これはグラフの走査と対応しています！

`foldM`を書くには、単に入力のリストについて場合分けをするだけです。

リストが空なら、型 `a`の結果を生成するための選択肢はひとつしかありません。
第2引数を返します。

```hs
foldM _ a Nil = pure a
```

なお`a`をモナド `m`まで持ち上げるために `pure`を使わなくてはいけません。

リストが空でない場合はどうでしょうか？
その場合、型 `a`の値、型 `b`の値、型 `a -> b -> m a`の関数があります。
もしこの関数を適用すると、型 `m a`のモナドの結果を手に入れることになります。
この計算の結果を逆向きの矢印 `<-`で束縛することができます。

あとはリストの残りに対して再帰するだけです。実装は簡単です。

```hs
foldM f a (b : bs) = do
  a' <- f a b
  foldM f a' bs
```

なお、do記法を除けば、この実装は配列に対する `foldl`の実装とほとんど同じです。

PSCiでこれを定義し、試してみましょう。
以下では例として、除算可能かどうかを調べて、失敗を示すために `Maybe`型構築子を使う、
整数の「安全な除算」関数を定義するとしましょう。

```hs
{{#include ../exercises/chapter8/test/Examples.purs:safeDivide}}
```

これで、 `foldM`で安全な除算の繰り返しを表現することができます。

```text
> import Test.Examples
> import Data.List (fromFoldable)

> foldM safeDivide 100 (fromFoldable [5, 2, 2])
(Just 5)

> foldM safeDivide 100 (fromFoldable [2, 0, 4])
Nothing
```

もしいずれかの時点で整数にならない除算が行われようとしたら、
`foldM safeDivide`関数は `Nothing`を返します。
そうでなければ、除算を繰り返した累積の結果を`Just`構築子に包んで返します。

## モナドとアプリカティブ

クラス間に上位クラス関係の効能があるため、
`Monad`型クラスのすべてのインスタンスは `Apply`型クラスのインスタンスでもあります。

しかしながら、あらゆる`Monad`のインスタンスに
「無料で」ついてくる`Apply`型クラスの実装もあります。
これは`ap`関数により与えられます。

```hs
ap :: forall m a b. Monad m => m (a -> b) -> m a -> m b
ap mf ma = do
  f <- mf
  a <- ma
  pure (f a)
```

もし `m`が `Monad`型クラスに固執していれば、
`ap`で与えられる`m`について妥当な `Apply`インスタンスが存在します。

興味のある読者は、これまで登場した `Array`、 `Maybe`、 `Either e`といったモナドについて、この `ap`が
`apply`と一致することを確かめてみてください。

もしすべてのモナドがアプリカティブ関手でもあるなら、
アプリカティブ関手についての直感的理解を
すべてのモナドについても適用することができるはずです。
特に、モナドが更なる副作用の組み合わせで増強された「より大きな言語」での
プログラミングといろいろな意味で一致することを予想するのはもっともです。
`map`と `apply`を使って、
引数が任意個の関数をこの新しい言語へと持ち上げることができるはずです。

しかし、モナドはアプリカティブ関手でできること以上を行うことができ、
重要な違いはdo記法の構文で強調されています。
利用者情報を符号化したXML文書から利用者の都市を検索する、
`userCity`の例についてもう一度考えてみましょう。

```hs
userCity :: XML -> Maybe XML
userCity root = do
  prof <- child root "profile"
  addr <- child prof "address"
  city <- child addr "city"
  pure city
```

do記法では2番目の計算が最初の結果 `prof`に依存し、
3番目の計算が2番目の計算の結果
`addr`に依存するというようなことができます。
`Applicative`型クラスのインターフェイスだけを使うのでは、
このような以前の値への依存は不可能です。

`pure`と `apply`だけを使って `userCity`を書こうとしてみれば、
これが不可能であることがわかるでしょう。
アプリカティブ関手ができるのは関数の互いに独立した引数を持ち上げることだけですが、
モナドはもっと興味深いデータ依存関係に関わる計算を書くことを可能にします。

前の章では `Applicative`型クラスは並列処理を表現できることを見ました。
持ち上げられた関数の引数は互いに独立していますから、
これはまさにその通りです。
`Monad`型クラスは計算が前の計算の結果に依存できるようにしますから、
同じようにはなりません。
モナドは副作用を順番に組み合わせなければいけません。

## 演習

 1. （簡単）3つ以上の要素がある配列の3つ目の要素を返す関数`third`を書いてください。
    関数は適切な`Maybe`型で返します。
    **ヒント**：`arrays`パッケージの`Data.Array`モジュールから`head`と`tail`関数の型を見つけ出してください。
    これらの関数を繋げるには`Maybe`モナドと共にdo記法を使ってください。
 1. （普通）一掴みの硬貨を使ってできる可能なすべての合計を決定する関数 `possibleSums`を、
    `foldM`を使って書いてみましょう。入力の硬貨は、硬貨の価値の配列として与えられます。この関数は次のような結果にならなくてはいけません。

     ```text
     > possibleSums []
     [0]

     > possibleSums [1, 2, 10]
     [0,1,2,3,10,11,12,13]
     ```

     **ヒント**：`foldM`を使うと1行でこの関数を書くことが可能です。
     重複を取り除いたり、結果を並び替えたりするのに、
     `nub`関数や `sort`関数を使いたくなるかもしれません。
1. （普通）`Maybe`型構築子について、 `ap`関数と `apply`演算子が一致することを確認してください。
   **補足**：この演習にはテストがありません。
1. （普通）`maybe`パッケージで定義されている
   `Maybe`型についての `Monad`インスタンスが、
   モナド則を満たしていることを検証してください。
   **補足**：この演習にはテストがありません。
1. （普通）配列上の `filter`の関数を一般化した関数 `filterM`を書いてください。
   この関数は次の型シグネチャを持ちます。

     ```hs
     filterM :: forall m a. Monad m => (a -> m Boolean) -> List a -> m (List a)
     ```

 1. （難しい） すべてのモナドには
    次で与えられるような既定の `Functor`インスタンスがあります。

     ```hs
     map f a = do
       x <- a
       pure (f x)
     ```

     モナド則を使って、すべてのモナドが次を満たすことを証明してください。

     ```hs
     lift2 f (pure a) (pure b) = pure (f a b)
     ```

     ここで、 `Applly`インスタンスは上で定義された `ap`関数を使用しています。
     `lift2`が次のように定義されていたことを思い出してください。

     ```hs
     lift2 :: forall f a b c. Apply f => (a -> b -> c) -> f a -> f b -> f c
     lift2 f a b = f <$> a <*> b
     ```

    **補足**：この演習にはテストがありません。

## ネイティブな作用

ここではPureScriptの中核となる重要なモナド、 `Effect`モナドについて見ていきます。

`Effect`モナドは `Effect`モジュールで定義されています。
かつてはいわゆる**ネイティブ**副作用を管理していました。
Haskellに馴染みがあれば、これは`IO`モナドと同等のものです。

ネイティブな副作用とは何でしょうか。
この副作用はPureScript特有の式からJavaScriptの式を区別するものです。
PureScriptの式は概して副作用とは無縁なのです。
ネイティブな作用の例を以下に示します。

- コンソール入出力
- 乱数生成
- 例外
- 変更可能な状態の読み書き

また、ブラウザでは次のようなものがあります。

- DOM操作
- XMLHttpRequest / AJAX呼び出し
- WebSocketによる相互作用
- Local Storageの読み書き

すでに「ネイティブでない」副作用の例については数多く見てきています。

- `Maybe`データ型で表現される省略可能な値
- `Either`データ型で表現されるエラー
- 配列やリストで表現される多価関数

これらの区別はわかりにくいので注意してください。エラーメッセージは例外の形でJavaScriptの式の副作用となることがあります。その意味では例外はネイティブな副作用を表していて、
`Effect`を使用して表現することができます。しかし、
`Either`を使用して実装されたエラーメッセージはJavaScriptランタイムの副作用ではなく、
`Effect`を使うスタイルでエラーメッセージを実装するのは適切ではありません。そのため、ネイティブなのは作用自体というより、実行時にどのように実装されているかです。

## 副作用と純粋性

PureScriptのような言語が純粋であるとすると、疑問が浮かんできます。副作用がないなら、どうやって役に立つ実際のコードを書くことができるというのでしょうか。

その答えはPureScriptの目的は副作用を排除することではないということです。これは、純粋な計算と副作用のある計算とを型システムにおいて区別することができるような方法で、副作用を表現することを目的としているのです。この意味で、言語はあくまで純粋だということです。

副作用のある値は、純粋な値とは異なる型を持っています。
このように、例えば副作用のある引数を関数に渡すことはできず、
予期せず副作用を持つようなことが起こらなくなります。

`Effect`モナドで管理された副作用を実行する唯一の方法は、
型 `Effect a`の計算をJavaScriptから実行することです。

Spagoビルドツール（や他のツール）は早道を提供しており、
アプリケーションの起動時に`main`計算を呼び出すための追加のJavaScriptコードを生成します。
`main`は `Effect`モナドでの計算であることが要求されます。

## 作用モナド

`Effect`は副作用のある計算を充分に型付けするAPIを提供すると同時に、
効率的なJavaScriptを生成します。

馴染みのある`log`関数から返る型をもう少し見てみましょう。
`Effect`はこの関数がネイティブな作用を生み出すことを示しており、
この場合はコンソールIOです。
`Unit`はいかなる*意味のある*データも返らないことを示しています。
`Unit`はC、Javaなど他の言語での`void`キーワードと似たようなものとして考えられます。

```hs
log :: String -> Effect Unit
```

> 余談：より一般的な（そしてより込み入った型の）`Effect.Class.Console`の`log`関数をIDEから提案されるかもしれません。
これは基本的な`Effect`モナドを扱う際は`Effect.Console`からの関数と交換可能です。
より一般的なバージョンがあることの理由は「モナドな冒険」章の「モナド変換子」について読んだあとにより明らかになっていることでしょう。
好奇心のある（そしてせっかちな）読者のために言うと、
これは`Effect`に`MonadEffect`インスタンスがあるから機能するのです。

> ```hs
> log :: forall m. MonadEffect m => String -> m Unit
> ```

それでは意味のあるデータを返す`Effect`を考えましょう。
`Effect.Random`の`random`関数はランダムな`Number`を生み出します。

```hs
random :: Effect Number
```

以下は完全なプログラムの例です。
（この章の演習フォルダの`test/Random.purs`にあります。）

```hs
{{#include ../exercises/chapter8/test/Random.purs}}
```

`Effect`はモナドなので、do記法を使って含まれるデータを開封し、
それからこのデータを作用のある`logShow`関数に渡します。
気分転換に、以下は`bind`演算子を使って書かれた同等なコードです。

```hs
main :: Effect Unit
main = random >>= logShow
```

これを手元で走らせてみてください。

```
spago run --main Test.Random
```

コンソールに出力 `0.0`と `1.0`の間で無作為に選ばれた数が表示されるでしょう。

> 余談：`spago run`は既定で`Main`モジュールとその中の`main`関数を探索します。
`--main`フラグで代替のモジュールを入口として指定することもでき、
上の例ではそうしています。
この代替のモジュールもまた`main`関数を含んでいることには注目してください。

なお「ランダムな」（技術的には疑似ランダムな）データを不浄な作用付きのコードに訴えることなく生成することも可能です。
この技法は「テストを生成する」章で押さえます。

以前言及したように`Effect`モナドはPureScriptで核心的な重要さがあります。
なぜ核心かというと、それはPureScriptの`外部関数インターフェース`とやりとりする上での常套手段だからです。
`外部関数インターフェース`はプログラムを実行したり副作用を発生させたりする仕組みを提供します。
`外部関数インターフェース`を使うことは避けるのが望ましいのですが、
どう動きどう使うのか理解することもまた極めて大事なことですので、
実際にPureScriptで何か動かす前にその章を読まれることをお勧めします。
要は`Effect`モナドは結構単純なのです。
いくつかのお助け関数がありますが、それを差し置いても副作用を内包すること以外には多くのことをしません。

## 例外

2つの**ネイティブな**副作用が絡む`node-fs`パッケージの関数を調べましょう。
ここでの副作用は可変状態の読み取りと例外です。

```hs
readTextFile :: Encoding -> String -> Effect String
```

もし存在しないファイルを読むことを試みると……

```hs
import Node.Encoding (Encoding(..))
import Node.FS.Sync (readTextFile)

main :: Effect Unit
main = do
  lines <- readTextFile UTF8 "iDoNotExist.md"
  log lines
```

以下の例外に遭遇します。

```
    throw err;
    ^
Error: ENOENT: no such file or directory, open 'iDoNotExist.md'
...
  errno: -2,
  syscall: 'open',
  code: 'ENOENT',
  path: 'iDoNotExist.md'
```

この例外をうまく管理するには、
潜在的に問題があるコードを`try`に包めばいずれの出力も制御できます。

```hs
main :: Effect Unit
main = do
  result <- try $ readTextFile UTF8 "iDoNotExist.md"
  case result of
    Right lines -> log $ "Contents: \n" <> lines
    Left  error -> log $ "Couldn't open file. Error was: " <> message error
```

`try`は`Effect`を走らせて起こりうる例外を`Left`値として返します。
もし計算が成功すれば結果は`Right`に包まれます。

```hs
try :: forall a. Effect a -> Effect (Either Error a)
```

自前の例外を生成することもできます。
以下は`Data.List.head`の代替実装で、
`Maybe`の値の`Nothing`を返す代わりにリストが空のとき例外を投げます。

```hs
exceptionHead :: List Int -> Effect Int
exceptionHead l = case l of
  x : _ -> pure x
  Nil -> throwException $ error "empty list"
```

ただし`exceptionHead`関数はどこかしら非実用的な例です。
というのも、PureScriptのコードで例外を生成するのは避け、
代わりに`Either`や`Maybe`のようなネイティブでない作用で
エラーや欠けた値を使うのが一番だからです。

## 可変状態

中核ライブラリには `ST`作用というまた別の作用も定義されています。

`ST`作用は変更可能な状態を操作するために使われます。純粋関数プログラミングを知っているなら、共有される変更可能な状態は問題を引き起こしやすいということも知っているでしょう。しかしながら、
`ST`作用は型システムを使って安全で**局所的な**状態変化を可能にし、状態の共有を制限するのです。

`ST`作用は
`Control.Monad.ST`モジュールで定義されています。これがどのように動作するかを確認するには、そのアクションの型を見る必要があります。

```hs
new :: forall a r. a -> ST r (STRef r a)

read :: forall a r. STRef r a -> ST r a

write :: forall a r. a -> STRef r a -> ST r a

modify :: forall r a. (a -> a) -> STRef r a -> ST r a
```

`new`は型 `STRef r a`の変更可能な参照区画を新しく作るのに使われます。
`STRef r a`は `read`アクションを使って状態を読み取ったり、
`write`アクションや `modify`アクションで状態を変更するのに使われます。
型 `a`は区画に格納された値の型で、
型 `r`は型システムで**メモリ領域**（または**ヒープ**）を表しています。

例を示します。小さな時間刻みで簡単な更新関数の実行を何度も繰り返すことによって、重力に従って落下する粒子の落下の動きをシミュレートしたいとしましょう。

粒子の位置と速度を保持する変更可能な参照区画を作成し、
区画に格納された値を更新するのにforループを使うことでこれを実現することができます。

```hs
import Prelude

import Control.Monad.ST.Ref (modify, new, read)
import Control.Monad.ST (ST, for, run)

simulate :: forall r. Number -> Number -> Int -> ST r Number
simulate x0 v0 time = do
  ref <- new { x: x0, v: v0 }
  for 0 (time * 1000) \_ ->
    modify
      ( \o ->
          { v: o.v - 9.81 * 0.001
          , x: o.x + o.v * 0.001
          }
      )
      ref
  final <- read ref
  pure final.x
```

計算の最後では、参照区画の最終的な値を読み取り、粒子の位置を返しています。

この関数が変更可能な状態を使っていても、その参照区画
`ref`がプログラムの他の部分で使われるのが許されない限り、これは純粋な関数のままであることに注意してください。
`ST`作用が禁止するものが正確には何であるのかについては後ほど見ます。

`ST`作用付きの計算を実行するには、 `run`関数を使用する必要があります。

```hs
run :: forall a. (forall r. ST r a) -> a
```

ここで注目して欲しいのは、
領域型 `r`が関数矢印の左辺にある**括弧の内側で**量化されているということです。
`run`に渡したどんなアクションでも、
**任意の領域**`r`がなんであれ動作するということを意味しています。

しかしながら、
ひとたび参照区画が `new`によって作成されると、
その領域の型はすでに固定されており、
`run`によって限定されたコードの外側で参照領域を使おうとしても型エラーになるでしょう。
`run`が安全に `ST`作用を除去でき、`simulate`を純粋関数にできるのはこれが理由なのです！

```hs
simulate' :: Number -> Number -> Int -> Number
simulate' x0 v0 time = run (simulate x0 v0 time)
```

PSCiでもこの関数を実行してみることができます。

```text
> import Main

> simulate' 100.0 0.0 0
100.00

> simulate' 100.0 0.0 1
95.10

> simulate' 100.0 0.0 2
80.39

> simulate' 100.0 0.0 3
55.87

> simulate' 100.0 0.0 4
21.54
```

実は、もし `simulate`の定義を `run`の呼び出しのところへ埋め込むとすると、次のようになります。

```hs
simulate :: Number -> Number -> Int -> Number
simulate x0 v0 time =
  run do
    ref <- new { x: x0, v: v0 }
    for 0 (time * 1000) \_ ->
      modify
        ( \o ->
            { v: o.v - 9.81 * 0.001
            , x: o.x + o.v * 0.001
            }
        )
        ref
    final <- read ref
    pure final.x
```

参照区画はそのスコープから逃れることができないことがコンパイラにわかりますし、
安全に`ref`を`var`に変換することができます。
`run`が埋め込まれた`simulate`に対して生成されたJavaScriptは次のようになります。

```javascript
var simulate = function (x0) {
  return function (v0) {
    return function (time) {
      return (function __do() {

        var ref = { value: { x: x0, v: v0 } };

        Control_Monad_ST_Internal["for"](0)(time * 1000 | 0)(function (v) {
          return Control_Monad_ST_Internal.modify(function (o) {
            return {
              v: o.v - 9.81 * 1.0e-3,
              x: o.x + o.v * 1.0e-3
            };
          })(ref);
        })();

        return ref.value.x;

      })();
    };
  };
};
```

なおこの結果として得られたJavaScriptは最適化の余地があります。
詳細は[この課題](https://github.com/purescript-contrib/purescript-book/issues/121)を参照してください。
上記の抜粋はその課題が解決されたら更新されるでしょう。

比較としてこちらが埋め込まれていない形式で生成されたJavaScriptです。

```js
var simulate = function (x0) {
  return function (v0) {
    return function (time) {
      return function __do() {

        var ref = Control_Monad_ST_Internal["new"]({ x: x0, v: v0 })();

        Control_Monad_ST_Internal["for"](0)(time * 1000 | 0)(function (v) {
          return Control_Monad_ST_Internal.modify(function (o) {
            return {
              v: o.v - 9.81 * 1.0e-3,
              x: o.x + o.v * 1.0e-3
            };
          })(ref);
        })();

        var $$final = Control_Monad_ST_Internal.read(ref)();
        return $$final.x;
      };
    };
  };
};
```

局所的な変更可能状態を扱うとき、
特に作用が絡むループを生成する
`for`、 `foreach`、 `while`のようなアクションを一緒に使うときには、
`ST`作用は短いJavaScriptを生成する良い方法となります。

## 演習

1. （普通）`safeDivide`関数を書き直し、
   もし分母がゼロなら`throwException`を使って文言`"div zero"`の例外を投げるようにしたものを
   `exceptionDivide`としてください。
1. （普通）関数`estimatePi :: Int -> Number`を書いてください。
   この関数は`n`項[Gregory
   Series](https://mathworld.wolfram.com/GregorySeries.html)を使って`pi`の近似を計算するものです。
   **ヒント**：解答は上記の`simulate`の定義に倣うことができます。
   また`Data.Int`の`toNumber :: Int -> Number`を使って、
   `Int`を`Number`に変換する必要があるかもしれません。
1. （普通）`n`番目のフィボナッチ数を計算する関数`fibonacci :: Int -> Int`を書いてください。
   `ST`を使って前の2つのフィボナッチ数の値を追跡します。
   新しい`ST`に基づく実装の速度を第4章の再帰実装に対して比較してください。

## DOM作用

この章の最後の節では、
`Effect`モナドでの作用についてこれまで学んだことを、
実際のDOM操作の問題に応用します。

DOMを直接扱ったり、
オープンソースのDOMライブラリを扱ったりする
PureScriptパッケージが沢山あります。
例えば以下です。

- [`web-dom`](https://github.com/purescript-web/purescript-web-dom)はW3C
  のDOM規格に向けた型定義と低水準インターフェース実装を提供します。
- [`web-html`](https://github.com/purescript-web/purescript-web-html)は
  W3CのHTML5規格に向けた型定義と低水準インターフェース実装を提供します。
- [`jquery`](http://github.com/paf31/purescript-jquery)は
  [jQuery](http://jquery.org)ライブラリのバインディングの集まりです。

上記のライブラリを抽象化するPureScriptライブラリもあります。
以下のようなものです。

- <a
  href="http://github.com/paf31/purescript-thermite"><code>thermite</code></a>
  は<a
  href="https://github.com/purescript-contrib/purescript-react"><code>react</code></a>
  上で構築されるライブラリです。
- <a
  href="https://github.com/megamaddu/purescript-react-basic-hooks"><code>react-basic-hooks</code></a>
  は<a
  href="https://github.com/lumihq/purescript-react-basic"><code>react-basic</code></a>
  上で構築されるライブラリです。
- <a
  href="http://github.com/purescript-halogen/purescript-halogen"><code>halogen</code></a>
  は自前の仮想DOMライブラリを土台とした型安全な抽象化の集まりを提供しま
  す。

この章では `react-basic-hooks`ライブラリを使用し、
住所簿アプリケーションにユーザーインターフェイスを追加しますが、
興味のあるユーザは異なるアプローチで進めることをおすすめします。

## 住所録のユーザーインタフェース

`react-basic-hooks`ライブラリを使い、
アプリケーションをReact**コンポーネント**として定義していきます。
ReactコンポーネントはHTML要素を純粋なデータ構造としてコードで記述します。
このデータ構造はそれから効率的にDOMに描画されます。
加えてコンポーネントはボタンクリックのようなイベントに応答することができます。
`react-basic-hooks`ライブラリは`Effect`モナドを使ってこれらのイベントの制御方法を記述します。

Reactライブラリの完全なチュートリアルはこの章の範囲をはるかに超えていますが、
読者は必要に応じてマニュアルを参照することをお勧めします。
目的に応じて、Reactは `Effect`モナドの実用的な例を提供してくれます。

利用者が住所録に新しい項目を追加できるフォームを構築することにしましょう。
フォームには、さまざまなフィールド（姓、名前、都市、州など）のテキストボックス、
および検証エラーが表示される領域が含まれます。
テキストボックスに利用者がテキストを入力すると、検証エラーが更新されます。

シンプルさを保つために、
フォームは固定の形状とします。
電話番号は種類（自宅、携帯電話、仕事、その他）ごとに
別々のテキストボックスへ分けることにします。

`exercises/chapter8`ディレクトリから以下のコマンドでWebアプリを立ち上げることができます。

```
$ npm install
$ npx spago build
$ npx parcel src/index.html --open
```

もし`spago`や`parcel`のような開発ツールが大域的にインストールされていれば、
`npx`の前置は省けるでしょう。
恐らく既に`spago`を`npm i -g spago`で大域的にインストールしていますし、
`parcel`についても同じことができるでしょう。

`parcel`は「アドレス帳」アプリのブラウザ窓を立ち上げます。
`parcel`の端末を開いたままにし、他の端末で`spago`で再構築すると、
最新の編集を含むページが自動的に再読み込みされるでしょう。
また、[`purs
ide`](https://github.com/purescript/purescript/tree/master/psc-ide)をサポートしていたり[`pscid`](https://github.com/kRITZCREEK/pscid)を走らせていたりする
[エディタ](https://github.com/purescript/documentation/blob/master/ecosystem/Editor-and-tool-support.md#editors)を使っていれば、
ファイルを保存したときに自動的にページが再構築される（そして自動的にページが再読み込みされる）ように設定できます。

このアドレス帳アプリでフォームフィールドにいろいろな値を入力すると、
ページ上に出力された検証エラーを見ることができるでしょう。

動く仕組みを散策しましょう。

`src/index.html`ファイルは最小限です。

```html
{{#include ../exercises/chapter8/src/index.html}}
```

`<script`の行はJavaScriptの入口を含んでおり、
`index.js`にはこの1行が含まれています。

```js
{{#include ../exercises/chapter8/src/index.js}}
```

`module Main` (`src/main.purs`) の`main`関数と等価な、
生成したJavaScriptを呼び出しています。
`spago build`は生成された全てのJavaScriptを`output`ディレクトリに置くことを思い出してください。

`main`関数はDOMとHTML APIを使い、
`index.html`に定義した`container`要素の中にアドレス帳コンポーネントを描画します。

```hs
{{#include ../exercises/chapter8/src/Main.purs:main}}
```

これら3行に注目してください。

```hs
w <- window
doc <- document w
ctr <- getElementById "container" $ toNonElementParentNode doc
```

これは次のように統合できます。

```hs
doc <- document =<< window
ctr <- getElementById "container" $ toNonElementParentNode doc
```

あるいはさらに統合することさえできます。

```hs
ctr <- getElementById "container" <<< toNonElementParentNode =<< document =<< window
-- or, equivalently:
ctr <- window >>= document >>= toNonElementParentNode >>> getElementById "container"
```

途中の`w`や`doc`変数が読みやすさの助けになるかは主観的な嗜好の問題です。

AddressBookの`reactComponent`を深堀りしましょう。
単純化されたコンポーネントから始め、それから`Main.purs`で実際のコードに構築していきます。

以下の最小限のコンポーネントをご覧ください。
遠慮なく全体のコンポーネントをこれに置き換えて実行の様子を見てみましょう。

```hs
mkAddressBookApp :: Effect (ReactComponent {})
mkAddressBookApp =
  reactComponent
    "AddressBookApp"
    (\props -> pure $ D.text "Hi! I'm an address book")
```

`reactComponent`にはこのような威圧的なシグネチャがあります。

```hs
reactComponent ::
  forall hooks props.
  Lacks "children" props =>
  Lacks "key" props =>
  Lacks "ref" props =>
  String ->
  ({ | props } -> Render Unit hooks JSX) ->
  Effect (ReactComponent { | props })
```

重要な注意点は全ての型クラス制約の後の引数にあります。
`String`（任意のコンポーネント名）、
`props`を描画された`JSX`に変換する方法を記述する関数を取り、
そして`Effect`に包まれた`ReactComponent`を返します。

propsからJSXへの関数は単にこうです。

```hs
\props -> pure $ D.text "Hi! I'm an address book"
```

`props`は無視されており、`D.text`は`JSX`を返し、
そして`pure`は描画されたJSXに持ち上げます。
これで`component`には`ReactComponent`を生成するのに必要な全てがあります。

次に完全なアドレス帳コンポーネントにある追加の複雑な事柄のいくつかを調べていきます。

これらは完全なコンポーネントの最初の数行です。

```hs
mkAddressBookApp :: Effect (ReactComponent {})
mkAddressBookApp = do
  reactComponent "AddressBookApp" \props -> R.do
    Tuple person setPerson <- useState examplePerson
```

`person`を`useState`フックの状態の一部として追跡します。

```hs
Tuple person setPerson <- useState examplePerson
```

なお、複数回`useState`を呼び出すことで、
コンポーネントの状態を複数の状態の部品に分解することは自由です。
例えば`Person`のそれぞれのレコードフィールドについて分離した状態の部品を使って、
このアプリを書き直すことができるでしょう。
しかしこの場合にそれをすると僅かに利便性を損なうアーキテクチャになってしまいます。

他の例では`Tuple`用の`/\`中置演算子に出喰わすかもしれません。
これは上の行と等しいものです。

```hs
firstName /\ setFirstName <- useState p.firstName
```

`useState`は既定の初期値を取り現在の値と値を更新する方法を取ります。
`useState`の型を確認すれば型`person`と`setPerson`についてより深い洞察が得られます。

```hs
useState ::
  forall state.
  state ->
  Hook (UseState state) (Tuple state ((state -> state) -> Effect Unit))
```

結果の値の`Hook (UseState state)`ラッパーを取り去ることができますが、
それは`useState`が`R.do`ブロックの中で呼ばれているからです。
`R.do`は後で詳述します。

さてこれで以下のシグネチャを観察できます。

```hs
person :: state
setPerson :: (state -> state) -> Effect Unit
```

`state`の限定された型は初期の既定値によって決定されます。
これは`examplePerson`の型なのでこの場合は`Person` `Record`です。

`person`はそれぞれの再描画の時点で現在の状態にアクセスする方法です。

`setPerson`は状態を更新する方法です。
現在の状態を新しい状態に変形する方法を記述する関数を単に提供します。
`state`の型が偶然`Record`のときは、レコード更新構文はこれにぴったりです。
例えば以下。

```hs
setPerson (\currentPerson -> currentPerson {firstName = "NewName"})

```

あるいは短かく以下です。

```hs
setPerson _ {firstName = "NewName"}
```

`Record`でない状態もまたこの更新パターンにしたがいます。
ベストプラクティスについてのより詳しいことは[このガイド](https://github.com/megamaddu/purescript-react-basic-hooks/pull/24#issuecomment-620300541)を参照してください。

`useState`が`R.do`ブロックの中で使われていることを思い出しましょう。
`R.do`は`do`の特別なreactフックの派生です。
`R.`の前置はこれが`React.Basic.Hooks`から来たものとして「限定する」もので、
`R.do`ブロックの中でフック互換版の`bind`を使うことを意味しています。
これは「限定されたdo」として知られています。
`Hook (UseState state)`のラッピングを無視し、
内部の値の`Tuple`と変数に束縛してくれます。

他の状態管理戦略として挙げられるのは`useReducer`ですが、
それはこの章の範疇外です。

以下では`JSX`の描画が行われています。

```hs
pure
  $ D.div
      { className: "container"
      , children:
          renderValidationErrors errors
            <> [ D.div
                  { className: "row"
                  , children:
                      [ D.form_
                          $ [ D.h3_ [ D.text "Basic Information" ]
                            , formField "First Name" "First Name" person.firstName \s ->
                                setPerson _ { firstName = s }
                            , formField "Last Name" "Last Name" person.lastName \s ->
                                setPerson _ { lastName = s }
                            , D.h3_ [ D.text "Address" ]
                            , formField "Street" "Street" person.homeAddress.street \s ->
                                setPerson _ { homeAddress { street = s } }
                            , formField "City" "City" person.homeAddress.city \s ->
                                setPerson _ { homeAddress { city = s } }
                            , formField "State" "State" person.homeAddress.state \s ->
                                setPerson _ { homeAddress { state = s } }
                            , D.h3_ [ D.text "Contact Information" ]
                            ]
                          <> renderPhoneNumbers
                      ]
                  }
              ]
      }
```

ここでDOMの意図した状態を表現する`JSX`を生成しています。
このJSXはHTMLタグ（例：`div`、`form`、`h3`、`li`、`ul`、`label`、`input`）に対応し単一のHTML要素を作る関数を適用することで作られるのが典型的です。
これらのHTML要素は実はReactコンポーネント自体でJSXに変換されます。
通常これらの関数にはそれぞれ3つの種類があります。

* `div_`: 子要素の配列を受け付けます。
  既定の属性を使います。
* `div`: 属性の`Record`を受け付けます。
  子要素の配列をこのレコードの`children`フィールドに渡すことができます。
* `div'`: `div`と同じですが、`JSX`に変換する前に`ReactComponent`を返します。

検証エラーをフォームの一番上に（もしあれば）表示するのに、
`Errors`構造体をJSXの配列に変える`renderValidationErrors`お助け関数を作ります。
この配列はフォームの残り部分の前に付けます。

```hs
{{#include ../exercises/chapter8/src/Main.purs:renderValidationErrors}}
```

なお、ここでは通常のデータ構造体を単純に操作しているので、
`map`のような関数を使ってより興味深い要素を構築することができます。

```hs
children: [ D.ul_ (map renderError xs)]
```

`className`プロパティを使ってCSSスタイルのクラスを定義します。
このプロジェクトでは[Bootstrap](https://getbootstrap.com/)の`stylesheet`を使っており、
これは`index.html`でインポートされています。
例えばフォーム中のアイテムは`row`として配置されてほしいですし、
検証エラーは`alert-danger`の装飾で強調されていてほしいです。

```hs
className: "alert alert-danger row"
```

2番目の補助関数は `formField`です。
これは、単一フォームフィールドのテキスト入力を作ります。

```hs
{{#include ../exercises/chapter8/src/Main.purs:formField}}
```

`input`を置いて`label`の中に`text`を表示することは、
スクリーンリーダーのアクセシビリティの助けになります。

`onChange`属性があれば利用者の入力に応答する方法を記述することができます。
`handler`関数を使いますが、これは以下の型を持ちます。

```hs
handler :: forall a. EventFn SyntheticEvent a -> (a -> Effect Unit) -> EventHandler
```

`handler`への最初の引数には`targetValue`を使いますが、
これはHTMLの`input`要素中のテキストの値を提供します。
この場合は型変数`a`が`Maybe String`で、
`handler`が期待するシグネチャに合致しています。

```hs
targetValue :: EventFn SyntheticEvent (Maybe String)
```

JavaScriptでは`input`要素の`onChange`イベントは実は`String`値と一緒になっているのですが、
JavaScriptの文字列はnullになりえるので、安全のために`Maybe`が使われています。

`(a -> Effect Unit)`の`handler`への2つ目の引数は、したがってこのシグネチャを持ちます。

```hs
Maybe String -> Effect Unit
```

この関数は`Maybe String`値を求める作用に変換する方法を記述します。
この目的のために以下のように自前の`handleValue`関数を定義して`handler`を渡します。

```hs
onChange:
  let
    handleValue :: Maybe String -> Effect Unit
    handleValue (Just v) = setValue v
    handleValue Nothing  = pure unit
  in
    handler targetValue handleValue
```

`setValue`はそれぞれの`formField`の呼び出しに提供した関数で
文字列を取り`setPerson`フックに適切なレコード更新呼び出しを実施します。

なお`handleValue`は以下のようにも置き換えられます。

```hs
onChange: handler targetValue $ traverse_ setValue
```

どうぞ`traverse_`の定義を調査して両方の形式が確かに等価であることをご確認ください。

これは、コンポーネント実装の基本をカバーしています。
しかし、コンポーネントの仕組みを完全に理解するためには、
この章に付随する情報をお読みください。

明らかに、このユーザインタフェースには改善すべき点がたくさんあります。
演習ではアプリケーションがより使いやすくなるような方法を追究していきます。

## 演習

以下の演習では`src/Main.purs`を変更してください。
これらの演習には単体試験はありません。

1. （簡単）このアプリケーションを変更し、
   職場の電話番号を入力できるテキストボックスを追加してください。
1. （普通）現時点でアプリケーションは検証エラーを
   単一の「pink-alert」背景に集めて表示させています。
   空の線で分割することにより、
   それぞれの検証エラーにpink-alert背景を持たせるように変更してください。

    **ヒント**：リスト中の検証エラーを表示するのに`ul`要素を使う代わりに、
    コードを変更し、
    それぞれのエラーに`alert`と`alert-danger`装飾を持つ`div`を作ってください。
1. （難しい、発展）このユーザーインターフェイスの問題のひとつは、
   検証エラーがその発生源であるフォームフィールドの隣に表示されていないことです。
   コードを変更してこの問題を解決してください。

    **ヒント**：検証器によって返されるエラーの型は、
    エラーの原因となっているフィールドを示すために拡張する必要があります。
    次のような変更されたエラー型を使用したくなるかもしれません。

    ```hs
    data Field = FirstNameField
               | LastNameField
               | StreetField
               | CityField
               | StateField
               | PhoneField PhoneType

    data ValidationError = ValidationError String Field

    type Errors = Array ValidationError
    ```

   `Error`構造体から特定の`Field`のための検証エラーを取り出す関数を書く必要があるでしょう。

## まとめ

この章ではPureScriptでの副作用の扱いについての多くの考え方を導入しました。

- `Monad`型クラスと、do記法との関連に出会いました。
- モナド則を導入し、do記法を使って書かれたコードを変換する方法を見ました。
- 異なる副作用で動作するコードを書くために、モナドを抽象的に扱う方法を見
  ました。
- モナドがアプリカティブ関手の一例であること、両者がどのように副作用のあ
  る計算を可能にするのかということ、そして2つの手法の違いを説明しました。
- ネイティブな作用の概念を定義し、ネイティブな副作用を処理するために使用
  する `Effect`モナドを導入しました。
- 乱数生成、例外、コンソール入出力、変更可能な状態、およびReactを使った
  DOM操作といった、さまざまな作用を扱うために `Effect`モナドを使いました。

`Effect`モナドは現実のPureScriptコードにおける基本的なツールです。
本書ではこのあとも、多くの場面で副作用を処理するために使っていきます。

- - -

<small>

この翻訳は[aratama](https://github.com/aratama)氏による翻訳を元に改変を加えています。
同氏の翻訳リポジトリは[`aratama/purescript-book-ja`](https://github.com/aratama/purescript-book-ja)に、Webサイトは[実例によるPureScript](http://aratama.github.io/purescript/)にあります。

[原文の使用許諾](https://book.purescript.org/)：

> Copyright (c) 2014-2017 Phil Freeman.
>
> The text of this book is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License: <https://creativecommons.org/licenses/by-nc-sa/3.0/deed.en_US>.
>
> Some text is derived from the [PureScript Documentation Repo](https://github.com/purescript/documentation), which uses the same license, and is copyright [various contributors](https://github.com/purescript/documentation/blob/master/CONTRIBUTORS.md).
>
> The exercises are licensed under the MIT license.

[aratama氏訳の使用許諾](http://aratama.github.io/purescript/)：

> This book is licensed under the [Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-nc-sa/3.0/deed.en_US).
>
> 本書は[クリエイティブコモンズ 表示 - 非営利 - 継承 3.0 非移植ライセンス](http://creativecommons.org/licenses/by-nc-sa/3.0/deed.ja)でライセンスされています。

本翻訳の使用許諾：

本翻訳も原文と原翻訳にしたがい、
[Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License](https://creativecommons.org/licenses/by-nc-sa/3.0/deed.en_US)の下に提供されています。

</small>