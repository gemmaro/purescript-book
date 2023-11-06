# 作用モナド

## この章の目標

前章では、*副作用*を扱うのに使う抽象化であるアプリカティブ関手を導入しました。
副作用とは省略可能な値、エラー文言、検証などです。
この章では、副作用を扱うためのより表現力の高い別の抽象化である*モナド*を導入します。

この章の目的は、なぜモナドが便利な抽象化なのかということと、*do記法*との関係を説明することです。

## プロジェクトの準備

このプロジェクトでは、以下の依存関係が追加されています。

- `effect`: 章の後半の主題である`Effect`モナドを定義しています。
  この依存関係は全てのプロジェクトで始めから入っているものなので（これまでの全ての章でも依存関係にありました）、明示的にインストールしなければいけないことは稀です。
- `react-basic-hooks`: 住所録アプリに使うwebフレームワークです。

## モナドとdo記法

do記法は*配列内包表記*を扱うときに初めて導入されました。
配列内包表記は`Data.Array`モジュールの`concatMap`関数の構文糖として提供されています。

次の例を考えてみましょう。2つのサイコロを振って出た目を数え、出た目の合計が
`n`のときそれを得点とすることを考えます。次のような非決定的なアルゴリズムを使うとこれを実現できます。

- 最初の投擲で値 `x`を _選択_ します。
- 2回目の投擲で値 `y`を _選択_ します。
- もし`x`と`y`の和が`n`なら組`[x, y]`を返し、そうでなければ失敗します。

配列内包表記を使うと、この非決定的アルゴリズムを自然に書けます。

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

前の章では、*省略可能な値*に対応したより大きなプログラミング言語へとPureScriptの関数を埋め込む、`Maybe`アプリカティブ関手についての直感的理解を養いました。
同様に*配列モナド*についても、*非決定選択*に対応したより大きなプログラミング言語へPureScriptの関数を埋め込む、というような直感的理解を得ることができます。

一般に、ある型構築子`m`のモナドは、型`m a`の値を持つdo記法を使う手段を提供します。
上の配列内包表記に注意すると、何らかの型`a`について全行に型`Array a`の計算が含まれています。
一般に、do記法ブロックの全行は、何らかの型`a`とモナド`m`について、型`m a`の計算を含みます。
モナド`m`は全行で同じでなければなりません（つまり副作用は固定）が、型`a`は異なることもあります（つまり個々の計算は異なる型の結果にできる）。

以下はdo記法の別の例です。
今回は型構築子 `Maybe`に適用されています。
XMLノードを表す型 `XML`と次の関数があるとします。

```hs
child :: XML -> String -> Maybe XML
```

この関数はノードの子の要素を探し、もしそのような要素が存在しなければ `Nothing`を返します。

この場合、do記法を使うと深い入れ子になった要素を検索できます。
XML文書としてエンコードされた利用者情報から、利用者の住んでいる市町村を読み取りたいとします。

```hs
userCity :: XML -> Maybe XML
userCity root = do
  prof <- child root "profile"
  addr <- child prof "address"
  city <- child addr "city"
  pure city
```

`userCity`関数は子の`profile`要素、`profile`要素の中にある`address`要素、最後に`address`要素の中にある`city`要素を探します。
これらの要素の何れかが欠落している場合、返り値は`Nothing`になります。
そうでなければ、返り値は`city`ノードから`Just`を使って構築されます。

最後の行にある`pure`関数は、全ての`Applicative`関手について定義されているのでした。
`Maybe`の`Applicative`関手の`pure`関数は`Just`として定義されており、最後の行を `Just
city`へ変更しても同じように正しく動きます。

## モナド型クラス

`Monad`型クラスは次のように定義されています。

```hs
class Apply m <= Bind m where
  bind :: forall a b. m a -> (a -> m b) -> m b

class (Applicative m, Bind m) <= Monad m
```

ここで鍵となる関数は `Bind`型クラスで定義されている演算子 `bind`で、`Functor`及び `Apply`型クラスにある `<$>`や `<*>`などの演算子と同様に、`Prelude`では `>>=`として `bind`の中置の別名が定義されています。

`Monad`型クラスは、既に見てきた`Applicative`型クラスの操作で`Bind`を拡張します。

`Bind`型クラスの例を幾つか見てみるのがわかりやすいでしょう。
配列についての `Bind`の妥当な定義は次のようになります。

```hs
instance Bind Array where
  bind xs f = concatMap f xs
```

これは以前に仄めかした、配列内包表記と `concatMap`関数の関係を説明しています。

`Maybe`型構築子についての `Bind`の実装は次のようになります。

```hs
instance Bind Maybe where
  bind Nothing  _ = Nothing
  bind (Just a) f = f a
```

この定義は欠落した値がdo記法ブロックを通じて伝播するという直感的理解を裏付けるものです。

`Bind`型クラスとdo記法がどのように関係しているかを見て行きましょう。
最初に、何らかの計算結果からの値の束縛から始まる、単純なdo記法ブロックについて考えてみましょう。

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

この計算 `whatToDoNext`は `value`に依存できます。

複数の束縛が関係している場合、この規則は先頭のほうから複数回適用されます。例えば、先ほど見た `userCity`の例では次のように脱糖されます。

```hs
userCity :: XML -> Maybe XML
userCity root =
  child root "profile" >>= \prof ->
    child prof "address" >>= \addr ->
      child addr "city" >>= \city ->
        pure city
```

do記法を使って表現されたコードは、`>>=`演算子を使う等価なコードより遥かに読みやすくなることがよくあることも特筆すべき点です。
しかしながら、明示的に`>>=`を使って束縛を書くと、*ポイントフリー*形式でコードが書けるようになることがよくあります。
ただし、読みやすさにはやはり注意が要ります。

## モナド則

`Monad`型クラスは*モナド則*と呼ばれる3つの規則を持っています。これらは
`Monad`型クラスの合理的な実装から何を期待できるかを教えてくれます。

do記法を使用してこれらの規則を説明していくのが最も簡単でしょう。

### 単位元律

*右単位元則* (right-identity law)
が3つの規則の中で最も簡単です。この規則はdo記法ブロックの最後の式であれば、`pure`の呼び出しを排除できると言っています。

```hs
do
  x <- expr
  pure x
```

右単位元則は、この式は単なる `expr`と同じだと言っています。

*左単位元則* (left-identity law)
は、もしそれがdo記法ブロックの最初の式であれば、`pure`の呼び出しを除去できると述べています。

```hs
do
  x <- pure y
  next
```

このコードは`next`の名前`x`を式`y`で置き換えたものと同じです。

最後の規則は _結合則_ (associativity law)
です。これは入れ子になったdo記法ブロックをどう扱うのかについて教えてくれます。この規則が述べているのは以下のコード片のことです。

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

これらの各計算には3つのモナドの式`m1`、`m2`、`m3`が含まれています。
どちらの場合でも`m1`の結果は結局は名前`x`に束縛され、`m2`の結果は名前`y`に束縛されます。

`c1`では2つの式`m1`と`m2`が各do記法ブロック内にグループ化されています。

`c2`では`m1`、`m2`、`m3`の3つ全ての式が同じdo記法ブロックに現れています。

結合法則は入れ子になったdo記法ブロックをこのように単純化しても問題ないことを言っています。

*補足*：do記法を`bind`の呼び出しへと脱糖する定義により、 `c1`と `c2`は何れも次のコードと同じです。

```hs
c3 = do
  x <- m1
  do
    y <- m2
    m3
```

## モナドで畳み込む

抽象的にモナドを扱う例として、この節では `Monad`型クラス中の任意の型構築子で機能する関数を紹介していきます。
これはモナドによるコードが副作用を伴う「より大きな言語」でのプログラミングと対応しているという直感的理解を補強しますし、モナドによるプログラミングが齎す一般性も示しています。

これから書いていく関数は`foldM`という名前です。
以前見た`foldl`関数をモナドの文脈へと一般化するものです。
型シグネチャは以下です。

```hs
foldM :: forall m a b. Monad m => (a -> b -> m a) -> a -> List b -> m a
foldl :: forall   a b.            (a -> b ->   a) -> a -> List b ->   a
```

モナド `m`が現れている点を除いて、 `foldl`の型と同じであることに注意しましょう。

直感的には、`foldM`は様々な副作用の組み合わせに対応した文脈で配列を畳み込むものと捉えられます。

例として`m`として`Maybe`を選ぶとすると、各段階で`Nothing`を返すことでこの畳み込みを失敗させられます。
各段階では省略可能な結果を返しますから、それ故畳み込みの結果も省略可能になります。

もし`m`として型構築子`Array`を選ぶとすると、畳み込みの各段階で0以上の結果を返せるため、畳み込みは各結果に対して独立に次の手順を継続します。
最後に、結果の集まりは可能な経路の全ての畳み込みから構成されることになります。
これはグラフの走査と対応していますね。

`foldM`を書くには、単に入力のリストについて場合分けをするだけです。

リストが空なら、型 `a`の結果を生成するための選択肢は1つしかありません。第2引数を返します。

```hs
foldM _ a Nil = pure a
```

なお、`a`をモナド `m`まで持ち上げるために `pure`を使わなくてはいけません。

リストが空でない場合はどうでしょうか。
その場合、型 `a`の値、型 `b`の値、型 `a -> b -> m a`の関数があります。
もしこの関数を適用すると、型 `m a`のモナドの結果を手に入れることになります。
この計算の結果を逆向きの矢印 `<-`で束縛できます。

あとはリストの残りに対して再帰するだけです。実装は簡単です。

```hs
foldM f a (b : bs) = do
  a' <- f a b
  foldM f a' bs
```

なお、この実装はリストに対する`foldl`の実装とほとんど同じです。
ただしdo記法である点を除きます。

PSCiでこの関数を定義して試せます。
以下は一例です。
整数の「安全な除算」関数を定義するとします。
0による除算かを確認し、失敗を示すために `Maybe`型構築子を使うのです。

```hs
{{#include ../exercises/chapter8/test/Examples.purs:safeDivide}}
```

これで、 `foldM`で安全な除算の繰り返しを表現できます。

```text
> import Test.Examples
> import Data.List (fromFoldable)

> foldM safeDivide 100 (fromFoldable [5, 2, 2])
(Just 5)

> foldM safeDivide 100 (fromFoldable [2, 0, 4])
Nothing
```

もし何れかの時点で0による除算が試みられたら、`foldM safeDivide`関数は`Nothing`を返します。
そうでなければ、累算値を繰り返し除算した結果を`Just`構築子に包んで返します。

## モナドとアプリカティブ

クラス間に上位クラス関係の効能があるため、`Monad`型クラスの全てのインスタンスは `Apply`型クラスのインスタンスでもあります。

しかし、あらゆる`Monad`のインスタンスに「無料で」ついてくる`Apply`型クラスの実装もあります。これは`ap`関数により与えられます。

```hs
ap :: forall m a b. Monad m => m (a -> b) -> m a -> m b
ap mf ma = do
  f <- mf
  a <- ma
  pure (f a)
```

もし`m`に`Monad`型クラスの法則の縛りがあれば、`ap`で与えられる`m`について妥当な `Apply`インスタンスが存在します。

興味のある読者はこれまで登場したモナドについてこの`ap`が`apply`として充足することを確かめてみてください。
モナドは`Array`、`Maybe`、`Either e`といったものです。

もし全てのモナドがアプリカティブ関手でもあるなら、アプリカティブ関手についての直感的理解を全てのモナドについても適用できるはずです。
特に、モナドが更なる副作用の組み合わせで増強された「より大きな言語」でのプログラミングといろいろな意味で一致することを予想するのはもっともです。
`map`と `apply`を使って、引数が任意個の関数をこの新しい言語へと持ち上げることができるはずです。

しかし、モナドはアプリカティブ関手でできること以上ができ、重要な違いはdo記法の構文で強調されています。
`userCity`の例についてもう一度考えてみましょう。
利用者情報をエンコードしたXML文書から利用者の市町村を検索するものでした。

```hs
userCity :: XML -> Maybe XML
userCity root = do
  prof <- child root "profile"
  addr <- child prof "address"
  city <- child addr "city"
  pure city
```

do記法では2番目の計算が最初の結果 `prof`に依存し、3番目の計算が2番目の計算の結果`addr`に依存するというようなことができます。
`Applicative`型クラスのインターフェイスだけを使うのでは、このように以前の値へ依存できません。

`pure`と `apply`だけを使って `userCity`を書こうとしてみれば、これが不可能であることがわかるでしょう。
アプリカティブ関手ができるのは関数の互いに独立した引数を持ち上げることだけですが、モナドはもっと興味深いデータの依存関係に関わる計算を書くことを可能にします。

前の章では`Applicative`型クラスは並列処理を表現できることを見ました。
持ち上げられた関数の引数は互いに独立していますから、これはまさにその通りです。
`Monad`型クラスは計算が前の計算の結果に依存できるようになっており、同じようにはなりません。
つまりモナドは副作用を順番に組み合わせなければならないのです。

## 演習

 1. （簡単）3つ以上の要素がある配列の3つ目の要素を返す関数`third`を書いてください。
    関数は適切な`Maybe`型で返します。
    *手掛かり*：`arrays`パッケージの`Data.Array`モジュールから`head`と`tail`関数の型を見つけ出してください。
    これらの関数を組み合わせるには`Maybe`モナドと共にdo記法を使ってください。
 1. （普通）一掴みの硬貨を使ってできる可能な全ての合計を決定する関数 `possibleSums`を、 `foldM`を使って書いてみましょう。
    入力の硬貨は、硬貨の価値の配列として与えられます。この関数は次のような結果にならなくてはいけません。

     ```text
     > possibleSums []
     [0]

     > possibleSums [1, 2, 10]
     [0,1,2,3,10,11,12,13]
     ```

     *手掛かり*：`foldM`を使うと1行でこの関数を書けます。
     重複を取り除いたり、結果を並び替えたりするのに、`nub`関数や`sort`関数を使うことでしょう。
1. （普通）`ap`関数と`apply`演算子が`Maybe`モナドを充足することを確かめてください。
   *補足*：この演習にはテストがありません。
1. （普通）`Maybe`型についての`Monad`インスタンスが、モナド則を満たしていることを検証してください。
   このインスタンスは`maybe`パッケージで定義されています。
   *補足*：この演習にはテストがありません。
1. （普通）リスト上の`filter`の関数を一般化した関数`filterM`を書いてください。
   この関数は次の型シグネチャを持ちます。

     ```hs
     filterM :: forall m a. Monad m => (a -> m Boolean) -> List a -> m (List a)
     ```

 1. （難しい）全てのモナドには次で与えられるような既定の`Functor`インスタンスがあります。

     ```hs
     map f a = do
       x <- a
       pure (f x)
     ```

     モナド則を使って、全てのモナドが次を満たすことを証明してください。

     ```hs
     lift2 f (pure a) (pure b) = pure (f a b)
     ```

     ここで、`Applly`インスタンスは上で定義された`ap`関数を使用しています。
     `lift2`が次のように定義されていたことを思い出してください。

     ```hs
     lift2 :: forall f a b c. Apply f => (a -> b -> c) -> f a -> f b -> f c
     lift2 f a b = f <$> a <*> b
     ```

    *補足*：この演習にはテストがありません。

## ネイティブな作用

ここではPureScriptで中心的な重要性のあるモナドの1つ、`Effect`モナドについて見ていきます。

`Effect`モナドは `Effect`モジュールで定義されています。かつてはいわゆる _ネイティブ_
副作用を管理していました。Haskellに馴染みがあれば、これは`IO`モナドと同等のものです。

ネイティブな副作用とは何でしょうか。
この副作用はPureScript特有の式とJavaScriptの式とを2分するものです。
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

既に「ネイティブでない」副作用の例については数多く見てきています。

- `Maybe`データ型で表現される省略可能な値
- `Either`データ型で表現されるエラー
- 配列やリストで表現される多値関数

これらの区別はわかりにくいので注意してください。
例えば、エラー文言は例外の形でJavaScriptの式の副作用となることがあると言えます。
その意味では例外はネイティブな副作用を表していて、`Effect`を使用して表現できます。
しかし、`Either`を使用して実装されたエラー文言はJavaScript実行時の副作用ではなく、`Effect`を使うスタイルでエラー文言を実装するのは不適切です。
そのため、ネイティブなのは作用自体というより、実行時にどのように実装されているかです。

## 副作用と純粋性

PureScriptのような純粋な言語では、ある疑問が浮かんできます。
副作用がないなら、どうやって役に立つ実際のコードを書くことができるのでしょうか。

その答えはPureScriptの目的は副作用を排除することではないということです。
純粋な計算と副作用のある計算とを、型システムにおいて区別できるような方法で表現します。
この意味で、言語はあくまで純粋なのです。

副作用のある値は、純粋な値とは異なる型を持っています。
そういうわけで、例えば副作用のある引数を関数に渡すことはできず、予期せず副作用を持つようなことが起こらなくなります。

`Effect`モナドで管理された副作用を現す手段は、型`Effect a`の計算をJavaScriptから実行することです。

Spagoビルドツール（や他のツール）は早道を用意しており、アプリケーションの起動時に`main`計算を呼び出すための追加のJavaScriptコードを生成します。
`main`は`Effect`モナドでの計算であることが要求されます。

## 作用モナド

`Effect`は副作用のある計算を充分に型付けするAPIを提供すると同時に、効率的なJavaScriptを生成します。

馴染みのある`log`関数から返る型を見てみましょう。
`Effect`はこの関数がネイティブな作用を生み出すことを示しており、この場合はコンソールIOです。

`Unit`はいかなる*意味のある*データも返らないことを示しています。
`Unit`はC、Javaなど他の言語での`void`キーワードと似たものとして考えられます。

```hs
log :: String -> Effect Unit
```

> _余談_ ：より一般的な（そしてより込み入った型を持つ）`Effect.Class.Console`の`log`関数をIDEから提案されるかもしれません。
> これは基本的な`Effect`モナドを扱う際は`Effect.Console`からの関数と交換可能です。
> より一般的なバージョンがあることの理由は「モナドな冒険」章の「モナド変換子」について読んだあとにより明らかになっていることでしょう。
> 好奇心のある（そしてせっかちな）読者のために言うと、これは`Effect`に`MonadEffect`インスタンスがあるから機能するのです。
>
> ```hs
> log :: forall m. MonadEffect m => String -> m Unit
> ```

それでは意味のあるデータを返す`Effect`を考えましょう。
`Effect.Random`の`random`関数は乱択された`Number`を生み出します。

```hs
random :: Effect Number
```

以下は完全なプログラムの例です（この章の演習フォルダの`test/Random.purs`にあります）。

```hs
{{#include ../exercises/chapter8/test/Random.purs}}
```

`Effect`はモナドなので、do記法を使って含まれるデータを開封し、それからこのデータを作用のある`logShow`関数に渡します。
気分転換に、以下は`bind`演算子を使って書かれた同等なコードです。

```hs
main :: Effect Unit
main = random >>= logShow
```

これを手元で走らせてみてください。

```shell
spago run --main Test.Random
```

コンソールに出力 `0.0`と `1.0`の間で無作為に選ばれた数が表示されるでしょう。

> 余談：`spago run`は既定で`main`関数を`Main`モジュールの中から探索します。
> `--main`フラグで代替のモジュールを入口として指定することも可能で、上の例ではそうしています。
> この代替のモジュールにも`main`関数が含まれているようにはしてください。

なお、不浄な作用付きのコードに訴えることなく、「乱択された」（技術的には疑似乱択された）データも生成できます。
この技法は「テストを生成する」章で押さえます。

以前言及したように`Effect`モナドはPureScriptで核心的な重要さがあります。
なぜ核心かというと、それはPureScriptの`外部関数インターフェース`とやり取りする上での常套手段だからです。
`外部関数インターフェース`はプログラムを実行したり副作用を発生させたりする仕組みを提供します。
`外部関数インターフェース`を使うことは避けるのが望ましいのですが、どのように動作しどう使うのか理解することもまた極めて大事なことですので、実際にPureScriptで何か動かす前にその章を読まれることをお勧めします。
要は`Effect`モナドは結構単純なのです。
幾つかの補助関数がありますが、副作用を内包すること以外には大したことはしません。

## 例外

2つの*ネイティブな*副作用が絡む`node-fs`パッケージの関数を調べましょう。
ここでの副作用は可変状態の読み取りと例外です。

```hs
readTextFile :: Encoding -> String -> Effect String
```

もし存在しないファイルを読もうとすると……

```hs
import Node.Encoding (Encoding(..))
import Node.FS.Sync (readTextFile)

main :: Effect Unit
main = do
  lines <- readTextFile UTF8 "iDoNotExist.md"
  log lines
```

以下の例外に遭遇します。

```text
    throw err;
    ^
Error: ENOENT: no such file or directory, open 'iDoNotExist.md'
...
  errno: -2,
  syscall: 'open',
  code: 'ENOENT',
  path: 'iDoNotExist.md'
```

この例外をうまく管理するには、潜在的に問題があるコードを`try`に包めばどのような出力でも制御できます。

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

独自の例外も生成できます。
以下は`Data.List.head`の代替実装で、`Maybe`の値の`Nothing`を返す代わりにリストが空のとき例外を投げます。

```hs
exceptionHead :: List Int -> Effect Int
exceptionHead l = case l of
  x : _ -> pure x
  Nil -> throwException $ error "empty list"
```

ただし`exceptionHead`関数はどこかしら非実用的な例です。
というのも、PureScriptのコードで例外を生成するのは避け、代わりに`Either`や`Maybe`のようなネイティブでない作用でエラーや欠けた値を使うのが一番だからです。

## 可変状態

中核ライブラリには `ST`作用という、これまた別の作用も定義されています。

`ST`作用は変更可能な状態を操作するために使われます。
純粋関数プログラミングを知っているなら、共有される変更可能な状態は問題を引き起こしやすいということも知っているでしょう。
しかし、`ST`作用は型システムを使って安全で*局所的な*状態変化を可能にし、状態の共有を制限するのです。

`ST`作用は `Control.Monad.ST`モジュールで定義されています。
この挙動を確認するには、その動作の型を見る必要があります。

```hs
new :: forall a r. a -> ST r (STRef r a)

read :: forall a r. STRef r a -> ST r a

write :: forall a r. a -> STRef r a -> ST r a

modify :: forall r a. (a -> a) -> STRef r a -> ST r a
```

`new`は型`STRef r a`の可変参照領域を新規作成するのに使われます。
この領域は`read`動作を使って読み取ったり、`write`動作や`modify`動作で状態を変更するのに使えます。
型`a`は領域に格納された値の型を、型`r`は*メモリ領域*（または*ヒープ*）を、それぞれ型システムで表しています。

例を示します。
重力に従って落下する粒子の落下の動きをシミュレートしたいとしましょう。
これには小さな時間刻みで簡単な更新関数の実行を何度も繰り返します。

粒子の位置と速度を保持する変更可能な参照領域を作成し、領域に格納された値を更新するのにforループを使うことでこれを実現できます。

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

計算の最後では、参照領域の最終的な値を読み取り、粒子の位置を返しています。

なお、この関数が変更可能な状態を使っていても、その参照領域`ref`がプログラムの他の部分での使用が許されない限り、これは純粋な関数のままです。
このことが正に`ST`作用が禁止するものであることを見ていきます。

`ST`作用付きで計算するには、`run`関数を使用する必要があります。

```hs
run :: forall a. (forall r. ST r a) -> a
```

ここで注目して欲しいのは、領域型 `r`が関数矢印の左辺にある*括弧の内側で*量化されているということです。
`run`に渡したどんな動作でも、*任意の領域*`r`が何であれ動作するということを意味しています。

しかし、ひとたび参照領域が`new`によって作成されると、その領域の型は既に固定されており、`run`によって限定されたコードの外側で参照領域を使おうとしても型エラーになるでしょう。
`run`が安全に`ST`作用を除去でき、`simulate`を純粋関数にできるのはこれが理由なのです。

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

そうして、参照領域はそのスコープから逃れられないことと、安全に`ref`を`var`に変換できることにコンパイラが気付きます。
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

> なお、この結果として得られたJavaScriptは最適化の余地があります。
> 詳細は[こちらの課題](https://github.com/purescript-contrib/purescript-book/issues/121)を参照してください。
> 上記の抜粋はそちらの課題が解決されたら更新されるでしょう。

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

局所的な変更可能状態を扱うとき、`ST`作用は短いJavaScriptを生成する良い方法となります。
作用を持つ繰り返しを生成する`for`、`foreach`、`while`のような動作を一緒に使うときは特にそうです。

## 演習

1. （普通）`safeDivide`関数を書き直し、もし分母がゼロなら`throwException`を使って文言`"div
   zero"`の例外を投げるようにしたものを`exceptionDivide`としてください。
1. （普通）関数`estimatePi :: Int -> Number`を書いてください。
   この関数は`n`項[Gregory
   Series](https://mathworld.wolfram.com/GregorySeries.html)を使って`pi`の近似を計算するものです。
   *手掛かり*：解答は上記の`simulate`の定義に倣うことができます。
   また`Data.Int`の`toNumber :: Int ->
   Number`を使って、`Int`を`Number`に変換する必要があるかもしれません。
1. （普通）`n`番目のフィボナッチ数を計算する関数`fibonacci :: Int -> Int`を書いてください。
   `ST`を使って前2つのフィボナッチ数の値を把握します。
   PSCiを使い、`ST`に基づく新しい実装の実行速度を第5章の再帰による実装と比較してください。

## DOM作用

この章の最後の節では、`Effect`モナドでの作用についてこれまで学んだことを、実際のDOM操作の問題に応用します。

DOMを直接扱ったり、オープンソースのDOMライブラリを扱ったりするPureScriptパッケージが沢山あります。
例えば以下です。

- [`web-dom`](https://github.com/purescript-web/purescript-web-dom)はW3CのDOM規格に向けた型定義と低水準インターフェース実装を提供します。
- [`web-html`](https://github.com/purescript-web/purescript-web-html)はW3CのHTML5規格に向けた型定義と低水準インターフェース実装を提供します。
- [`jquery`](http://github.com/paf31/purescript-jquery)は[jQuery](http://jquery.org)ライブラリのバインディングの集まりです。

上記のライブラリを土台に抽象化を進めたPureScriptライブラリもあります。
以下のようなものです。

- [`thermite`](https://github.com/paf31/purescript-thermite)は[`react`](https://github.com/purescript-contrib/purescript-react)を土台に構築されています。
- [`react-basic-hooks`](https://github.com/megamaddu/purescript-react-basic-hooks)は[`react-basic`](https://github.com/lumihq/purescript-react-basic)を土台に構築されています。
- [`halogen`](https://github.com/purescript-halogen/purescript-halogen)は独自の仮想DOMライブラリを土台とする型安全な一揃いの抽象化を提供します。

この章では
`react-basic-hooks`ライブラリを使用し、住所簿アプリケーションにユーザーインターフェイスを追加しますが、興味のあるユーザは異なるアプローチで進めることをお勧めします。

## 住所録のユーザーインターフェース

`react-basic-hooks`ライブラリを使い、アプリケーションをReact*コンポーネント*として定義していきます。ReactコンポーネントはHTML要素を純粋なデータ構造としてコードで記述します。それからこのデータ構造は効率的にDOMへ描画されます。加えてコンポーネントはボタンクリックのようなイベントに応答できます。`react-basic-hooks`ライブラリは`Effect`モナドを使ってこれらのイベントの制御方法を記述します。

Reactライブラリの完全な入門はこの章の範囲をはるかに超えていますが、読者は必要に応じて説明書を参照することをお勧めします。
目的に応じて、Reactは `Effect`モナドの実用的な例を提供してくれます。

利用者が住所録に新しい項目を追加できるフォームを構築することにしましょう。
フォームには、様々なフィールド（姓、名、市町村、州など）のテキストボックス、及び検証エラーが表示される領域が含まれます。
テキストボックスに利用者がテキストを入力する度に、検証エラーが更新されます。

簡潔さを保つために、フォームは固定の形状とします。電話番号は種類（自宅、携帯電話、仕事、その他）ごとに別々のテキストボックスへ分けることにします。

`exercises/chapter8`ディレクトリから以下のコマンドでwebアプリを立ち上げることができます。

```shell
$ npm install
$ npx spago build
$ npx parcel src/index.html --open
```

もし`spago`や`parcel`のような開発ツールが大域的にインストールされていれば、`npx`の前置は省けるでしょう。
恐らく既に`spago`を`npm i -g spago`で大域的にインストールしていますし、`parcel`についても同じことができるでしょう。

`parcel`は「住所録」アプリのブラウザ窓を立ち上げます。
`parcel`の端末を開いたままにし、他の端末で`spago`で再構築すると、最新の編集を含むページが自動的に再読み込みされるでしょう。
また、[`purs
ide`](https://github.com/purescript/purescript/tree/master/psc-ide)に対応していたり[`pscid`](https://github.com/kRITZCREEK/pscid)を走らせていたりする[エディタ](https://github.com/purescript/documentation/blob/master/ecosystem/Editor-and-tool-support.md#editors)を使っていれば、ファイルを保存したときに自動的にページが再構築される（そして自動的にページが再読み込みされる）ように設定できます。

この住所録アプリでフォームフィールドにいろいろな値を入力すると、ページ上で出力された検証エラーが見られます。

動作の仕組みを散策しましょう。

`src/index.html`ファイルは最小限です。

```html
{{#include ../exercises/chapter8/src/index.html}}
```

`<script`の行にJavaScriptの入口が含まれており、`index.js`にはこの実質1行だけが含まれています。

```js
{{#include ../exercises/chapter8/src/index.js}}
```

`module Main` (`src/main.purs`) の`main`関数と等価な、生成したJavaScriptを呼び出しています。
`spago build`は生成された全てのJavaScriptを`output`ディレクトリに置くことを思い出してください。

`main`関数はDOMとHTML APIを使い、`index.html`に定義した`container`要素の中に住所録コンポーネントを描画します。

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

あるいは更なる統合さえできます。

```hs
ctr <- getElementById "container" <<< toNonElementParentNode =<< document =<< window
-- or, equivalently:
ctr <- window >>= document >>= toNonElementParentNode >>> getElementById "container"
```

途中の`w`や`doc`変数が読みやすさの助けになるかは主観的な好みの問題です。

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
`String`（任意のコンポーネント名）、`props`を描画された`JSX`に変換する方法を記述する関数を取り、そして`Effect`に包まれた`ReactComponent`を返します。

propsからJSXへの関数は単にこうです。

```hs
\props -> pure $ D.text "Hi! I'm an address book"
```

`props`は無視されており、`D.text`は`JSX`を返し、そして`pure`は描画されたJSXに持ち上げます。
これで`component`には`ReactComponent`を生成するのに必要な全てがあります。

次に、完全な住所録コンポーネントにある幾つかの複雑な事柄を調べていきます。

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

なお、複数回`useState`を呼び出すことで、コンポーネントの状態を複数の状態の部品に分解することが自在にできます。
例えば`Person`の各レコードフィールドについて分離した状態の部品を使って、このアプリを書き直すことができるでしょう。
しかしこの場合にそうすると僅かに利便性を損なうアーキテクチャになってしまいます。

他の例では`Tuple`用の`/\`中置演算子に出喰わすかもしれません。
これは先の行と等しいものです。

```hs
firstName /\ setFirstName <- useState p.firstName
```

`useState`は、既定の初期値を取って現在の値と値を更新する方法を取ります。
`useState`の型を確認すれば型`person`と`setPerson`についてより深い洞察が得られます。

```hs
useState ::
  forall state.
  state ->
  Hook (UseState state) (Tuple state ((state -> state) -> Effect Unit))
```

結果の値の梱包`Hook (UseState
state)`は取り去ることができますが、それは`useState`が`R.do`ブロックの中で呼ばれているからです。
`R.do`は後で詳述します。

さてこれで以下のシグネチャを観察できます。

```hs
person :: state
setPerson :: (state -> state) -> Effect Unit
```

`state`の限定された型は初期の既定値によって決定されます。
これは`examplePerson`の型なのでこの場合は`Person` `Record`です。

`person`は各再描画の時点で現在の状態にアクセスする方法です。

`setPerson`は状態を更新する方法です。
単に現在の状態を新しい状態に変形する方法を記述する関数を提供します。
`state`の型が偶然`Record`のときは、レコード更新構文がこれにぴったり合います。
例えば以下。

```hs
setPerson (\currentPerson -> currentPerson {firstName = "NewName"})

```

あるいは短かく以下です。

```hs
setPerson _ {firstName = "NewName"}
```

`Record`でない状態もまた、この更新パターンに従います。
ベストプラクティスについて、より詳しいことは[この手引き](https://github.com/megamaddu/purescript-react-basic-hooks/pull/24#issuecomment-620300541)を参照してください。

`useState`が`R.do`ブロックの中で使われていることを思い出しましょう。
`R.do`は`do`の特別なreactフックの派生です。
`R.`の前置はこれが`React.Basic.Hooks`から来たものとして「限定する」もので、`R.do`ブロックの中でフック互換版の`bind`を使うことを意味しています。
これは「限定されたdo」として知られています。
`Hook (UseState state)`の梱包を無視し、内部の値の`Tuple`と変数に束縛してくれます。

他の状態管理戦略として挙げられるのは`useReducer`ですが、それはこの章の範疇外です。

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
このJSXは単一のHTML要素を作るHTMLタグ（例：`div`、`form`、`h3`、`li`、`ul`、`label`、`input`）に対応する関数を適用することで作られるのが普通です。
これらのHTML要素はそれ自体がReactコンポーネントであり、JSXに変換されます。
通常これらの関数にはそれぞれ3つの種類があります。

- `div_`: 子要素の配列を受け付けます。
  既定の属性を使います。
- `div`: 属性の`Record`を受け付けます。
  子要素の配列をこのレコードの`children`フィールドに渡すことができます。
- `div'`: `div`と同じですが、`JSX`に変換する前に`ReactComponent`を返します。

検証エラーをフォームの一番上に（もしあれば）表示するため、`Errors`構造体をJSXの配列に変える`renderValidationErrors`補助関数を作ります。この配列はフォームの残り部分の手前に付けます。

```hs
{{#include ../exercises/chapter8/src/Main.purs:renderValidationErrors}}
```

なお、ここでは単に通常のデータ構造体を操作しているので、`map`のような関数を使ってもっと面白い要素を構築できます。

```hs
children: [ D.ul_ (map renderError xs)]
```

`className`プロパティを使ってCSSスタイルのクラスを定義します。
このプロジェクトでは[Bootstrap](https://getbootstrap.com/)の`stylesheet`を使っており、これは`index.html`でインポートされています。
例えばフォーム中のアイテムは`row`として配置されてほしいですし、検証エラーは`alert-danger`の装飾で強調されていてほしいです。

```hs
className: "alert alert-danger row"
```

2番目の補助関数は `formField`です。
これは、単一フォームフィールドのテキスト入力を作ります。

```hs
{{#include ../exercises/chapter8/src/Main.purs:formField}}
```

`input`を置いて`label`の中に`text`を表示すると、スクリーンリーダーのアクセシビリティの助けになります。

`onChange`属性があれば利用者の入力に応答する方法を記述できます。`handler`関数を使いますが、これは以下の型を持ちます。

```hs
handler :: forall a. EventFn SyntheticEvent a -> (a -> Effect Unit) -> EventHandler
```

`handler`への最初の引数には`targetValue`を使いますが、これはHTMLの`input`要素中のテキストの値を提供します。
この場合は型変数`a`が`Maybe String`で、`handler`が期待するシグネチャに合致しています。

```hs
targetValue :: EventFn SyntheticEvent (Maybe String)
```

JavaScriptでは`input`要素の`onChange`イベントには`String`値が伴います。
しかし、JavaScriptの文字列はnullになり得るので、安全のために`Maybe`が使われています。

したがって`(a -> Effect Unit)`の`handler`への2つ目の引数は、このシグネチャを持ちます。

```hs
Maybe String -> Effect Unit
```

この関数は`Maybe String`値を求める作用に変換する方法を記述します。
この目的のために以下のように独自の`handleValue`関数を定義して`handler`を渡します。

```hs
onChange:
  let
    handleValue :: Maybe String -> Effect Unit
    handleValue (Just v) = setValue v
    handleValue Nothing  = pure unit
  in
    handler targetValue handleValue
```

`setValue`は`formField`の各呼び出しに与えた関数で、文字列を取り`setPerson`フックに適切なレコード更新呼び出しを実施します。

なお、`handleValue`は以下のようにも置き換えられます。

```hs
onChange: handler targetValue $ traverse_ setValue
```

`traverse_`の定義を調査して、両方の形式が確かに等価であることをご確認ください。

これでコンポーネント実装の基本を押さえました。
しかし、コンポーネントの仕組みを完全に理解するためには、この章に付随するソースをお読みください。

明らかに、このユーザーインターフェースには改善すべき点が沢山あります。
演習ではアプリケーションがより使いやすくなるような方法を追究していきます。

## 演習

以下の演習では`src/Main.purs`を変更してください。
これらの演習には単体試験はありません。

1. （簡単）このアプリケーションを変更し、職場の電話番号を入力できるテキストボックスを追加してください。
1. （普通）現時点でアプリケーションは検証エラーを単一の「pink-alert」背景に集めて表示させています。
   空行で分離することにより、各検証エラーにpink-alert背景を持たせるように変更してください。

    *手掛かり*：リスト中の検証エラーを表示するのに`ul`要素を使う代わりに、コードを変更し、各エラーに`alert`と`alert-danger`装飾を持つ`div`を作ってください。
1. （難しい、発展）このユーザーインターフェイスの問題の1つは、検証エラーがその発生源であるフォームフィールドの隣に表示されていないことです。
   コードを変更してこの問題を解決してください。

    *手掛かり*：検証器によって返されるエラーの型を、エラーの原因となっているフィールドを示すために拡張するべきです。
    以下の変更されたエラー型を使うと良いでしょう。

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

- `Monad`型クラスとdo記法との関係性を見ました。
- モナド則を導入し、do記法を使って書かれたコードを変換する方法を見ました。
- 異なる副作用を扱うコードを書く上で、モナドを抽象的に使う方法を見ました。
- モナドがアプリカティブ関手の一例であること、両者がどのように副作用のある計算を可能にするのかということ、そして2つの手法の違いを説明しました。
- ネイティブな作用の概念を定義し、`Effect`モナドを見ました。
  これはネイティブな副作用を扱うものでした。
- 乱数生成、例外、コンソール入出力、変更可能な状態、及びReactを使ったDOM操作といった、様々な作用を扱うために
  `Effect`モナドを使いました。

`Effect`モナドは実際のPureScriptコードにおける基本的なツールです。本書ではこのあとも、多くの場面で副作用を処理するために使っていきます。
