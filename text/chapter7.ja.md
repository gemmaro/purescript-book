# アプリカティブによる検証

## この章の目標

この章では、
`Applicative`型クラスによって表現される**アプリカティブ関手** (applicative functor)
という重要な抽象化と新たに出会うことになります。
名前が難しそうに思えても心配しないでください。
フォームデータの検証という実用的な例を使ってこの概念の動機付けをします。
アプリカティブ関手を使うと、
通常であれば大量の決まり文句を伴うようなコードを、
簡潔で宣言的な記述へと変えることができるようになります。

また、**巡回可能関手** (traversable functor) を表現する`Traversable`という別の型クラスにも出会います。
現実の問題への解決策からこの概念が自然に生じるということがわかるでしょう。

この章では第3章に引き続き住所録を例として扱います。
今回は住所録のデータ型を拡張し、
これらの型の値を検証する関数を書きます。
これらの関数は、例えばデータ入力フォームの一部で、
使用者へエラーを表示するウェブユーザインタフェースで使われると考えてください。

## プロジェクトの準備

この章のソースコードは、ふたつのファイル`src/Data/AddressBook.purs`
および`src/Data/AddressBook/Validation.purs`で定義されています。

このプロジェクトは多くの依存関係を持っていますが、
その大半はすでに見てきたものです。
新しい依存関係は2つです。

- `control` - `Applicative`のような、型クラスを使用して制御フローを抽象
              化する関数が定義されています。
- `validation` - この章の主題である **アプリカティブによる検証** のため
                 の関手が定義されています。

`Data.AddressBook`モジュールには、
このプロジェクトのデータ型とそれらの型に対する`Show`インスタンスが定義されており、
`Data.AddressBook.Validation`モジュールにはそれらの型の検証規則が含まれています。

## 関数適用の一般化

**アプリカティブ関手**の概念を理解するために、
以前扱った型構築子`Maybe`について考えてみましょう。

このモジュールのソースコードでは、
次のような型を持つ`address`関数が定義されています。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook.purs:address_anno}}
```

この関数は、通りの名前、市、州という３つの文字列から型`Address`の値を構築するために使います。

この関数は簡単に適用できますので、
PSCiでどうなるか見てみましょう。

```text
> import Data.AddressBook

> address "123 Fake St." "Faketown" "CA"
{ street: "123 Fake St.", city: "Faketown", state: "CA" }
```

しかし、通り、市、州の三つすべてが必ずしも入力されないものとすると、
三つの場合がそれぞれ省略可能であることを示すために`Maybe`型を使用したくなります。

考えられる場合としては、
市が省略されている場合があるでしょう。
もし`address`関数を直接適用しようとすると、
型検証器からエラーが表示されます。

```text
> import Data.Maybe
> address (Just "123 Fake St.") Nothing (Just "CA")

Could not match type

  Maybe String

with type

  String
```

`address`は`Maybe String`型ではなく文字列型の引数を取るので、
もちろんこれは期待通り型エラーになります。

しかし、もし`address`関数を「持ち上げる」ことができれば、
`Maybe`型で示される省略可能な値を扱うことができるはずだと期待することは理にかなっています。
実際にそれは可能で、
`Control.Apply`で提供されている関数`lift3`が、まさに求めているものです。

```text
> import Control.Apply
> lift3 address (Just "123 Fake St.") Nothing (Just "CA")

Nothing
```

このとき、引数のひとつ（市）が欠落していたので、
結果は`Nothing`になります。
もし3つの引数すべてが`Just`構築子を使って与えられれば、
結果は値を含むことになります。

```text
> lift3 address (Just "123 Fake St.") (Just "Faketown") (Just "CA")

Just ({ street: "123 Fake St.", city: "Faketown", state: "CA" })
```

`lift3`という関数の名前は、
3引数の関数を持ち上げるために使用できることを示しています。
関数を持ち上げる同様の関数で、
引数の数が異なるものが`Control.Apply`で定義されています。

## 任意個の引数を持つ関数の持ち上げ

これで、`lift2`や`lift3`のような関数を使えば、
引数が2個や3個の関数を持ち上げることができるのはわかりました。
でも、これを任意個の引数の関数へと一般化することはできるのでしょうか。

`lift3`の型を見てみるとわかりやすいでしょう。

```text
> :type lift3
forall a b c d f. Apply f => (a -> b -> c -> d) -> f a -> f b -> f c -> f d
```

上の`Maybe`の例では型構築子`f`は`Maybe`ですから、`lift3`は次のように特殊化されます。

```haskell
forall a b c d. (a -> b -> c -> d) -> Maybe a -> Maybe b -> Maybe c -> Maybe d
```

この型が言っているのは、
3引数の任意の関数を取り、
その関数を引数と返り値が`Maybe`で包まれた新しい関数へと持ち上げる、ということです。

もちろんどんな型構築子`f`についても持ち上げができるわけではないのですが、
それでは`Maybe`型を持ち上げができるようにしているものは何なのでしょうか。
さて、先ほどの型の特殊化では、
`f`に対する型クラス制約から`Apply`型クラスを取り除いていました。
`Apply`はPreludeで次のように定義されています。

```haskell
class Functor f where
  map :: forall a b. (a -> b) -> f a -> f b

class Functor f <= Apply f where
  apply :: forall a b. f (a -> b) -> f a -> f b
```

`Apply`型クラスは`Functor`の下位クラスであり、
追加の関数`apply`が定義しています。
`<$>`が`map`の別名として定義されているように、
`Prelude`モジュールで`<*>`を`apply`の別名として定義しています。
これから見ていきますが、これら2つの演算子はよく一緒に使われます。

なおこの[`apply`](https://pursuit.purescript.org/packages/purescript-prelude/docs/Control.Apply#v:apply)は`Data.Function`の[`apply`](https://pursuit.purescript.org/packages/purescript-prelude/docs/Data.Function#v:apply)（中置で`$`）とは異なります。
運良く後者はほぼ常に中置記法として使われるので、名前の衝突については心配ご無用です。

`apply`の型は`map`の型と実によく似ています。
`map`と`apply`の違いは、`map`がただの関数を引数に取るのに対し、
`apply`の最初の引数は型構築子`f`で包まれているという点です。
これをどのように使うのかはこれからすぐに見ていきますが、
その前にまず`Maybe`型について`Apply`型クラスをどう実装するのかを見ていきましょう。

```haskell
instance functorMaybe :: Functor Maybe where
  map f (Just a) = Just (f a)
  map f Nothing  = Nothing

instance applyMaybe :: Apply Maybe where
  apply (Just f) (Just x) = Just (f x)
  apply _        _        = Nothing
```

この型クラスのインスタンスが言っているのは、
任意のオプショナルな値にオプショナルな関数を適用することができ、
その両方が定義されている時に限り結果も定義される、ということです。

それでは、`map`と`apply`を一緒に使ってどうやって引数が任意個の関数を持ち上げるのかを見ていきましょう。

1引数の関数については、`map`をそのまま使うだけです。

2引数関数については型`a -> b -> c`のカリー化された関数`g`があるとします。
これは型`a -> (b -> c)`と同じですから、
`Functor`インスタンス付きのあらゆる型構築子`f`について、
`map`を`f`に適用すると型`f a -> f (b -> c)`の新たな関数を得ることになります。
持ち上げられた（型`f a`の）最初の引数にその関数を部分適用すると、
型`f (b -> c)`の新たな包まれた関数が得られます。
`f`に`Apply`インスタンスもあるならば、
そこから、2番目の持ち上げられた（型`f b`の）引数へ`apply`を適用することができ、
型`f c`の最終的な値を得ます。

まとめると、`x :: f a`と`y :: f b`があるとき、
式`(g <$> x) <*> y`の型は`f c`になります。
（この式は`apply (map g x)  y`と同じ意味だということを思い出しましょう。）
Preludeで定義された優先順位の規則に従うと、`g <$> x <*> y`というように括弧を外すことができます。

一般的にいえば、最初の引数に`<$>`を使い、
残りの引数に対しては`<*>`を使います。
`lift3`で説明すると次のようになります。

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

この式の型がちゃんと整合しているかの確認は、
読者への演習として残しておきます。

例として、`<$>`と`<*>`をそのまま使うと、
`Maybe`上に`address`関数を持ち上げることができます。

```text
> address <$> Just "123 Fake St." <*> Just "Faketown" <*> Just "CA"
Just ({ street: "123 Fake St.", city: "Faketown", state: "CA" })

> address <$> Just "123 Fake St." <*> Nothing <*> Just "CA"
Nothing
```

このように、引数が異なる他のいろいろな関数を`Maybe`上に持ち上げてみてください。

この代わりにお馴染の**do記法**に似た見た目の**アプリカティブdo記法**が同じ目的で使えます。
以下では`lift3`に**アプリカティブdo記法**を使っています。
なお`ado`が`do`の代わりに使われており、生み出された値を示すために最後の行で`in`が使われています。

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

`Applicative`は`Apply`の下位クラスであり、
`pure`関数が定義されています。
`pure`は値を取り、その型の型構築子`f`で包まれた値を返します。

`Maybe`についての`Applicative`インスタンスは次のようになります。

```haskell
instance applicativeMaybe :: Applicative Maybe where
  pure x = Just x
```

アプリカティブ関手は関数を持ち上げることを可能にする関手だと考えるとすると、
`pure`は引数のない関数の持ち上げだというように考えることができます。

## アプリカティブに対する直感的理解

PureScriptの関数は純粋であり、
副作用は持っていません。
Applicative関手は、
関手`f`によって表現されたある種の副作用を提供するような、
より大きな「プログラミング言語」を扱えるようにします。

たとえば、関手`Maybe`はオプショナルな値の副作用を表現しています。
その他の例としては、
型`err`のエラーの可能性の副作用を表す`Either err`や、
大域的な構成を読み取る副作用を表すArrow関手 (arrow functor) `r ->`があります。
ここでは`Maybe`関手についてだけを考えることにします。

もし関手`f`が作用を持つより大きなプログラミング言語を表すとすると、
`Apply`と`Applicative`インスタンスは小さなプログラミング言語 (PureScript) から
新しい大きな言語へと値や関数を持ち上げることを可能にします。

`pure`は純粋な（副作用がない）値をより大きな言語へと持ち上げますし、
関数については上で述べたとおり`map`と`apply`を使うことができます。

ここで疑問が生まれます。
もしPureScriptの関数と値を新たな言語へ埋め込むのに`Applicative`が使えるなら、
どうやって新たな言語は大きくなっているというのでしょうか。
この答えは関手`f`に依存します。
もしなんらかの`x`について`pure x`で表せないような型`f a`の式を見つけたなら、
その式はそのより大きな言語だけに存在する項を表しているということです。

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

この関数は、クエリパラメータとして与えられた3つの引数を持つ、
（とても簡単な！）ウェブサービスの実装であるとしましょう。
使用者が3つの引数すべてを与えたことを確かめたいので、
引数が存在するかどうかを表す`Maybe`型を使うことになるでしょう。
`fullName`を`Maybe`の上へ持ち上げると、
省略された引数を確認するウェブサービスを実装することができます。

```text
> import Data.Maybe

> fullName <$> Just "Phillip" <*> Just "A" <*> Just "Freeman"
Just ("Freeman, Phillip A")

> fullName <$> Just "Phillip" <*> Nothing <*> Just "Freeman"
Nothing
```

または**アプリカティブdo**で

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

この持ち上げた関数は、引数のいずれかが`Nothing`なら`Nothing`返すことに注意してください。

これで、もし引数が不正ならWebサービスからエラー応答を送信することができるので、なかなかいい感じです。しかし、どのフィールドが間違っていたのかを応答で表示できると、もっと良くなるでしょう。

`Meybe`上へ持ち上げる代わりに`Either String`上へ持ち上げるようにすると、
エラーメッセージを返すことができるようになります。
まずは`Either String`を使ってオプショナルな入力をエラーを発信できる計算に変換する演算子を書きましょう。

```text
> import Data.Either
> :paste
… withError Nothing  err = Left err
… withError (Just a) _   = Right a
… ^D
```

**注意**：`Either
err`Applicative関手において、`Left`構築子は失敗を表しており、`Right`構築子は成功を表しています。

これで`Either String`上へ持ち上げることで、それぞれの引数について適切なエラーメッセージを提供できるようになります。

```text
> :paste
… fullNameEither first middle last =
…   fullName <$> (first  `withError` "First name was missing")
…            <*> (middle `withError` "Middle name was missing")
…            <*> (last   `withError` "Last name was missing")
… ^D
```

または**アプリカティブdo**で

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

これでこの関数は`Maybe`の3つの省略可能な引数を取り、
`String`のエラーメッセージか`String`の結果のどちらかを返します。

いろいろな入力でこの関数を試してみましょう。

```text
> fullNameEither (Just "Phillip") (Just "A") (Just "Freeman")
(Right "Freeman, Phillip A")

> fullNameEither (Just "Phillip") Nothing (Just "Freeman")
(Left "Middle name was missing")

> fullNameEither (Just "Phillip") (Just "A") Nothing
(Left "Last name was missing")
```

このとき、すべてのフィールドが与えられば成功の結果が表示され、そうでなければ省略されたフィールドのうち最初のものに対応するエラーメッセージが表示されます。しかし、もし複数の入力が省略されているとき、最初のエラーしか見ることができません。

```text
> fullNameEither Nothing Nothing Nothing
(Left "First name was missing")
```

これでも十分なときもありますが、エラー時に**すべての**省略されたフィールドの一覧がほしいときは、`Either
String`よりも強力なものが必要です。この章の後半でこの解決策を見ていきます。

## 作用の結合

抽象的にApplicative関手を扱う例として、
アプリカティブ関手`f`によって表現された副作用を総称的に組み合わせる関数をどのように書くのかをこの節では示します。

これはどういう意味でしょうか？
何らかの`a`について型`f a`で包まれた引数のリストがあるとしましょう。
それは型`List (f a)`のリストがあるということです。
直感的には、これは`f`によって追跡される副作用を持つ、
返り値の型が`a`の計算のリストを表しています。
これらの計算のすべてを順番に実行することができれば、
`List a`型の結果のリストを得るでしょう。
しかし、まだ`f`によって追跡される副作用が残ります。
つまり、元のリストの中の作用を「結合する」ことにより、
型`List (f a)`の何かを型`f (List a)`の何かへと変換することができると考えられます。

任意の固定長リストの長さ`n`について、
その引数を要素に持った長さ`n`のリストを構築するような`n`引数の関数が存在します。
たとえば、もし`n`が`3`なら、
関数は`\x y z -> x : y : z : Nil`です。
この関数の型は`a -> a -> a -> List a`です。
`Applicative`インスタンスを使うと、
この関数を`f`の上へ持ち上げて関数型`f a -> f a -> f a -> f (List a)`を得ることができます。
しかし、いかなる`n`についてもこれが可能なので、
いかなる引数の**リスト**についても同じように持ち上げられることが確かめられます。

したがって、次のような関数を書くことができるはずです。

```haskell
combineList :: forall f a. Applicative f => List (f a) -> f (List a)
```

この関数は副作用を持つかもしれない引数のリストをとり、
それぞれの副作用を適用することで、`f`に包まれた単一のリストを返します。

この関数を書くためには、
引数のリストの長さについて考えます。
リストが空の場合はどんな作用も実行する必要はありませんから、
`pure`を使用して単に空のリストを返すことができます。

```haskell
combineList Nil = pure Nil
```

実際のところ、これが唯一できることです！

入力のリストが空でないならば、
型`f a`の包まれた引数である先頭要素と、
型`List (f a)`の尾鰭について考えます。
また、再帰的にリストの残りを結合すると、
型`f (List a)`の結果が得られます。
それから`<$>`と`<*>`を使うと、
`Cons`構築子を先頭と新しい尾鰭の上に持ち上げることができます。

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

`Meybe`へ特殊化して考えると、
リストのすべての要素が`Just`であるときに限りこの関数は`Just`を返しますし、
そうでなければ`Nothing`を返します。
これはオプショナルな値に対応するより大きな言語に取り組む上での直感と一貫したものです。
オプショナルな結果を返す計算のリストは、
全ての計算が結果を持っているならばそれ自身の結果のみを持つのです。

しかし`combineList`関数はどんな`Applicative`に対しても機能します！
`Either err`を使ってエラーを発信するかもしれなかったり、
`r ->`を使って大域的な状態を読み取る計算を連鎖させるときにも使えるのです。

`combineList`関数については、後ほど`Traversable`関手について考えるときに再会します。

## 演習

 1. （普通）数値演算子`+`、`-`、`*`、`/`のオプショナル引数
    （つまり`Maybe`に包まれた引数）を扱って`Maybe`に包まれた値を返す版を書いてください。
    これらの関数には`addMaybe`、`subMaybe`、`mulMaybe`、`divMaybe`と名前を付けます。
    **ヒント**：`lift2`を使ってください。
 1. （普通）上の演習を（`Maybe`だけでなく）全ての`Apply`型で動くように拡張してください。
    これらの新しい関数には`addApply`、`subApply`、`mulApply`、`divApply`と名前を付けます。
 1. (難しい) 型`combineMaybe : forall a f. (Applicative f) => Maybe (f a) -> f
    (Maybe a)`
    を持つ関数`combineMaybe`を書いてください。
    この関数は副作用をもつオプショナルな計算をとり、
    オプショナルな結果をもつ副作用のある計算を返します。

## アプリカティブによる検証

この章のソースコードでは住所録アプリケーションで使うことのできるいろいろなデータ型が定義されています。
詳細はここでは割愛しますが、
`Data.AddressBook`モジュールからエクスポートされる重要な関数は次のような型を持っています。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook.purs:address_anno}}

{{#include ../exercises/chapter7/src/Data/AddressBook.purs:phoneNumber_anno}}

{{#include ../exercises/chapter7/src/Data/AddressBook.purs:person_anno}}
```

ここで、`PhoneType`は次のような代数的データ型として定義されています。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook.purs:PhoneType}}
```

これらの関数は住所録の項目を表す`Person`を構築するのに使えます。
例えば、`Data.AddressBook`には次のような値が定義されています。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook.purs:examplePerson}}
```

PSCiでこれらの値を試してみましょう。
（結果は整形されています。）

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

前の章では型`Person`のデータ構造を検証するのに`Either String`関手をどのように使うかを見ました。
例えば、データ構造の2つの名前を検証する関数が与えられたとき、
データ構造全体を次のように検証することができます。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:nonEmpty1}}

{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validatePerson1}}
```

または**アプリカティブdo**で

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validatePerson1Ado}}
```

最初の2行では`nonEmpty`関数を使って空文字列でないことを検証しています。
もし入力が空なら`nonEMpty`はエラーを返し（`Left`構築子で示されています）、
そうでなければ`Right`構築子を使って値を包んで返します。

最後の2行では何の検証も実行せず、
単に`address`フィールドと`phones`フィールドを残りの引数として`person`関数へと提供しています。

この関数はPSCiでうまく動作するように見えますが、以前見たような制限があります。

```text
> validatePerson $ person "" "" (address "" "" "") []
(Left "Field cannot be empty")
```

`Either String`アプリカティブ関手は遭遇した最初のエラーだけを返します。
でもこの入力では、名前の不足と姓の不足という2つのエラーがわかるようにしたくなるでしょう。

`validation`ライブラリは別のアプリカティブ関手も提供されています。
これは単に`V`と呼ばれていて、
何らかの**半群** (Semigroup) でエラーを返す機能があります。
たとえば、`V (Array String)`を使うと、新しいエラーを配列の最後に連結していき、
`String`の配列をエラーとして返すことができます。

`Data.Validation`モジュールは`Data.AddressBook`モジュールの
データ構造を検証するために`V (Array String)`アプリカティブ関手を使っています。

`Data.AddressBook.Validation`モジュールにある検証の例としては次のようになります。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:Errors}}

{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:nonEmpty}}

{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:lengthIs}}

{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validateAddress}}
```

または**アプリカティブdo**で

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validateAddressAdo}}
```

`validateAddress`は`Address`の構造を検証します。
`street`と`city`が空でないかどうか、`state`の文字列の長さが2であるかどうかを検証します。

`nonEmpty`と`lengthIs`の2つの検証関数はいずれも、
`Data.Validation`モジュールで提供されている`invalid`関数を
エラーを示すために使っていることに注目してください。
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

これで、すべての検証エラーの配列を受け取ることができるようになりました。

## 正規表現検証器

`validatePhoneNumber`関数では引数の形式を検証するために正規表現を使っています。重要なのは`matches`検証関数で、この関数は`Data.String.Regex`モジュールのて定義されている`Regex`を使って入力を検証しています。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:matches}}
```

繰り返しになりますが、`pure`は常に成功する検証を表しており、エラーの配列の伝達には`invalid`が使われています。

これまでと同じような感じで、`validatePhoneNumber`は`matches`関数から構築されています。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validatePhoneNumber}}
```

または**アプリカティブdo**で

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

 1. （簡単）正規表現`stateRegex :: Regex`を書いて
    文字列が2文字のアルファベットであることを確かめてください。
    **ヒント**：`phoneNumberRegex`のソースコードを参照してみましょう。
 1. （普通）文字列全体が空白でないことを検査する正規表現`nonEmptyRegex :: Regex`を書いてください。
    **ヒント**：この正規表現を開発するのに手助けが必要なら、[RegExr](https://regexr.com)をご確認ください。
    素晴しい早見表と対話的なお試し環境があります。
 1. （普通）`validateAddress`に似ていますが、
    上の`stateRegex`を使って`state`フィールドを検証し、
    `nonEmptyRegex`を使って`street`と`city`フィールドを検証する関数`validateAddressImproved`を書いてください。
    **ヒント**：`matches`の用例については`validatePhoneNumber`のソースを見てください。

## 巡回可能関手

残った検証器は`validatePerson`です。
これはこれまで見てきた検証器と以下の新しい`validatePhoneNumbers`関数を組み合わせて
`Person`全体を検証するものです。

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validatePhoneNumbers}}

{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validatePerson}}
```

または**アプリカティブdo**で

```haskell
{{#include ../exercises/chapter7/src/Data/AddressBook/Validation.purs:validatePersonAdo}}
```

`validatePhoneNumbers`はこれまでに見たことのない新しい関数、`traverse`を使います。

`traverse`は`Data.Traversable`モジュールの`Traversable`型クラスで定義されています。

```haskell
class (Functor t, Foldable t) <= Traversable t where
  traverse :: forall a b m. Applicative m => (a -> m b) -> t a -> m (t b)
  sequence :: forall a m. Applicative m => t (m a) -> m (t a)
```

`Traversable`は**巡回可能関手**の型クラスを定義します。
これらの関数の型は少し難しそうに見えるかもしれませんが、`validatePerson`は良いきっかけとなる例です。

すべての巡回可能関手は`Functor`と`Foldable`のどちらでもあります。
（**畳み込み可能関手**は構造をひとつの値へとまとめる、
畳み込み操作を提供する型構築子であったことを思い出してください。）
それに加えて、`Traversable`関手はその構造に依存した副作用の集まりを連結する機能を提供します。

複雑そうに聞こえるかもしれませんが、配列の場合に特殊化して簡単に考えてみましょう。配列型構築子は`Traversable`である、つまり次のような関数が存在するということです。

```haskell
traverse :: forall a b m. Applicative m => (a -> m b) -> Array a -> m (Array b)
```

直感的には、任意のアプリカティブ関手`m`と、
型`a`の値を取って型`b`の値を返す（`f`で追跡される副作用を持つ）関数が与えられたとき、
その関数を型`Array a`の配列のそれぞれの要素に適用し、
型`Array b`の（`f`で追跡される副作用を持つ）結果を得ることができます。

まだよくわからないでしょうか。
それでは、更に`f`を上記の`V Errors`アプリカティブ関手に特殊化して考えてみましょう。
これで次の型を持つ関数が得られます。

```haskell
traverse :: forall a b. (a -> V Errors b) -> Array a -> V Errors (Array b)
```

この型シグネチャは、
型`a`についての検証関数`m`があれば、
`traverse m`は型`Array a`の配列についての検証関数であるということを言っています。
これはまさに今必要になっている`Person`データ構造体の`phones`フィールドを検証する検証器そのものです！
それぞれの要素が成功するかどうかを検証する検証関数を作るために、
`validatePhoneNumber`を`traverse`へ渡しています。

一般に、`traverse`はデータ構造の要素をひとつづつ辿っていき、副作用のある計算を実行して結果を累積します。

`Traversable`のもう一つの関数、`sequence`の型シグネチャには見覚えがあるかもしれません。

```haskell
sequence :: forall a m. Applicative m => t (m a) -> m (t a)
```

実際、先ほど書いた`combineList`関数は`Traversable`型クラスの`sequence`関数の特別な場合に過ぎません。
`t`を型構築子`List`だとすると、`combineList`関数の型が復元されます。

```haskell
combineList :: forall f a. Applicative f => List (f a) -> f (List a)
```

巡回可能関手は、
作用のある計算を連鎖させてその作用を結合するという、
データ構造走査の考え方を把握できるようにするものです。
実際、`sequence`と`traversable`は`Traversable`を定義する上でどちらも同じくらい重要です。
これらはお互いが互いを利用して実装することができます。
これについては興味ある読者への演習として残しておきます。

`Data.List`で与えられているリストの`Traversable`インスタンスは次の通り。

```haskell
instance traversableList :: Traversable List where
-- traverse :: forall a b m. Applicative m => (a -> m b) -> List a -> m (List b)
traverse _ Nil         = pure Nil
traverse f (Cons x xs) = Cons <$> f x <*> traverse f xs
```

（実際の定義は後にスタック安全性を向上するための変更されました。
その変更についてより詳しくは[こちら](https://github.com/purescript/purescript-lists/pull/87)で読むことができます。）

入力が空のリストのときには、
単に`pure`を使って空の配列を返すことができます。
配列が空でないときは、
関数`f`を使うと先頭の要素から型`f b`の計算を作成することができます。
また、配列の残りに対して`traverse`を再帰的に呼び出すことができます。
最後に、アプリカティブ関手`m`まで`Cons`構築子を持ち上げて、2つの結果を組み合わせます。

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

これらの例では、
`Nothing`の値の走査は検証なしで`Nothing`の値を返し、
`Just x`を走査すると`x`を検証するのに検証関数が使われるということを示しています。
要は、`traverse`は型`a`についての検証関数をとり、`Maybe a`についての検証関数、
つまり型`a`のオプショナルな値についての検証関数を返すのです。

他の巡回可能関手には`Array`、また任意の型`a`について`Tuple a`、`Either a`が含まれます。
一般的に、「容器」のようなデータの型構築子は大抵`Traversable`インスタンスを持っています。
例として、演習では二分木の型の`Traversable`インスタンスを書くようになっています。

## 演習

 1. （簡単）`Eq`と`Show`インスタンスを以下の2分木データ構造に書いてください。

     ```haskell
     data Tree a = Leaf | Branch (Tree a) a (Tree a)
     ```

     これらのインスタンスを手作業で書くこともできますし、
     コンパイラに導出してもらうこともできることを前の章から思い起こしてください。

     `Show`の出力には多くの「正しい」書式の選択肢があります。
     この演習のテストでは以下の空白スタイルを期待しています。
     これはちょうど一般化されたshowの既定の書式と合致しているため、
     このインスタンスを手作業で書くつもりであれば、
     このことを念頭に置いておくだけでよいです。

     ```
     (Branch (Branch Leaf 8 Leaf) 42 Leaf)
     ```

 1. （普通）`Traversable`インスタンスを`Tree a`を書いてください。
    これは副作用を左から右に結合するものです。
    **ヒント**：`Traversable`に定義する必要のある追加のインスタンス依存関係がいくつかあります。

 1. （普通）行き掛け順に木を巡回する関数
    `traversePreOrder :: forall a m b. Applicative m => (a -> m b) -> Tree a
    -> m (Tree b)`
    を書いてください。
    つまり作用の実行は根左右と行われ、
    以前の通り掛け順の巡回の演習でしたような左根右ではありません。
    **ヒント**：追加でインスタンスを定義する必要はありませんし、
    前に定義した関数は何も呼ぶ必要はありません。
    アプリカティブdo記法 (`ado`) はこの関数を書く最も簡単な方法です。

 1. （普通）作用が左右根と実行される木の帰り掛け順の巡回を行う関数
    `traversePostOrder`を書いてください。

 1. （普通）`homeAddress`フィールドがオプショナル（`Maybe`を使用）な
    新しい版の`Person`型をつくってください。
    それからこの新しい`Person`を検証する新しい版の`validatePerson`（`validatePersonOptionalAddress`と改名します）を書いてください。
    **ヒント**：`traverse`を使って型`Maybe a`のフィールドを検証してください。

 1. （難しい）`sequence`のように振る舞う関数`sequenceUsingTraverse`を書いてください。
    ただし`traverse`を使ってください。

 1. （難しい）`traverse`のように振る舞う関数`traverseUsingSequence`を書いてください。
    ただし`sequence`を使ってください。

## アプリカティブ関手による並列処理

これまでの議論では、
アプリカティブ関手がどのように「副作用を結合」させるかを説明するときに、
「結合」(combine) という単語を選びました。
しかしながら、これらのすべての例において、
アプリカティブ関手は作用を「連鎖」(sequence) させる、
というように言っても同じく妥当です。
巡回可能関手がデータ構造に従って作用を順番に結合させる`sequence`関数を提供していることと、
この直感的理解とは一致するでしょう。

しかし一般には、
アプリカティブ関手はこれよりももっと一般的です。
アプリカティブ関手の規則は、
その計算を実行する副作用にどんな順序付けも強制しません。
実際、並列に副作用を実行するためのアプリカティブ関手というものは妥当になりえます。

たとえば、
`V`検証関手はエラーの**配列**を返しますが、
その代わりに`Set`半群を選んだとしてもやはり正常に動き、
このときどんな順序でそれぞれの検証器を実行しても問題はありません。
データ構造に対して並列にこれを実行することさえできるのです！

別の例として、`parallel`パッケージは、
**並列計算**をサポートする`Parallel`型クラスを与えます。
`Parallel`は関数`parallel`を提供しており、
何らかの`Applicative`関手を使って入力の計算を**並列に**計算することができます。

```haskell
f <$> parallel computation1
  <*> parallel computation2
```

この計算は`computation1`と`computation2`を非同期に使って値を計算を始めるでしょう。
そして両方の結果の計算が終わった時に、関数`f`を使ってひとつの結果へと結合するでしょう。

この考え方の詳細は、
本書の後半で**コールバック地獄**の問題に対して
アプリカティブ関手を応用するときに見ていきます。

アプリカティブ関手は並列に結合されうる副作用を捕捉する自然な方法です。

## まとめ

この章では新しい考え方をたくさん扱いました。

- 関数適用の概念を副作用の観念を捉えた型構築子へと一般化する、**アプリカ
  ティブ関手**の概念を導入しました。
- データ構造の検証という課題にアプリカティブ関手がどのような解決策を与え
  るか、どうすれば単一のエラーの報告からデータ構造を横断するすべてのエラー
  の報告へ変換できるのかを見てきました。
- `Traversable`型クラスに出会いました。**巡回可能関手**の考え方を内包す
  るものであり、要素が副作用を持つ値の結合に使うことができる容器でした。

アプリカティブ関手は多くの問題に対して優れた解決策を与える興味深い抽象化です。
本書を通じて何度も見ることになるでしょう。
今回の場合、アプリカティブ関手は宣言的な流儀で書く手段を提供していましたが、
これにより**どうやって**検証を行うかではなく、
**何を**検証器が検証すべきなのかを定義することができました。
一般に、アプリカティブ関手は**領域特化言語**を設計する上で便利な道具になります。

次の章では、これに関連する考え方である**モナド**クラスを見て、
アドレス帳の例をブラウザで実行させられるように拡張しましょう！

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