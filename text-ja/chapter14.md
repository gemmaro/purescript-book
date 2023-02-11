# 領域特化言語

## この章の目標

この章では多数の標準的な手法を使い、PureScriptにおける*領域特化言語*（または*DSL*）の実装について探求していきます。

領域特化言語とは、特定の問題領域での開発に適した言語のことです。
領域特化言語の構文及び機能は、その領域内の考え方を表現するコードの読みやすさを最大限に発揮すべく選択されます。
本書の中では、既に領域特化言語の例を幾つか見てきています。

- 第11章で開発された `Game`モナドと関連するアクションは、 _テキストアドベンチャーゲーム開発_
  という領域に対しての領域特化言語を構成しています。
- 第13章で扱った `quickcheck`パッケージは、 _生成的テスティング_
  の領域の領域特化言語です。このコンビネータはテストの性質に対して特に表現力の高い記法を可能にします。

この章では、領域特化言語の実装において、幾つかの標準的な技法による構造的な手法に迫ります。
これがこの話題の完全な説明だということでは決してありませんが、自分の目的に合う具体的なDSLを構築するのには充分な知識をもたらすことでしょう。

この章で実行している例は、HTML文書を作成するための領域特化言語です。
正しいHTML文書を記述するための型安全な言語を開発することが目的で、素朴な実装を徐々に改善しつつ進めていきます。

## プロジェクトの準備

この章で使うプロジェクトには新しい依存性が1つ追加されます。これから使う道具の1つである*Freeモナド*が定義されている `free`ライブラリです。

このプロジェクトをPSCiを使って試していきます。

## HTMLデータ型

このHTMLライブラリの最も基本的なバージョンは
`Data.DOM.Simple`モジュールで定義されています。このモジュールには次の型定義が含まれています。

```haskell
newtype Element = Element
  { name         :: String
  , attribs      :: Array Attribute
  , content      :: Maybe (Array Content)
  }

data Content
  = TextContent String
  | ElementContent Element

newtype Attribute = Attribute
  { key          :: String
  , value        :: String
  }
```

`Element`型はHTMLの要素を表しています。
各要素は要素名、属性の対の配列と、要素の内容で構成されています。
contentプロパティは、`Maybe`タイプを適切に使って、要素が開いている（他の要素やテキストを含む）か閉じているかを示しています。

このライブラリの鍵となる機能は次の関数です。

```haskell
render :: Element -> String
```

この関数はHTML要素をHTML文字列として出力します。
PSCiで明示的に適当な型の値を構築し、ライブラリのこのバージョンを試してみましょう。

```text
$ spago repl

> import Prelude
> import Data.DOM.Simple
> import Data.Maybe
> import Effect.Console

> :paste
… log $ render $ Element
…   { name: "p"
…   , attribs: [
…       Attribute
…         { key: "class"
…         , value: "main"
…         }
…     ]
…   , content: Just [
…       TextContent "Hello World!"
…     ]
…   }
… ^D

<p class="main">Hello World!</p>
unit
```

現状のライブラリには幾つもの問題があります。

- HTML文書の作成に手がかかります。
  全ての新しい要素に少なくとも1つのレコードと1つのデータ構築子が必要です。
- 無効な文書を表現できてしまいます。
  - 開発者が要素名の入力を間違えるかもしれません
  - 開発者が属性を間違った要素に関連付けることができてしまいます
  - 開いた要素が正しい場合に開発者が閉じた要素を使えてしまいます

残りの章ではとある手法を用いてこれらの問題を解決し、このライブラリーをHTML文書を作成するために使える領域特化言語にしていきます。

## スマート構築子

最初に導入する手法は方法こそ単純なものですが、とても効果的です。
モジュールの使用者にデータの表現を露出する代わりに、モジュールエクスポートリストを使ってデータ構築子 `Element`、 `Content`、
`Attribute`を隠蔽し、正しいことが明らかなデータだけ構築する、いわゆる*スマート構築子*だけをエクスポートします。

例を示しましょう。まず、HTML要素を作成するための便利な関数を提供します。

```haskell
element :: String -> Array Attribute -> Maybe (Array Content) -> Element
element name attribs content = Element
  { name:      name
  , attribs:   attribs
  , content:   content
  }
```

次に、欲しいHTML要素を利用者が作れるように、スマート構築子を作成します。
これには`element`関数を適用します。

```haskell
a :: Array Attribute -> Array Content -> Element
a attribs content = element "a" attribs (Just content)

p :: Array Attribute -> Array Content -> Element
p attribs content = element "p" attribs (Just content)

img :: Array Attribute -> Element
img attribs = element "img" attribs Nothing
```

最後に、正しいデータ構造だけが構築されることがわかっているこれらの関数をエクスポートするように、モジュールエクスポートリストを更新します。

```haskell
module Data.DOM.Smart
  ( Element
  , Attribute(..)
  , Content(..)

  , a
  , p
  , img

  , render
  ) where
```

モジュールエクスポートリストはモジュール名の直後の括弧内に書きます。
各モジュールのエクスポートは次の3種類の何れかになります。

- 値（ないし関数）。その値の名前により指定されます。
- 型クラス。クラス名により指定されます。
- 型構築子と関連するデータ構築子。型名とそれに続くエクスポートされるデータ構築子の括弧で囲まれたリストで指定されます。

ここでは、 `Element`の*型*をエクスポートしていますが、データ構築子はエクスポートしていません。
もしデータ構築子をエクスポートすると、モジュールの使用者が不正なHTML要素を構築できてしまいます。

`Attribute`と `Content`型についてはデータ構築子を全てエクスポートしています（エクスポートリストの記号 `..`で示されています）。
すぐ後で、これらの型にもスマート構築子の手法を適用していきます。

既にライブラリに幾つもの大きな改良が加わっていることに注目です。

- 不正な名前を持つHTML要素は表現できません（もちろん、ライブラリが提供する要素名に制限されています）。
- 閉じた要素は構築するときに内容を含められません。

`Content`型にとても簡単にこの手法を適用できます。
単にエクスポートリストから `Content`型のデータ構築子を取り除き、次のスマート構築子を提供します。

```haskell
text :: String -> Content
text = TextContent

elem :: Element -> Content
elem = ElementContent
```

`Attribute`型にも同じ手法を適用してみましょう。
まず、属性のための汎用のスマート構築子を用意します。
以下は最初の試行です。

```haskell
attribute :: String -> String -> Attribute
attribute key value = Attribute
  { key: key
  , value: value
  }

infix 4 attribute as :=
```

この定義では元の `Element`型と同じ問題に直面しています。
存在しなかったり、名前が間違っているような属性を表現できます。
この問題を解決するために、属性名を表すnewtypeを作成します。

```haskell
newtype AttributeKey = AttributeKey String
```

これを使えば演算子を次のように変更できます。

```haskell
attribute :: AttributeKey -> String -> Attribute
attribute (AttributeKey key) value = Attribute
  { key: key
  , value: value
  }
```

`AttributeKey`データ構築子をエクスポートしなければ、明示的にエクスポートされた次のような関数を使う以外に、使用者が型
`AttributeKey`の値を構築する方法はありません。
以下に幾つかの例を示します。

```haskell
href :: AttributeKey
href = AttributeKey "href"

_class :: AttributeKey
_class = AttributeKey "class"

src :: AttributeKey
src = AttributeKey "src"

width :: AttributeKey
width = AttributeKey "width"

height :: AttributeKey
height = AttributeKey "height"
```

新しいモジュールの最終的なエクスポートリストは次のようになります。
最早どのデータ構築子も直接エクスポートしていない点に注目です。

```haskell
module Data.DOM.Smart
  ( Element
  , Attribute
  , Content
  , AttributeKey

  , a
  , p
  , img

  , href
  , _class
  , src
  , width
  , height

  , attribute, (:=)
  , text
  , elem

  , render
  ) where
```

PSCiでこの新しいモジュールを試してみると、既にコードの簡潔さにおいて大幅な向上が見て取れます。

```text
$ spago repl

> import Prelude
> import Data.DOM.Smart
> import Effect.Console
> log $ render $ p [ _class := "main" ] [ text "Hello World!" ]

<p class="main">Hello World!</p>
unit
```

しかし、基盤をなすデータ表現は変更されなかったので、 `render`関数を変更する必要はなかったことにも注目してください。
これはスマート構築子による手法の利点のひとつです。
外部APIの使用者によって認識される表現からモジュールの内部データ表現を分離できるのです。

## 演習

 1. （簡単）`Data.DOM.Smart`モジュールで `render`を使った新しいHTML文書の作成を試してみましょう。
 1. （普通）`checked`と `disabled`など、値を要求しないHTML属性がありますが、これらは次のような _空の属性_
    として表示されるかもしれません。

     ```html
     <input disabled>
     ```

     空の属性を扱えるように `Attribute`の表現を変更してください。
     要素に空の属性を追加するための`attribute`または`:=`の代わりに使える関数を記述してください。

## 幻影型

次の手法の動機付けとして、以下のコードを考えます。

```text
> log $ render $ img
    [ src    := "cat.jpg"
    , width  := "foo"
    , height := "bar"
    ]

<img src="cat.jpg" width="foo" height="bar" />
unit
```

ここでの問題は、 `width`属性と`height`属性に文字列値を提供しているということです。
ここで与えることができるのはピクセル単位ないしパーセントの数値だけであるべきです。

`AttributeKey`型にいわゆる _幻影型_ (phantom type) 引数を導入すると、この問題を解決できます。

```haskell
newtype AttributeKey a = AttributeKey String
```

定義の右辺に対応する型 `a`の値が存在しないので、この型変数 `a`は*幻影型*と呼ばれています。
この型 `a`はコンパイル時に追加の情報を提供するためだけに存在しています。
型`AttributeKey
a`の任意の値は実行時には単なる文字列ですが、コンパイル時はその値の型により、このキーに関連する値で求められる型がわかります。

`attribute`関数の型を次のように変更すれば、`AttributeKey`の新しい形式を考慮するようにできます。

```haskell
attribute :: forall a. IsValue a => AttributeKey a -> a -> Attribute
attribute (AttributeKey key) value = Attribute
  { key: key
  , value: toValue value
  }
```

ここで、幻影型の引数 `a`は、属性キーと属性値が照応する型を持っていることを確認するために使われます。
使用者は `AttributeKey
a`の型の値を直接作成できないので（ライブラリで提供されている定数を介してのみ得られます）、全ての属性が構築により正しくなります。

なお、`IsValue`制約はキーに関連付けられた値の型が何であれその値を文字列に変換し、生成したHTML内に出力できることを保証します。
`IsValue`型クラスは次のように定義されています。

```haskell
class IsValue a where
  toValue :: a -> String
```

`String`と `Int`型についての型クラスインスタンスも提供しておきます。

```haskell
instance stringIsValue :: IsValue String where
  toValue = id

instance intIsValue :: IsValue Int where
  toValue = show
```

また、これらの型が新しい型変数を反映するように、 `AttributeKey`定数を更新しなければいけません。

```haskell
href :: AttributeKey String
href = AttributeKey "href"

_class :: AttributeKey String
_class = AttributeKey "class"

src :: AttributeKey String
src = AttributeKey "src"

width :: AttributeKey Int
width = AttributeKey "width"

height :: AttributeKey Int
height = AttributeKey "height"
```

これで、不正なHTML文書を表現することが不可能になっていることがわかります。
また、`width`と `height`属性を表現するのに文字列ではなく数を使うことが強制されていることがわかります。

```text
> import Prelude
> import Data.DOM.Phantom
> import Effect.Console

> :paste
… log $ render $ img
…   [ src    := "cat.jpg"
…   , width  := 100
…   , height := 200
…   ]
… ^D

<img src="cat.jpg" width="100" height="200" />
unit
```

## 演習

 1. （簡単）ピクセルまたはパーセントの長さの何れかを表すデータ型を作成してください。
    その型について `IsValue`のインスタンスを書いてください。
    この型を使うように `width`と `height`属性を変更してください。
 1. （難しい）幻影型を使って真偽値 `true`、 `false`用の最上位の表現を定義することで、 `AttributeKey`が
    `disabled`や `checked`のような*空の属性*を表現しているかどうかを符号化できます。

     ```haskell
     data True
     data False
     ```

     幻影型を使って、使用者が `attribute`演算子を空の属性に対して使うことを防ぐように、前の演習の解答を変更してください。

## Freeモナド

APIに施す最後の変更は、 `Content`型をモナドにしてdo記法を使えるようにするために、 _Freeモナド_
と呼ばれる構造を使うことです。これによって入れ子になった要素がわかりやすくなるようにHTML文書を構造化できます。以下の代わりに……

```haskell
p [ _class := "main" ]
  [ elem $ img
      [ src    := "cat.jpg"
      , width  := 100
      , height := 200
      ]
  , text "A cat"
  ]
```

このように書くことができるようになります。

```haskell
p [ _class := "main" ] $ do
  elem $ img
    [ src    := "cat.jpg"
    , width  := 100
    , height := 200
    ]
  text "A cat"
```

しかし、do記法だけがFreeモナドの恩恵だというわけではありません。Freeモナドがあれば、モナドのアクションの _表現_ をその _解釈_
から分離し、同じアクションに _複数の解釈_ を持たせることさえできます。

`Free`モナドは `free`ライブラリの `Control.Monad.Free`モジュールで定義されています。
PSCiを使うと、次のようにFreeモナドについての基本的な情報を見ることができます。

```text
> import Control.Monad.Free

> :kind Free
(Type -> Type) -> Type -> Type
```

`Free`の種は、引数として型構築子を取り、別の型構築子を返すことを示しています。
実は、`Free`モナドを使えば任意の`Functor`を`Monad`にできます。

モナドのアクションの*表現*の定義から始めます。
こうするには、対応する各モナドアクションそれぞれについて、1つのデータ構築子を持つ `Functor`を作成する必要があります。
今回の場合、2つのモナドのアクションは `elem`と `text`になります。
実際には、 `Content`型を次のように変更するだけです。

```haskell
data ContentF a
  = TextContent String a
  | ElementContent Element a

instance functorContentF :: Functor ContentF where
  map f (TextContent s x) = TextContent s (f x)
  map f (ElementContent e x) = ElementContent e (f x)
```

ここで、この `ContentF`型構築子は以前の `Content`データ型とよく似ています。
しかし、ここでは型引数`a`を取り、それぞれのデータ構築子は型`a`の値を追加の引数として取るように変更されています。
`Functor`インスタンスでは、単に各データ構築子で型 `a`の構成要素に関数 `f`を適用します。

これにより、新しい`Content`モナドを`Free`モナド用の型シノニムとして定義できます。
これは最初の型引数として `ContentF`型構築子を使うことで構築されます。

```haskell
type Content = Free ContentF
```

型シノニムの代わりにnewtypeを使用して、使用者に対してライブラリの内部表現を露出することを避けられます。
`Content`データ構築子を隠すことで、提供しているモナドのアクションだけを使うことを使用者に制限しています。

`ContentF`は `Functor`なので、 `Free ContentF`用の`Monad`インスタンスが自動的に手に入ります。

`Content`の新しい型引数を考慮するように`Element`データ型を僅かに変更する必要があります。
モナドの計算の戻り値の型が `Unit`であることだけが必要です。

```haskell
newtype Element = Element
  { name         :: String
  , attribs      :: Array Attribute
  , content      :: Maybe (Content Unit)
  }
```

また、 `Content`モナドについての新しいモナドのアクションになる `elem`と `text`関数を変更する必要があります。
これには`Control.Monad.Free`モジュールで提供されている `liftF`関数が使えます。
この関数の型は次のようになっています。

```haskell
liftF :: forall f a. f a -> Free f a
```

`liftF`により、何らかの型 `a`について、型 `f a`の値からFreeモナドのアクションを構築できるようになります。
今回の場合、 `ContentF`型構築子のデータ構築子をそのまま使うだけです。

```haskell
text :: String -> Content Unit
text s = liftF $ TextContent s unit

elem :: Element -> Content Unit
elem e = liftF $ ElementContent e unit
```

他にも同じようなコードの変更はありますが、興味深い変更は `render`関数にあります。ここでは、このFreeモナドを _解釈_
しなければいけません。

## モナドの解釈

`Control.Monad.Free`モジュールでは、Freeモナドで計算を解釈するための多数の関数が提供されています。

```haskell
runFree
  :: forall f a
   . Functor f
  => (f (Free f a) -> Free f a)
  -> Free f a
  -> a

runFreeM
  :: forall f m a
   . (Functor f, MonadRec m)
  => (f (Free f a) -> m (Free f a))
  -> Free f a
  -> m a
```

`runFree`関数は、 _純粋な_ 結果を計算するために使用されます。
`runFreeM`関数があればFreeモナドのアクションを解釈するためにモナドが使えます。

*補足*：厳密には、より強い`MonadRec`制約を満たすモナド `m`を使用するよう制限されています。
実際には、これはスタックオーバーフローを心配する必要がないことを意味します。
なぜなら `m`は安全な*末尾再帰モナド*に対応しているからです。

まず、アクションを解釈できるモナドを選ばなければなりません。
`Writer String`モナドを使って、結果のHTML文字列を累積することにします。

新しい`render`メソッドが開始すると、補助関数
`renderElement`に移譲し、`execWriter`を使って`Writer`モナドで計算を走らせます。

```haskell
render :: Element -> String
render = execWriter <<< renderElement
```

`renderElement`はwhereブロックで定義されます。

```haskell
  where
    renderElement :: Element -> Writer String Unit
    renderElement (Element e) = do
```

`renderElement`の定義は直感的で、複数の小さな文字列を累積するために `Writer`モナドの `tell`アクションを使っています。

```haskell
      tell "<"
      tell e.name
      for_ e.attribs $ \x -> do
        tell " "
        renderAttribute x
      renderContent e.content
```

次に、`renderAttribute`関数を定義します。
こちらも同じくらい単純です。

```haskell
    where
      renderAttribute :: Attribute -> Writer String Unit
      renderAttribute (Attribute x) = do
        tell x.key
        tell "=\""
        tell x.value
        tell "\""
```

`renderContent`関数は、もっと興味深いものです。
ここでは`runFreeM`関数を使い、Freeモナドの内部で計算を解釈しています。
計算は補助関数 `renderContentItem`に移譲しています。

```haskell
      renderContent :: Maybe (Content Unit) -> Writer String Unit
      renderContent Nothing = tell " />"
      renderContent (Just content) = do
        tell ">"
        runFreeM renderContentItem content
        tell "</"
        tell e.name
        tell ">"
```

`renderContentItem`の型は `runFreeM`の型シグネチャから推測できます。
関手 `f`は型構築子 `ContentF`で、モナド `m`は解釈している計算のモナド、つまり `Writer String`です。
これにより `renderContentItem`は次の型シグネチャだとわかります。

```haskell
      renderContentItem :: ContentF (Content Unit) -> Writer String (Content Unit)
```

`ContentF`の2つのデータ構築子でパターン照合するだけでこの関数を実装できます。

```haskell
      renderContentItem (TextContent s rest) = do
        tell s
        pure rest
      renderContentItem (ElementContent e rest) = do
        renderElement e
        pure rest
```

それぞれの場合において、式 `rest`は型 `Content Unit`を持っており、解釈計算の残りを表しています。
`rest`アクションを呼び出すことによってそれぞれの場合を完了できます。

できました。
PSCiで、次のようにすれば新しいモナドのAPIを試すことができます。

```text
> import Prelude
> import Data.DOM.Free
> import Effect.Console

> :paste
… log $ render $ p [] $ do
…   elem $ img [ src := "cat.jpg" ]
…   text "A cat"
… ^D

<p><img src="cat.jpg" />A cat</p>
unit
```

## 演習

 1. （普通）`ContentF`型に新しいデータ構築子を追加して、生成されたHTMLにコメントを出力する新しいアクション
    `comment`に対応してください。
    `liftF`を使ってこの新しいアクションを実装してください。
    新しい構築子を適切に解釈するように、解釈 `renderContentItem`を更新してください。

## 言語の拡張

全てのアクションが型 `Unit`の何かを返すようなモナドは、さほど興味深いものではありません。
実際のところ、概ね良くなったと思われる構文は別として、このモナドは `Monoid`以上の機能を何ら追加していません。

非自明な結果を返す新しいモナドアクションでこの言語を拡張することで、Freeモナド構造の威力をお見せしましょう。

*アンカー*を使用して文書のさまざまな節へのハイパーリンクが含まれているHTML文書を生成するとします。
これは既に達成できています。
手作業でアンカーの名前を生成して文書中で少なくとも2回それらを含めればよいのです。
1つはアンカーの定義自身に、もう1つはそれぞれのハイパーリンクにあります。
しかし、この方法には根本的な問題が幾つかあります。

- 開発者が一意なアンカー名の生成をし損なうかもしれません。
- 開発者がアンカー名を1つ以上の箇所で打ち間違うかもしれません。

開発者が誤ちを犯すことを防ぐために、アンカー名を表す新しい型を導入し、新しい一意な名前を生成するためのモナドアクションを提供できます。

最初の工程は名前の型を新しく追加することです。

```haskell
newtype Name = Name String

runName :: Name -> String
runName (Name n) = n
```

繰り返しになりますが、`Name`は
`String`のnewtypeとして定義しているものの、モジュールのエクスポートリスト内でデータ構築子をエクスポートしないように注意する必要があります。

次に、属性値として `Name`を使うことができるように、新しい型に`IsValue`型クラスのインスタンスを定義します。

```haskell
instance nameIsValue :: IsValue Name where
  toValue (Name n) = n
```

また、次のように `a`要素に現れるハイパーリンク用の新しいデータ型を定義します。

```haskell
data Href
  = URLHref String
  | AnchorHref Name

instance hrefIsValue :: IsValue Href where
  toValue (URLHref url) = url
  toValue (AnchorHref (Name nm)) = "#" <> nm
```

この新しい型により、`href`属性の型の値を変更して、利用者にこの新しい `Href`型の使用を強制できます。
また、新しい`name`属性も作成でき、要素をアンカーに変換するのに使えます。

```haskell
href :: AttributeKey Href
href = AttributeKey "href"

name :: AttributeKey Name
name = AttributeKey "name"
```

残っている問題は、現在モジュールの使用者が新しい名前を生成する方法がないということです。
`Content`モナドでこの機能を提供できます。まず、 `ContentF`型構築子に新しいデータ構築子を追加する必要があります。

```haskell
data ContentF a
  = TextContent String a
  | ElementContent Element a
  | NewName (Name -> a)
```

`NewName`データ構築子は型 `Name`の値を返すアクションに対応しています。データ構築子の引数として `Name`を要求するのではなく、型 `Name -> a`の _関数_ を提供するように使用者に要求していることに注意してください。型 `a`は _計算の残り_ を表していることを思い出すと、この関数は、型 `Name`の値が返されたあとで、計算を継続する方法を提供しているのだとわかります。

新しいデータ構築子を考慮するよう、次のように`ContentF`用の`Functor`インスタンスを更新する必要もあります。

```haskell
instance functorContentF :: Functor ContentF where
  map f (TextContent s x) = TextContent s (f x)
  map f (ElementContent e x) = ElementContent e (f x)
  map f (NewName k) = NewName (f <<< k)
```

これで、以前と同じように`liftF`関数を使って新しいアクションを構築できます。

```haskell
newName :: Content Name
newName = liftF $ NewName id
```

`id`関数を継続として提供していることに注意してください。
これは型 `Name`の結果を変更せずに返すということを意味しています。

最後に、新しいアクションを解釈するために解釈関数を更新する必要があります。
以前は計算を解釈するために `Writer
String`モナドを使っていましたが、このモナドは新しい名前を生成する能力を持っていないので、何か他のものに切り替えなければなりません。
`WriterT`モナド変換子を`State`モナドと一緒に使うと、必要な作用を組み合わせることができます。
型注釈を短く保てるように、この解釈モナドを型同義語として定義しておきます。

```haskell
type Interp = WriterT String (State Int)
```

ここで、`Int`型の状態は増加していくカウンタとして振舞い、一意な名前を生成するのに使われます。

`Writer`と `WriterT`モナドはそれらのアクションを抽象化するのに同じ型クラスメンバを使うので、どのアクションも変更する必要がありません。
必要なのは、 `Writer String`への参照全てを `Interp`で置き換えることだけです。
しかし、これを計算するために使われる制御子を変更しなければいけません。
こうなると単なる`execWriter`の代わりに、ここでも`evalState`を使う必要があります。

```haskell
render :: Element -> String
render e = evalState (execWriterT (renderElement e)) 0
```

また、新しい `NewName`データ構築子を解釈するために、 `renderContentItem`に新しい場合を追加しなければいけません。

```haskell
renderContentItem (NewName k) = do
  n <- get
  let fresh = Name $ "name" <> show n
  put $ n + 1
  pure (k fresh)
```

ここで、型 `Name -> Content a`の継続 `k`が与えられているので、型 `Content a`の解釈を構築しなければいけません。
この解釈は単純です。
`get`を使って状態を読み、その状態を使って一意な名前を生成し、それから `put`で状態に1だけ足すのです。
最後に、継続にこの新しい名前を渡して、計算を完了します。

以上をもって、この新しい機能をPSCiで試すことができます。
これには`Content`モナドの内部で一意な名前を生成し、要素の名前とハイパーリンクのリンク先の両方として使います。

```text
> import Prelude
> import Data.DOM.Name
> import Effect.Console

> :paste
… render $ p [ ] $ do
…   top <- newName
…   elem $ a [ name := top ] $
…     text "Top"
…   elem $ a [ href := AnchorHref top ] $
…     text "Back to top"
… ^D

<p><a name="name0">Top</a><a href="#name0">Back to top</a></p>
unit
```

複数回の `newName`の呼び出しの結果が、実際に一意な名前になっていることも確かめられます。

## 演習

 1. （普通）使用者から `Element`型を隠蔽すると、更にAPIを簡素にできます。
    次の手順に従って、これらの変更を加えてください。
     - `p`や `img`のような（返る型が `Element`の）関数を `elem`アクションと結合して、型 `Content
       Unit`を返す新しいアクションを作ってください。
     - `Element`の代わりに型`Content Unit`の引数を受け付けるように`render`関数を変更してください。
 1. （普通）型同義語の代わりに`newtype`を使うことによって`Content`モナドの実装を隠してください。
    `newtype`用のデータ構築子はエクスポートすべきではありません。
 1. （難しい）`ContentF`型を変更して以下の新しいアクションに対応してください。

     ```haskell
     isMobile :: Content Boolean
     ```

     このアクションは、この文書がモバイルデバイス上での表示のためにレンダリングされているかどうかを示す真偽値を返します。

     *手掛かり*：`ask`アクションと`ReaderT`モナド変換子を使って、このアクションを解釈してください。
     あるいは、`RWS`モナドを使うほうが好みの人もいるかもしれません。

## まとめ

この章では、幾つかの標準的な技術を使って、素朴な実装を段階的に改善することにより、HTML文書を作成するための領域特化言語を開発しました。

- _スマート構築子_ を使ってデータ表現の詳細を隠し、利用者には _構築により正しい_ 文書だけを作ることを許しました。
- *独自に定義された中置2引数演算子*を使い、言語の構文を改善しました。
- _幻影型_ を使ってデータの型の中に追加の情報を折り込みました。これにより利用者が誤った型の属性値を与えることを防いでいます。
- _Freeモナド_
  を使って内容の集まりの配列表現をdo記法に対応したモナドな表現に変えました。それからこの表現を新しいモナドアクションに対応するよう拡張し、標準モナド変換子を使ってモナドの計算を解釈しました。

これらの手法は全て、使用者が間違いを犯すのを防いだり領域特化言語の構文を改良したりするために、PureScriptのモジュールと型システムを活用しています。

関数型プログラミング言語による領域特化言語の実装は活発に研究されている分野ですが、幾つかの簡単な技法に対して役に立つ導入を提供し、表現力豊かな型を持つ言語で作業することの威力を示すことができていれば幸いです。
