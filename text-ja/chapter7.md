# アプリカティブによる検証

## この章の目標

この章では重要な抽象化と新たに出会うことになります。
`Applicative`型クラスによって表現される*アプリカティブ関手*です。
名前が難しそうに思えても心配しないでください。
フォームデータの検証という実用的な例を使ってこの概念の動機付けをします。
アプリカティブ関手の技法があることにより、通常であれば大量の決まり文句の検証を伴うようなコードを、簡潔で宣言的なフォームの記述へと変えられます。

また、*巡回可能関手*を表現する`Traversable`という別の型クラスにも出会います。現実の問題への解決策からこの概念が自然に生じることがわかるでしょう。

この章のコードでは第3章に引き続き住所録を例とします。
今回は住所録のデータ型を拡張し、これらの型の値を検証する関数を書きます。
これらの関数は、例えばwebユーザインターフェースで使えることが分かります。
データ入力フォームの一部として、使用者へエラーを表示するのに使われます。

## プロジェクトの準備

この章のソースコードは、2つのファイル`src/Data/AddressBook.purs`、及び`src/Data/AddressBook/Validation.purs`で定義されています。

このプロジェクトには多くの依存関係がありますが、その大半は既に見てきたものです。
新しい依存関係は2つです。

- `control` - `Applicative`のような、型クラスを使用して制御フローを抽象化する関数が定義されています。
- `validation` - この章の主題である _アプリカティブによる検証_ のための関手が定義されています。

`Data.AddressBook`モジュールにはこのプロジェクトのデータ型とそれらの型に対する`Show`インスタンスが定義されています。
また、`Data.AddressBook.Validation`モジュールにはそれらの型の検証規則が含まれています。

## 関数適用の一般化

_アプリカティブ関手_ の概念を理解するために、以前扱った型構築子`Maybe`について考えてみましょう。

このモジュールのソースコードでは、次の型を持つ`address`関数が定義されています。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook.purs:address_anno}}
```

この関数は、通りの名前、市、州という3つの文字列から型`Address`の値を構築するために使います。

この関数は簡単に適用できますので、PSCiでどうなるか見てみましょう。

```text
> import Data.AddressBook

> address "123 Fake St." "Faketown" "CA"
{ street: "123 Fake St.", city: "Faketown", state: "CA" }
```

しかし、通り、市、州の3つ全てが必ずしも入力されないものとすると、3つの場合がそれぞれ省略可能であることを示すために`Maybe`型を使用したくなります。

考えられる場合としては、市が省略されている場合があるでしょう。
もし`address`関数を直接適用しようとすると、型検証器からエラーが表示されます。

```text
> import Data.Maybe
> address (Just "123 Fake St.") Nothing (Just "CA")

Could not match type

  Maybe String

with type

  String
```

勿論、これは期待通り型エラーになります。
`address`は`Maybe String`型の値ではなく、文字列を引数として取るためです。

しかし、もし`address`関数を「持ち上げる」ことができれば、`Maybe`型で示される省略可能な値を扱うことができるはずだという予想は理に適っています。実際それは可能で、`Control.Apply`で提供されている関数`lift3`が、まさに求めているものです。

```text
> import Control.Apply
> lift3 address (Just "123 Fake St.") Nothing (Just "CA")

Nothing
```

このとき、引数の1つ（市）が欠落していたので、結果は`Nothing`になります。
もし3つの引数全てに`Just`構築子を使ったものが与えられたら、結果は値を含むことになります。

```text
> lift3 address (Just "123 Fake St.") (Just "Faketown") (Just "CA")

Just ({ street: "123 Fake St.", city: "Faketown", state: "CA" })
```

`lift3`という関数の名前は、3引数の関数を持ち上げるために使えることを示しています。関数を持ち上げる同様の関数で、引数の数が異なるものが`Control.Apply`で定義されています。

## 任意個の引数を持つ関数の持ち上げ

これで、`lift2`や`lift3`のような関数を使えば、引数が2個や3個の関数を持ち上げることができるのはわかりました。
でも、これを任意個の引数の関数へと一般化できるのでしょうか。

`lift3`の型を見てみるとわかりやすいでしょう。

```text
> :type lift3
forall (a :: Type) (b :: Type) (c :: Type) (d :: Type) (f :: Type -> Type). Apply f => (a -> b -> c -> d) -> f a -> f b -> f c -> f d
```

上の`Maybe`の例では型構築子`f`は`Maybe`ですから、`lift3`は次のように特殊化されます。

```haskell
forall a b c d. (a -> b -> c -> d) -> Maybe a -> Maybe b -> Maybe c -> Maybe d
```

この型で書かれているのは、3引数の任意の関数を取り、その関数を引数と返り値が`Maybe`で包まれた新しい関数へと持ち上げられる、ということです。

勿論、どんな型構築子`f`についても持ち上げができるわけではないのですが、それでは`Maybe`型を持ち上げができるようにしているものは何なのでしょうか。
さて、先ほどの型の特殊化では、`f`に対する型クラス制約から`Apply`型クラスを取り除いていました。
`Apply`はPreludeで次のように定義されています。

```haskell
class Functor f where
  map :: forall a b. (a -> b) -> f a -> f b

class Functor f <= Apply f where
  apply :: forall a b. f (a -> b) -> f a -> f b
```

`Apply`型クラスは`Functor`の下位クラスであり、追加の関数`apply`を定義しています。`<$>`が`map`の別名として定義されているように、`Prelude`モジュールでは`<*>`を`apply`の別名として定義しています。これから見ていきますが、これら2つの演算子はよく一緒に使われます。

なお、この[`apply`](https://pursuit.purescript.org/packages/purescript-prelude/docs/Control.Apply#v:apply)は`Data.Function`の[`apply`](https://pursuit.purescript.org/packages/purescript-prelude/docs/Data.Function#v:apply)（中置で`$`）とは異なります。
幸いにも後者はほぼ常に中置記法として使われるので、名前の衝突については心配ご無用です。

`apply`の型は`map`の型と実によく似ています。
`map`と`apply`の違いは、`map`がただの関数を引数に取るのに対し、`apply`の最初の引数は型構築子`f`で包まれているという点です。
これをどのように使うのかはこれからすぐに見ていきますが、その前にまず`Maybe`型について`Apply`型クラスをどう実装するのかを見ていきましょう。

```haskell
instance Functor Maybe where
  map f (Just a) = Just (f a)
  map f Nothing  = Nothing

instance Apply Maybe where
  apply (Just f) (Just x) = Just (f x)
  apply _        _        = Nothing
```

この型クラスのインスタンスで書かれているのは、任意の省略可能な値に省略可能な関数を適用でき、その両方が定義されている時に限り結果も定義される、ということです。

それでは、`map`と`apply`を一緒に使い、引数が任意個の関数を持ち上げる方法を見ていきましょう。

1引数の関数については、`map`をそのまま使うだけです。

2引数関数については、型`a -> b -> c`のカリー化された関数`g`があるとします。これは型`a -> (b -> c)`と同じですから、`Functor`インスタンス付きのあらゆる型構築子`f`について、`map`を`f`に適用すると型`f a -> f (b -> c)`の新たな関数を得ることになります。持ち上げられた（型`f a`の）最初の引数にその関数を部分適用すると、型`f (b -> c)`の新たな包まれた関数が得られます。`f`に`Apply`インスタンスもあるなら、そこから、2番目の持ち上げられた（型`f b`の）引数へ`apply`を適用でき、型`f c`の最終的な値を得ます。

纏めると、`x :: f a`と`y :: f b`があるとき、式`(g <$> x) <*> y`の型は`f c`になります（この式は`apply (map g x)  y`と同じ意味だということを思い出しましょう）。Preludeで定義された優先順位の規則に従うと、`g <$> x <*> y`というように括弧を外すことができます。

一般的には、最初の引数に`<$>`を使い、残りの引数に対しては`<*>`を使います。`lift3`で説明すると次のようになります。

```haskell
lift3 :: forall a b c d f
       . Apply f
      => (a -> b -> c -> d)
      -> f a
      -> f b
      -> f c
      -> f d
lift3 f x y z = f <$> x <*> y <*> z
```

> この式に関する型の検証は、読者への演習として残しておきます。

例として、`<$>`と`<*>`をそのまま使うと、`Maybe`上に`address`関数を持ち上げることができます。

```text
> address <$> Just "123 Fake St." <*> Just "Faketown" <*> Just "CA"
Just ({ street: "123 Fake St.", city: "Faketown", state: "CA" })

> address <$> Just "123 Fake St." <*> Nothing <*> Just "CA"
Nothing
```

同様にして、引数が異なる他のいろいろな関数を`Maybe`上に持ち上げてみてください。

この代わりに、お馴染の*do記法*に似た見た目の*アプリカティブdo記法*が同じ目的で使えます。
以下では`lift3`に*アプリカティブdo記法*を使っています。
なお、`ado`が`do`の代わりに使われており、生み出された値を示すために最後の行で`in`が使われています。

```haskell
lift3 :: forall a b c d f
       . Apply f
      => (a -> b -> c -> d)
      -> f a
      -> f b
      -> f c
      -> f d
lift3 f x y z = ado
  a <- x
  b <- y
  c <- z
  in f a b c
```

## アプリカティブ型クラス

関連する`Applicative`という型クラスが存在しており、次のように定義されています。

```haskell
class Apply f <= Applicative f where
  pure :: forall a. a -> f a
```

`Applicative`は`Apply`の下位クラスであり、`pure`関数が定義されています。
`pure`は値を取り、その型の型構築子`f`で包まれた値を返します。

`Maybe`についての`Applicative`インスタンスは次のようになります。

```haskell
instance Applicative Maybe where
  pure x = Just x
```

アプリカティブ関手は関数を持ち上げることを可能にする関手だと考えるとすると、`pure`は引数のない関数の持ち上げだというように考えられます。

## アプリカティブに対する直感的理解

PureScriptの関数は純粋であり、副作用は持っていません。Applicative関手は、関手`f`によって表現されるある種の副作用を提供するような、より大きな「プログラミング言語」を扱えるようにします。

例えば関手`Maybe`は欠けている可能性がある値の副作用を表現しています。
その他の例としては、型`err`のエラーの可能性の副作用を表す`Either err`や、大域的な構成を読み取る副作用を表すArrow関手 (arrow functor) `r ->`があります。
ここでは`Maybe`関手についてのみ考えることにします。

もし関手`f`が作用を持つ、より大きなプログラミング言語を表すとすると、`Apply`と`Applicative`インスタンスは小さなプログラミング言語
(PureScript) から新しい大きな言語へと値や関数を持ち上げることを可能にします。

`pure`は純粋な（副作用がない）値をより大きな言語へと持ち上げますし、関数については上で述べた通り`map`と`apply`を使えます。

ここで疑問が生まれます。
もしPureScriptの関数と値を新たな言語へ埋め込むのに`Applicative`が使えるなら、どうやって新たな言語は大きくなっているというのでしょうか。
この答えは関手`f`に依存します。
もしなんらかの`x`について`pure x`で表せないような型`f
a`の式を見つけたなら、その式はそのより大きな言語だけに存在する項を表しているということです。

`f`が`Maybe`のときは、式`Nothing`がその例になっています。
どんな`x`があっても`Nothing`を`pure x`というように書くことはできません。
したがって、PureScriptは値の欠落を表す新しい項`Nothing`を含むように拡大されたと考えることができます。

## もっと作用を

様々な`Applicative`関手へと関数を持ち上げる例をもっと見ていきましょう。

以下は、PSCiで定義された3つの名前を結合して完全な名前を作る簡単な関数の例です。

```text
> import Prelude

> fullName first middle last = last <> ", " <> first <> " " <> middle

> fullName "Phillip" "A" "Freeman"
Freeman, Phillip A
```

この関数が、クエリ引数として与えられた3つの引数を持つ、（とっても簡単な）webサービスの実装を形成しているとしましょう。
使用者が3つの各引数を与えたことを確かめたいので、引数が存在するかどうかを表す`Maybe`型を使うことになるでしょう。
`fullName`を`Maybe`の上へ持ち上げると、欠けている引数を検査するwebサービスの実装を作成できます。

```text
> import Data.Maybe

> fullName <$> Just "Phillip" <*> Just "A" <*> Just "Freeman"
Just ("Freeman, Phillip A")

> fullName <$> Just "Phillip" <*> Nothing <*> Just "Freeman"
Nothing
```

または*アプリカティブdo*で次のようにします。

```text
> import Data.Maybe

> :paste…
… ado
…   f <- Just "Phillip"
…   m <- Just "A"
…   l <- Just "Freeman"
…   in fullName f m l
… ^D
(Just "Freeman, Phillip A")

… ado
…   f <- Just "Phillip"
…   m <- Nothing
…   l <- Just "Freeman"
…   in fullName f m l
… ^D
Nothing
```

この持ち上げた関数は、引数の何れかが`Nothing`なら`Nothing`を返すことに注意してください。

引数が不正のときにwebサービスからエラー応答を送り返せるのは良いことです。
しかし、どのフィールドが不正確なのかを応答で示せると、もっと良くなるでしょう。

`Meybe`上へ持ち上げる代わりに`Either String`上へ持ち上げるようにすると、エラー文言を返せるようになります。
まずは`Either String`を使い、省略可能な入力からエラーを発信できる計算に変換する演算子を書きましょう。

```text
> import Data.Either
> :paste
… withError Nothing  err = Left err
… withError (Just a) _   = Right a
… ^D
```

*補足*：`Either err`アプリカティブ関手において、`Left`構築子は失敗を表しており、`Right`構築子は成功を表しています。

これで`Either String`上へ持ち上げることで、それぞれの引数について適切なエラー文言を提供できるようになります。

```text
> :paste
… fullNameEither first middle last =
…   fullName <$> (first  `withError` "First name was missing")
…            <*> (middle `withError` "Middle name was missing")
…            <*> (last   `withError` "Last name was missing")
… ^D
```

または*アプリカティブdo*で次のようにします。

```text
> :paste
… fullNameEither first middle last = ado
…  f <- first  `withError` "First name was missing"
…  m <- middle `withError` "Middle name was missing"
…  l <- last   `withError` "Last name was missing"
…  in fullName f m l
… ^D

> :type fullNameEither
Maybe String -> Maybe String -> Maybe String -> Either String String
```

これでこの関数は`Maybe`を使う3つの省略可能な引数を取り、`String`のエラー文言か`String`の結果のどちらかを返します。

いろいろな入力でこの関数を試してみましょう。

```text
> fullNameEither (Just "Phillip") (Just "A") (Just "Freeman")
(Right "Freeman, Phillip A")

> fullNameEither (Just "Phillip") Nothing (Just "Freeman")
(Left "Middle name was missing")

> fullNameEither (Just "Phillip") (Just "A") Nothing
(Left "Last name was missing")
```

このとき、全てのフィールドが与えられば成功の結果が表示され、そうでなければ省略されたフィールドのうち最初のものに対応するエラー文言が表示されます。
しかし、もし複数の入力が省略されているとき、最初のエラーしか見られません。

```text
> fullNameEither Nothing Nothing Nothing
(Left "First name was missing")
```

これでも充分なときもありますが、エラー時に*全ての*省略されたフィールドの一覧がほしいときは、`Either
String`よりも強力なものが必要です。この章の後半で解決策を見ていきます。

## 作用の結合

抽象的にアプリカティブ関手を扱う例として、この節ではアプリカティブ関手`f`によって表現された副作用を一般的に組み合わせる関数を書く方法を示します。

これはどういう意味でしょうか。
何らかの`a`について型`f a`で包まれた引数のリストがあるとしましょう。
それは型`List (f a)`のリストがあるということです。
直感的には、これは`f`によって追跡される副作用を持つ、返り値の型が`a`の計算のリストを表しています。
これらの計算の全てを順番に実行できれば、`List a`型の結果のリストを得るでしょう。
しかし、まだ`f`によって追跡される副作用が残ります。
つまり、元のリストの中の作用を「結合する」ことにより、型`List (f a)`の何かを型`f (List a)`の何かへと変換できると考えられます。

任意の固定長リストの長さ`n`について、`n`引数からその引数を要素に持つ長さ`n`のリストを構築する関数が存在します。
例えばもし`n`が`3`なら、関数は`\x y z -> x : y : z : Nil`です。
この関数は型`a -> a -> a -> List a`を持ちます。
`Applicative`インスタンスを使うと、この関数を`f`の上へ持ち上げられ、関数型`f a -> f a -> f a -> f (List a)`が得られます。
しかし、いかなる`n`についてもこれが可能なので、いかなる引数の*リスト*についても同じように持ち上げられることが確かめられます。

したがって、次のような関数を書くことができるはずです。

```haskell
combineList :: forall f a. Applicative f => List (f a) -> f (List a)
```

この関数は副作用を持つかもしれない引数のリストを取り、それぞれの副作用を適用することで、`f`に包まれた単一のリストを返します。

この関数を書くためには、引数のリストの長さについて考えます。
リストが空の場合はどんな作用も実行する必要がありませんから、`pure`を使用して単に空のリストを返すことができます。

```haskell
combineList Nil = pure Nil
```

実際のところ、これが唯一できることです。

入力のリストが空でないならば、型`f a`の包まれた引数である先頭要素と、型`List (f a)`の尾鰭について考えます。
また、再帰的にリストの残りを結合すると、型`f (List a)`の結果が得られます。
それから`<$>`と`<*>`を使うと、`Cons`構築子を先頭と新しい尾鰭の上に持ち上げることができます。

```haskell
combineList (Cons x xs) = Cons <$> x <*> combineList xs
```

繰り返しになりますが、これは与えられた型に基づいている唯一の妥当な実装です。

`Maybe`型構築子を例にとって、PSCiでこの関数を試してみましょう。

```text
> import Data.List
> import Data.Maybe

> combineList (fromFoldable [Just 1, Just 2, Just 3])
(Just (Cons 1 (Cons 2 (Cons 3 Nil))))

> combineList (fromFoldable [Just 1, Nothing, Just 2])
Nothing
```

`Meybe`へ特殊化すると、リストの全ての要素が`Just`であるときに限りこの関数は`Just`を返しますし、そうでなければ`Nothing`を返します。
これは省略可能な値に対応する、より大きな言語に取り組む上での直感と一貫しています。
省略可能な結果を生む計算のリストは、全ての計算が結果を持っているならばそれ自身の結果のみを持つのです。

ところが`combineList`関数はどんな`Applicative`に対しても機能するのです。
`Either err`を使ってエラーを発信する可能性を持たせたり、`r ->`を使って大域的な構成を読み取る計算を組み合わせるためにも使えます。

`combineList`関数については、後ほど`Traversable`関手について考えるときに再訪します。

## 演習

 1. （普通）数値演算子`+`、`-`、`*`、`/`の別のバージョンを書いてください。
    ただし省略可能な引数（つまり`Maybe`に包まれた引数）を扱って`Maybe`に包まれた値を返します。
    これらの関数には`addMaybe`、`subMaybe`、`mulMaybe`、`divMaybe`と名前を付けてください。
    *手掛かり*：`lift2`を使ってください。
 1. （普通）上の演習を（`Maybe`だけでなく）全ての`Apply`型で動くように拡張してください。
    これらの新しい関数には`addApply`、`subApply`、`mulApply`、`divApply`と名前を付けます。
 1. （難しい）型`forall a f. Applicative f => Maybe (f a) -> f (Maybe
    a)`を持つ関数`combineMaybe`を書いてください。
    この関数は副作用を持つ省略可能な計算を取り、省略可能な結果を持つ副作用のある計算を返します。

## アプリカティブによる検証

この章のソースコードでは住所録アプリケーションで使うであろう幾つかのデータ型が定義されています。
詳細はここでは割愛しますが、`Data.AddressBook`モジュールからエクスポートされる鍵となる関数は次のような型を持ちます。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook.purs:address_anno}}

{{#include ../exercises/chapter7/src/Data/AddressBook.purs:phoneNumber_anno}}

{{#include ../exercises/chapter7/src/Data/AddressBook.purs:person_anno}}
```

ここで、`PhoneType`は次のような代数的データ型として定義されています。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook.purs:PhoneType}}
```

これらの関数は住所録の項目を表す`Person`を構築できます。
例えば、`Data.AddressBook`では以下の値が定義されています。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook.purs:examplePerson}}
```

PSCiでこれらの値を試してみましょう（結果は整形されています）。

```text
> import Data.AddressBook

> examplePerson
{ firstName: "John"
, lastName: "Smith"
, homeAddress:
    { street: "123 Fake St."
    , city: "FakeTown"
    , state: "CA"
    }
, phones:
    [ { type: HomePhone
      , number: "555-555-5555"
      }
    , { type: CellPhone
      , number: "555-555-0000"
      }
    ]
}
```

前の章では型`Person`のデータ構造を検証する上で`Either
String`関手の使い方を見ました。例えば、データ構造の2つの名前を検証する関数が与えられたとき、データ構造全体を次のように検証できます。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:nonEmpty1}}

{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validatePerson1}}
```

または*アプリカティブdo*で次のようにします。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validatePerson1Ado}}
```

最初の2行では`nonEmpty1`関数を使って空文字列でないことを検証しています。
もし入力が空なら`nonEmpty1`は`Left`構築子で示されるエラーを返します。
そうでなければ`Right`構築子で包まれた値を返します。

最後の2行では何の検証も実行せず、単に`address`フィールドと`phones`フィールドを残りの引数として`person`関数へと提供しています。

この関数はPSCiでうまく動作するように見えますが、以前見たような制限があります。

```text
> validatePerson $ person "" "" (address "" "" "") []
(Left "Field cannot be empty")
```

`Either String`アプリカティブ関手は最初に遭遇したエラーだけを返します。
仮にこの入力だったとすると、2つのエラーが分かったほうが良いでしょう。
1つは名前の不足で、2つ目は姓の不足です。

`validation`ライブラリでは別のアプリカティブ関手も提供されています。
これは`V`という名前で、何らかの*半群*でエラーを返せます。
例えば`V (Array String)`を使うと、新しいエラーを配列の最後に連結していき、`String`の配列をエラーとして返せます。

`Data.Validation`モジュールは`Data.AddressBook`モジュールのデータ構造を検証するために`V (Array
String)`アプリカティブ関手を使っています。

`Data.AddressBook.Validation`モジュールから取材した検証器の例は次のようになります。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:Errors}}

{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:nonEmpty}}

{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:lengthIs}}

{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validateAddress}}
```

または*アプリカティブdo*で次のようにします。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validateAddressAdo}}
```

`validateAddress`は`Address`の構造を検証します。
`street`と`city`が空でないかどうか、`state`の文字列の長さが2であるかどうかを検証します。

`nonEmpty`と`lengthIs`の2つの検証関数が何れも、`Data.Validation`モジュールで提供されている`invalid`関数をエラーを示すために使っているところに注目してください。
`Array String`半群を扱っているので、`invalid`は引数として文字列の配列を取ります。

PSCiでこの関数を試しましょう。

```text
> import Data.AddressBook
> import Data.AddressBook.Validation

> validateAddress $ address "" "" ""
(invalid [ "Field 'Street' cannot be empty"
         , "Field 'City' cannot be empty"
         , "Field 'State' must have length 2"
         ])

> validateAddress $ address "" "" "CA"
(invalid [ "Field 'Street' cannot be empty"
         , "Field 'City' cannot be empty"
         ])
```

これで、全ての検証エラーの配列を受け取ることができるようになりました。

## 正規表現検証器

`validatePhoneNumber`関数では引数の形式を検証するために正規表現を使っています。重要なのは`matches`検証関数で、この関数は`Data.String.Regex`モジュールで定義されている`Regex`を使って入力を検証しています。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:matches}}
```

繰り返しになりますが、`pure`は常に成功する検証を表しており、エラーの配列の伝達には`invalid`が使われています。

これまでと同様に、`validatePhoneNumber`は`matches`関数から構築されています。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validatePhoneNumber}}
```

または*アプリカティブdo*で次のようにします。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validatePhoneNumberAdo}}
```

また、PSCiでいろいろな有効な入力や無効な入力に対して、この検証器を実行してみてください。

```text
> validatePhoneNumber $ phoneNumber HomePhone "555-555-5555"
pure ({ type: HomePhone, number: "555-555-5555" })

> validatePhoneNumber $ phoneNumber HomePhone "555.555.5555"
invalid (["Field 'Number' did not match the required format"])
```

## 演習

 1. （簡単）正規表現`stateRegex :: Regex`を書いて文字列が2文字のアルファベットであることを確かめてください。
    *手掛かり*：`phoneNumberRegex`のソースコードを参照してみましょう。
 1. （普通）文字列全体が空白でないことを検査する正規表現`nonEmptyRegex :: Regex`を書いてください。
    *手掛かり*：この正規表現を開発するのに手助けが必要なら、[RegExr](https://regexr.com)をご確認ください。
    素晴しい早見表と対話的なお試し環境があります。
 1. （普通）`validateAddress`に似ていますが、上の`stateRegex`を使って`state`フィールドを検証し、`nonEmptyRegex`を使って`street`と`city`フィールドを検証する関数`validateAddressImproved`を書いてください。
    *手掛かり*：`matches`の用例については`validatePhoneNumber`のソースを見てください。

## 巡回可能関手

残った検証器は`validatePerson`です。
これはこれまで見てきた検証器と以下の新しい`validatePhoneNumbers`関数を組み合わせて`Person`全体を検証するものです。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validatePhoneNumbers}}

{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validatePerson}}
```

または*アプリカティブdo*で次のようにします。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validatePersonAdo}}
```

`validatePhoneNumbers`はこれまでに見たことのない新しい関数である`traverse`を使っています。

`traverse`は`Data.Traversable`モジュールの`Traversable`型クラスで定義されています。

```haskell
class (Functor t, Foldable t) <= Traversable t where
  traverse :: forall a b m. Applicative m => (a -> m b) -> t a -> m (t b)
  sequence :: forall a m. Applicative m => t (m a) -> m (t a)
```

`Traversable`は _巡回可能関手_
の型クラスを定義します。これらの関数の型は少し難しそうに見えるかもしれませんが、`validatePerson`は良いきっかけとなる例です。

全ての巡回可能関手は`Functor`と`Foldable`のどちらでもあります（*畳み込み可能関手*は畳み込み操作に対応する型構築子であったことを思い出してください。
畳み込みとは構造を1つの値へと簡約するものでした）。
それに加えて、巡回可能関手はその構造に依存した副作用の集まりを組み合わせられます。

複雑そうに聞こえるかもしれませんが、配列の場合に特殊化して簡単にした上で考えてみましょう。配列型構築子は`Traversable`であり、つまりは次のような関数が存在するということです。

```haskell
traverse :: forall a b m. Applicative m => (a -> m b) -> Array a -> m (Array b)
```

直感的にはこうです。
任意のアプリカティブ関手`m`と、型`a`の値を取って型`b`の値を返す（`f`で追跡される副作用を持つ）関数が与えられたとします。
このとき、その関数を型`Array a`の配列のそれぞれの要素に適用して型`Array
b`の（`f`で追跡される副作用を持つ）結果を得ることができます。

まだよくわからないでしょうか。それでは更に、`f`を上記の`V
Errors`アプリカティブ関手に特殊化して考えてみましょう。これで次の型を持つ関数が得られます。

```haskell
traverse :: forall a b. (a -> V Errors b) -> Array a -> V Errors (Array b)
```

この型シグネチャでは、型`a`についての検証関数`m`があれば、`traverse m`は型`Array
a`の配列についての検証関数であると書かれています。
ところがこれは正に`Person`データ構造体の`phones`フィールドを検証できるようにするのに必要なものです。
各要素が成功するかを検証する検証関数を作るために、`validatePhoneNumber`を`traverse`へ渡しています。

一般に、`traverse`はデータ構造の要素を1つずつ辿っていき、副作用を伴いつつ計算し、結果を累算します。

`Traversable`のもう1つの関数、`sequence`の型シグネチャには見覚えがあるかもしれません。

```haskell
sequence :: forall a m. Applicative m => t (m a) -> m (t a)
```

実際、先ほど書いた`combineList`関数は`Traversable`型クラスの`sequence`関数の特別な場合に過ぎません。
`t`を型構築子`List`だとすると、`combineList`関数の型が復元されます。

```haskell
combineList :: forall f a. Applicative f => List (f a) -> f (List a)
```

巡回可能関手はデータ構造走査の考え方を見据えたものです。
これにより作用のある計算の集合を集めてその作用を結合します。
実際、`sequence`と`traversable`は`Traversable`を定義する上でどちらも同じくらい重要です。
これらはお互いがお互いを利用して実装できます。
これについては興味ある読者への演習として残しておきます。

`Data.List`で与えられているリストの`Traversable`インスタンスは次の通り。

```haskell
instance Traversable List where
-- traverse :: forall a b m. Applicative m => (a -> m b) -> List a -> m (List b)
traverse _ Nil         = pure Nil
traverse f (Cons x xs) = Cons <$> f x <*> traverse f xs
```

（実際の定義は後にスタック安全性を向上するために変更されました。その変更についてより詳しくは[こちら](https://github.com/purescript/purescript-lists/pull/87)で読むことができます）

入力が空のリストのときには、`pure`を使って空のリストを返せます。
リストが空でないときは、関数`f`を使うと先頭の要素から型`f b`の計算を作成できます。
また、尾鰭に対して`traverse`を再帰的に呼び出せます。
最後に、アプリカティブ関手`m`まで`Cons`構築子を持ち上げて、2つの結果を組み合わせられます。

巡回可能関手の例はただの配列やリスト以外にもあります。
以前に見た`Maybe`型構築子も`Traversable`のインスタンスを持っています。
PSCiで試してみましょう。

```text
> import Data.Maybe
> import Data.Traversable
> import Data.AddressBook.Validation

> traverse (nonEmpty "Example") Nothing
pure (Nothing)

> traverse (nonEmpty "Example") (Just "")
invalid (["Field 'Example' cannot be empty"])

> traverse (nonEmpty "Example") (Just "Testing")
pure ((Just "Testing"))
```

これらの例では、`Nothing`の値の走査は検証なしで`Nothing`の値を返し、`Just
x`を走査すると`x`を検証するのに検証関数が使われるということを示しています。
要は、`traverse`は型`a`についての検証関数を取り、`Maybe
a`についての検証関数、つまり型`a`の省略可能な値についての検証関数を返すのです。

他の巡回可能関手には、任意の型`a`についての`Array a`、`Tuple a`、`Either a`が含まれます。
一般に、「容器」のようなほとんどのデータ型構築子は`Traversable`インスタンスを持っています。
一例として、演習には二分木の型の`Traversable`インスタンスを書くことが含まれます。

## 演習

 1. （簡単）`Eq`と`Show`インスタンスを以下の2分木データ構造に対して書いてください。

     ```haskell
     data Tree a = Leaf | Branch (Tree a) a (Tree a)
     ```

     これらのインスタンスを手作業で書くこともできますし、コンパイラに導出してもらうこともできることを前の章から思い起こしてください。

     `Show`の出力には多くの「正しい」書式の選択肢があります。
     この演習のテストでは以下の空白スタイルを期待しています。
     これは一般化されたshowの既定の書式と合致しているため、このインスタンスを手作業で書くつもりのときだけ、このことを念頭に置いておいてください。

     ```haskell
     (Branch (Branch Leaf 8 Leaf) 42 Leaf)
     ```

 1. （普通）`Traversable`インスタンスを`Tree a`に対して書いてください。
    これは副作用を左から右に結合するものです。
    *手掛かり*：`Traversable`に定義する必要のある追加のインスタンス依存関係が幾つかあります。

 1. （普通）行き掛け順に木を巡回する関数`traversePreOrder :: forall a m b. Applicative m => (a
    -> m b) -> Tree a -> m (Tree b)`を書いてください。
    つまり作用の実行は根左右と行われ、以前の通り掛け順の巡回の演習でしたような左根右ではありません。
    *手掛かり*：追加でインスタンスを定義する必要はありませんし、前に定義した関数は何も呼ぶ必要はありません。
    アプリカティブdo記法 (`ado`) はこの関数を書く最も簡単な方法です。

 1. （普通）木を帰り掛け順に巡回する関数`traversePostOrder`を書いてください。作用は左右根と実行されます。

 1. （普通）`homeAddress`フィールドが省略可能（`Maybe`を使用）な新しい版の`Person`型をつくってください。
    それからこの新しい`Person`を検証する新しい版の`validatePerson`（`validatePersonOptionalAddress`と改名します）を書いてください。
    *手掛かり*：`traverse`を使って型`Maybe a`のフィールドを検証してください。

 1. （難しい）`sequence`のように振る舞う関数`sequenceUsingTraverse`を書いてください。
    ただし`traverse`を使ってください。

 1. （難しい）`traverse`のように振る舞う関数`traverseUsingSequence`を書いてください。
    ただし`sequence`を使ってください。

## アプリカティブ関手による並列処理

これまでの議論では、アプリカティブ関手がどのように「副作用を結合」させるかを説明するときに、「結合」(combine) という単語を選びました。
しかし、これらの全ての例において、アプリカティブ関手は作用を「連鎖」(sequence) させる、というように言っても同じく妥当です。
巡回可能関手がデータ構造に従って作用を順番に結合させる`sequence`関数を提供していることと、この直感的理解とは一致するでしょう。

しかし一般には、アプリカティブ関手はこれよりももっと一般的です。
アプリカティブ関手の規則は、その計算の副作用にどんな順序付けも強制しません。
実際、並列に副作用を実行するアプリカティブ関手は妥当でしょう。

例えば`V`検証関手はエラーの*配列*を返しますが、その代わりに`Set`半群を選んだとしてもやはり正常に動き、このときどんな順序で各検証器を実行しても問題はありません。
データ構造に対して並列にこれの実行さえできるのです。

2つ目の例として、`parallel`パッケージは*並列計算*に対応する`Parallel`型クラスを提供します。
`Parallel`は関数`parallel`を提供しており、何らかの`Applicative`関手を使って入力の計算の結果を*並列に*計算します。

```haskell
f <$> parallel computation1
  <*> parallel computation2
```

この計算は`computation1`と`computation2`を非同期に使って値の計算を始めるでしょう。そして両方の結果の計算が終わった時に、関数`f`を使って1つの結果へと結合するでしょう。

この考え方の詳細は、本書の後半で _コールバック地獄_ の問題に対してアプリカティブ関手を応用するときに見ていきます。

アプリカティブ関手は並列に結合できる副作用を捉える自然な方法です。

## まとめ

この章では新しい考え方を沢山扱いました。

- *アプリカティブ関手*の概念を導入しました。
  これは、関数適用の概念から副作用の観念を捉えた型構築子へと一般化するものです。
- データ構造の検証という課題をアプリカティブ関手やその切り替えで解く方法を見てきました。
  単一のエラーの報告からデータ構造を横断する全てのエラーの報告へ変更できました。
- `Traversable`型クラスに出会いました。*巡回可能関手*の考え方を内包するものであり、要素が副作用を持つ値の結合に使うことができる容れ物でした。

アプリカティブ関手は多くの問題に対して優れた解決策を与える興味深い抽象化です。
本書を通じて何度も見ることになるでしょう。
今回の場合、アプリカティブ関手は宣言的な流儀で書く手段を提供していましたが、これにより検証器が*どうやって*検証を実施するかではなく、*何を*検証すべきなのかを定義できました。
一般にアプリカティブ関手が*領域特化言語*を設計する上で便利な道具になることを見ていきます。

次の章では、これに関連する考え方である*モナド*クラスを見て、住所録の例をブラウザで実行させられるように拡張しましょう。
