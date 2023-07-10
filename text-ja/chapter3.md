# 関数とレコード

## この章の目標

この章では、関数及びレコードというPureScriptプログラムの2つの構成要素を導入します。更に、どのようにPureScriptプログラムを構造化するのか、どのように型をプログラム開発に役立てるかを見ていきます。

連絡先のリストを管理する簡単な住所録アプリケーションを作成していきます。
このコード例により、PureScriptの構文から幾つかの新しい概念を導入します。

このアプリケーションのフロントエンドは対話式モードであるPSCiを使うようにしていますが、このコードを土台にJavaScriptでフロントエンドを書くこともできるでしょう。
実際に後の章で、フォームの検証と保存及び復元の機能を追加します。

## プロジェクトの準備

この章のソースコードは `src/Data/AddressBook.purs`というファイルに含まれています。
このファイルは次のようなモジュール宣言とインポート一覧から始まります。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:imports}}
```

ここでは、幾つかのモジュールをインポートします。

- `Prelude`モジュールには標準的な定義と関数の小さな集合が含まれます。
  `purescript-prelude`ライブラリから多くの基礎的なモジュールを再エクスポートしているのです。
- `Control.Plus`モジュールには`empty`値が定義されています。
- `Data.List`モジュールは`lists`パッケージで提供されています。
  またこのパッケージはSpagoを使ってインストールできます。
  モジュールには連結リストを使うために必要な幾つかの関数が含まれています。
- `Data.Maybe`モジュールは、省略可能な値を扱うためのデータ型と関数を定義しています。

訳者注：2つのドット (`..`) を使用すると、
指定された型構築子の全てのデータ構築子をインポートできます。

これらのモジュールのインポート内容が括弧内で明示的に列挙されていることに注目してください（`Prelude`は除きます。これは一括インポートされるのが普通です）。
明示的な列挙はインポート内容の衝突を避けるのに役に立つので、一般に良い習慣です。

ソースコードリポジトリをクローンしたと仮定すると、この章のプロジェクトは次のコマンドでSpagoを使用して構築できます。

```text
$ cd chapter3
$ spago build
```

## 単純な型

JavaScriptの原始型に対応する組み込みデータ型として、PureScriptでは数値型と文字列型、真偽型の3つが定義されています。
これらは`Prim`モジュールで定義されており、全てのモジュールに暗黙にインポートされます。
それぞれ`Number`、`String`、`Boolean`と呼ばれており、PSCiで`:type`コマンドを使うと簡単な値の型を表示させて確認できます。

```text
$ spago repl

> :type 1.0
Number

> :type "test"
String

> :type true
Boolean
```

PureScriptには他にも、整数、文字、配列、レコード、関数といった組み込み型が定義されています。

小数点以下を省くと整数になり、型 `Number`の浮動小数点数の値と区別されます。

```text
> :type 1
Int
```

二重引用符を使用する文字列直値とは異なり、文字直値は一重引用符で囲みます。

```text
> :type 'a'
Char
```

配列はJavaScriptの配列に対応していますが、JavaScriptの配列とは異なり、PureScriptの配列の全ての要素は同じ型を持つ必要があります。

```text
> :type [1, 2, 3]
Array Int

> :type [true, false]
Array Boolean

> :type [1, false]
Could not match type Int with type Boolean.
```

最後の例は型検証器によるエラーを示しています。
配列の2つの要素の型を*単一化*（つまり等価にする意）するのに失敗したのです。

レコードはJavaScriptのオブジェクトに対応しており、レコード直値はJavaScriptのオブジェクト直値と同じ構文になっています。

```text
> author = { name: "Phil", interests: ["Functional Programming", "JavaScript"] }

> :type author
{ name :: String
, interests :: Array String
}
```

この型が示しているのは指定されたオブジェクトが2つの*フィールド*を持っているということです。
`String`型のフィールド`name`と`Array String`型のフィールド`interests`です。
後者はつまり`String`の配列です。

ドットに続けて参照したいフィールドのラベルを書くとレコードのフィールドを参照できます。

```text
> author.name
"Phil"

> author.interests
["Functional Programming","JavaScript"]
```

PureScriptの関数はJavaScriptの関数に対応します。
関数はファイルの最上位で定義でき、等号の前に引数を指定します。

```haskell
import Prelude -- (+) 演算子をスコープに持ち込みます

add :: Int -> Int -> Int
add x y = x + y
```

代えて、バックスラッシュ文字に続けて空白文字で区切られた引数名のリストを書くことで、関数をインラインでも定義できます。
PSCiで複数行の宣言を入力するには、`:paste`コマンドを使用して「貼り付けモード」に入ります。
このモードでは、*Control-D*キーシーケンスを使って宣言を終了します。

```text
> import Prelude
> :paste
… add :: Int -> Int -> Int
… add = \x y -> x + y
… ^D
```

PSCiでこの関数が定義されていると、次のように関数の隣に2つの引数を空白で区切って書くことで、関数をこれらの引数に*適用* (apply) できます。

```text
> add 10 20
30
```

## 字下げについての注意

PureScriptのコードは字下げの大きさに意味があります。ちょうどHaskellと同じで、JavaScriptとは異なります。コード内の空白の多寡は無意味ではなく、Cのような言語で中括弧によってコードのまとまりを示しているように、PureScriptでは空白がコードのまとまりを示すために使われているということです。

宣言が複数行に亙る場合、最初の行以外は最初の行の字下げより深くしなければなりません。

したがって、次は正しいPureScriptコードです。

```haskell
add x y z = x +
  y + z
```

しかし、次は正しいコードではありません。

```haskell
add x y z = x +
y + z
```

後者では、PureScriptコンパイラはそれぞれの行毎に1つ、つまり*2つ*の宣言であると構文解析します。

一般に、同じブロック内で定義された宣言は同じ深さで字下げする必要があります。
例えばPSCiでlet文の宣言は同じ深さで字下げしなければなりません。
次は正しいコードです。

```text
> :paste
… x = 1
… y = 2
… ^D
```

しかし、これは正しくありません。

```text
> :paste
… x = 1
…  y = 2
… ^D
```

PureScriptの幾つかのキーワードは新たなコードのまとまりを導入します。
その中での宣言はそれより深く字下げされなければなりません。

```haskell
example x y z =
  let
    foo = x * y
    bar = y * z
  in
    foo + bar
```

これはコンパイルされません。

```haskell
example x y z =
  let
    foo = x * y
  bar = y * z
  in
    foo + bar
```

より多くを学びたければ（あるいは何か問題に遭遇したら）[構文](https://github.com/purescript/documentation/blob/master/language/Syntax.md#syntax)のドキュメントを参照してください。

## 独自の型の定義

PureScriptで新たな問題に取り組むときは、まずはこれから扱おうとする値の型の定義を書くことから始めるのがよいでしょう。最初に、住所録に含まれるレコードの型を定義してみます。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:Entry}}
```

これは`Entry`という*型同義語*を定義しています。
型`Entry`は等号の右辺と等価ということです。
レコードの型は`firstName`、`lastName`、`phone`という3つのフィールドからなります。
2つの名前のフィールドは型`String`を持ち、`address`は以下で定義された型`Address`を持ちます。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:Address}}
```

なお、レコードには他のレコードを含めることができます。

それでは、住所録のデータ構造として3つめの型同義語も定義してみましょう。
単に項目の連結リストとして表すことにします。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:AddressBook}}
```

なお、`List Entry`は `Array Entry`とは同じではありません。
後者は項目の*配列*を表しています。

## 型構築子と種

`List`は*型構築子*の一例になっています。
`List`そのものは型ではなく、何らかの型 `a`があるとき `List a`が型になっています。
つまり、 `List`は*型引数*`a`を取り、新たな型 `List a`を*構築*するのです。

なお、ちょうど関数適用と同じように、型構築子は他の型に並置するだけで適用されます。
実際、型`List Entry`は型構築子`List`が型`Entry`に*適用*されたもので、項目のリストを表しています。

もし間違って（型注釈演算子 `::`を使って）型 `List`の値を定義しようとすると、今まで見たことのない種類のエラーが表示されるでしょう。

```text
> import Data.List
> Nil :: List
In a type-annotated expression x :: t, the type t must have kind Type
```

これは*種エラー*です。値がその*型*で区別されるのと同じように、型はその*種*によって区別されます。間違った型の値が*型エラー*になるように、*間違った種*の型は*種エラー*を引き起こします。

`Number`や `String`のような、値を持つ全ての型の種を表す `Type`と呼ばれる特別な種があります。

型構築子にも種があります。
例えば種 `Type -> Type`はちょうど `List`のような型から型への関数を表しています。
ここでエラーが発生したのは、値が種 `Type`であるような型を持つと期待されていたのに、 `List`は種 `Type -> Type`を持っているためです。

PSCiで型の種を調べるには、 `:kind`命令を使用します。例えば次のようになります。

```text
> :kind Number
Type

> import Data.List
> :kind List
Type -> Type

> :kind List String
Type
```

PureScriptの _種システム_ は他にも面白い種に対応していますが、それらについては本書の他の部分で見ていくことになるでしょう。

## 量化された型

説明しやすくするため、任意の2つの引数を取り最初のものを返す原始的な関数を定義しましょう。

```text
> :paste
… constantlyFirst :: forall a b. a -> b -> a
… constantlyFirst = \a b -> a
… ^D
```

> なお、`:type`を使って`constantlyFirst`の型について尋ねた場合、もっと冗長になります。
>
> ```text
> : type constantlyFirst
> forall (a :: Type) (b :: Type). a -> b -> a
> ```
>
> 型シグネチャには追加で種の情報が含まれます。
> `a`と`b`が具体的な型であることが明記されています。

この`forall`キーワードは、`constantlyFirst`が*全称量化された型*を持つことを示しています。
つまり`a`や`b`をどの型に置き換えても良く、`constantlyFirst`はその型で動作するのです。

例えば、`a`を`Int`、`b`を`String`と選んだとします。
その場合、`constantlyFirst`の型を次のように*特殊化*できます。

```text
Int -> String -> Int
```

量化された型を特殊化したいということをコードで示す必要はありません。
特殊化は自動的に行われます。
例えば、あたかも既にその型に備わっていたかの如く`constantlyFirst`を使えます。

```text
> constantlyFirst 3 "ignored"

3
```

`a`と`b`にはどんな型でも選べますが、`constantlyFirst`が返す型は最初の引数の型と同じでなければなりません（両方とも同じ`a`に「紐付く」からです）。

```text
:type constantlyFirst true "ignored"
Boolean

:type constantlyFirst "keep" 3
String
```

## 住所録の項目の表示

それでは最初に、文字列で住所録の項目を表現する関数を書いてみましょう。
まずは関数に型を与えることから始めます。
型の定義は省略できますが、ドキュメントとしても役立つので型を書いておくようにすると良いでしょう。
実際、最上位の宣言に型註釈が含まれていないと、PureScriptコンパイラが警告を出します。
型宣言は関数の名前とその型を `::`記号で区切るようにして書きます。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:showEntry_signature}}
```

この型シグネチャが言っているのは、`showEntry`は引数として`Entry`を取り`String`を返す関数であるということです。
以下は`showEntry`のコードです。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:showEntry_implementation}}
```

この関数は`Entry`レコードの3つのフィールドを連結し、単一の文字列にします。
ここで使用される`showAddress`関数は`address`フィールド中のレコードを文字列に変えます。
`showAddress`の定義は次の通りです。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:showAddress}}
```

関数定義は関数の名前で始まり、引数名のリストが続きます。関数の結果は等号の後ろに定義します。フィールドはドットに続けてフィールド名を書くことで参照できます。PureScriptでは、文字列連結はJavaScriptのような単一のプラス記号ではなく、ダイアモンド演算子（`<>`）を使用します。

## はやめにテスト、たびたびテスト

PSCi対話式モードでは反応を即座に得られるので、素早い試作開発に向いています。
それではこの最初の関数が正しく動作するかをPSCiを使用して確認してみましょう。

まず、これまでに書いたコードをビルドします。

```text
$ spago build
```

次に、PSCiを起動し、この新しいモジュールをインポートするために `import`命令を使います。

```text
$ spago repl

> import Data.AddressBook
```

レコード直値を使うと、住所録の項目を作成できます。レコード直値はJavaScriptの無名オブジェクトと同じような構文で名前に束縛します。

```text
> address = { street: "123 Fake St.", city: "Faketown", state: "CA" }
```

それでは、この例に関数を適用してみてください。

```text
> showAddress address

"123 Fake St., Faketown, CA"
```

`showEntry`も、住所の例を含む住所録項目レコードを作って試しましょう。

```text
> entry = { firstName: "John", lastName: "Smith", address: address }
> showEntry entry

"Smith, John: 123 Fake St., Faketown, CA"
```

## 住所録の作成

今度は住所録を扱う補助関数を幾つか書いてみましょう。
空の住所録を表す値が必要ですが、これは空のリストです。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:emptyBook}}
```

既存の住所録に値を挿入する関数も必要でしょう。この関数を `insertEntry`と呼ぶことにします。関数の型を与えることから始めましょう。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:insertEntry_signature}}
```

この型シグネチャに書かれているのは、最初の引数として`Entry`、第2引数として`AddressBook`を取り、新しい`AddressBook`を返すということです。

既存の`AddressBook`を直接変更することはしません。
代わりに、同じデータが含まれている新しい`AddressBook`を返します。
このように`AddressBook`は*不変データ構造*の一例となっています。
これはPureScriptにおける重要な考え方です。
変更はコードの副作用であり、効率良く挙動を探る上で妨げになります。
そのため可能な限り純粋関数や不変なデータにする方が好ましいのです。

`insertEntry`を実装するのに`Data.List`の`Cons`関数が使えます。
この関数の型を見るには、PSCiを起動し `:type`コマンドを使います。

```text
$ spago repl

> import Data.List
> :type Cons

forall (a :: Type). a -> List a -> List a
```

この型シグネチャで書かれているのは、`Cons`が何らかの型`a`の値と型`a`の要素のリストを取り、同じ型の項目を持つ新しいリストを返すということです。
`a`を`Entry`型として特殊化してみましょう。

```haskell
Entry -> List Entry -> List Entry
```

しかし、 `List Entry`はまさに `AddressBook`ですから、次と同じになります。

```haskell
Entry -> AddressBook -> AddressBook
```

今回の場合、既に適切な入力があります。
`Entry`と `AddressBook`に `Cons`を適用すると、新しい `AddressBook`を得ることができます。
これこそがまさに求めていた関数です。

`insertEntry`の実装は次のようになります。

```haskell
insertEntry entry book = Cons entry book
```

こうすると、等号の左側にある2つの引数`entry`と`book`がスコープに導入されます。
それから`Cons`関数を適用し、結果を作成しています。

## カリー化された関数

PureScriptの関数はきっかり1つの引数を取ります。
`insertEntry`関数は2つの引数を取るように見えますが、*カリー化された関数*の一例なのです。
PureScriptでは全ての関数はカリー化されたものと見做されます。

カリー化が意味するのは複数の引数を取る関数を1度に1つ取る関数に変換することです。
関数を呼ぶときに1つの引数を渡し、これまた1つの引数を取る別の関数を返し、といったことを全ての引数が渡されるまで続けます。

例えば`add`に`5`に渡すと別の関数が得られます。
その関数は整数を取り、5を足し、合計を結果として返します。

```haskell
add :: Int -> Int -> Int
add x y = x + y

addFive :: Int -> Int
addFive = add 5
```

`addFive`は*部分適用*の結果です。
つまり複数の引数を取る関数に、引数の全個数より少ない数だけ渡すのです。
試してみましょう。

> なお、お済みでなければ`add`関数を定義しなくてはなりません。
>
> ```text
> > import Prelude
> > :paste
>… add :: Int -> Int -> Int
>… add x y = x + y
>… ^D
> ```

```text
> :paste
… addFive :: Int -> Int
… addFive = add 5
… ^D

> addFive 1
6

> add 5 1
6
```

カリー化と部分適用をもっと理解するには、例にあった`add`とは別の関数を2、3作ってみてください。
そしてそれができたら`insertEntry`に戻りましょう。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:insertEntry_signature}}
```

（型シグネチャ中の）`->`演算子は右結合です。
つまりコンパイラは型を次のように解釈します。

```haskell
Entry -> (AddressBook -> AddressBook)
```

`insertEntry`は単一の引数`Entry`を取り、新しい関数を返します。
そして今度はその関数が単一の引数`AddressBook`を取り、新しい`AddressBook`を返します。

これはつまり、最初の引数だけを与えて`insertEntry`を*部分適用*できたりするということです。
PSCiで結果の型が見られます。

```text
> :type insertEntry entry

AddressBook -> AddressBook
```

期待した通り、戻り値の型は関数になっていました。
この結果の関数に2つ目の引数も適用できます。

```text
> :type (insertEntry entry) emptyBook
AddressBook
```

ただし、ここでの括弧は不要です。
以下は等価です。

```text
> :type insertEntry entry emptyBook
AddressBook
```

これは関数適用が左に結合するためで、空白で区切った引数を次々に関数に指定するだけでいい理由もこれで分かります。

関数の型の`->`演算子は関数の*型構築子*です。
この演算子は2つの型引数を取ります。
左右の被演算子はそれぞれ関数の引数の型と返り値の型です。

本書では今後、「2引数の関数」というように表現することがあることに注意してください。
しかしそれはカリー化された関数を意味していると考えるべきで、その関数は最初の引数を取り2つ目の引数を取る別の関数を返すのです。

今度は `insertEntry`の定義について考えてみます。

```haskell
insertEntry :: Entry -> AddressBook -> AddressBook
insertEntry entry book = Cons entry book
```

もし式の右辺に明示的に括弧をつけるなら、`(Cons entry) book`となります。
つまり`insertEntry entry`はその引数が単に関数`(Cons entry)`に渡されるような関数だということです。
ところがこの2つの関数はどんな入力についても同じ結果を返すので、となると同じ関数ではないですか。
よって、両辺から引数`book`を削除できます。

```haskell
insertEntry :: Entry -> AddressBook -> AddressBook
insertEntry entry = Cons entry
```

しかし今や同様の議論により、両辺から `entry`も削除できます。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:insertEntry}}
```

この処理は*イータ変換*と呼ばれ、（その他の技法を併用して）*ポイントフリー形式*へと関数を書き換えるのに使えます。
つまり、引数を参照せずに関数を定義できるのです。

`insertEntry`の場合、イータ変換によって「`insertEntry`は単にリストにおけるconsだ」となり、とても明快な関数の定義になりました。
しかし、一般にポイントフリー形式のほうがいいのかどうかには議論の余地があります。

## プロパティ取得子

よくあるパターンの1つとして、レコード中の個別のフィールド（または「プロパティ」）を取得することがあります。
`Entry`から`Address`を取り出すインライン関数は次のように書けます。

```haskell
\entry -> entry.address
```

PureScriptでは[_プロパティ取得子_](https://github.com/purescript/documentation/blob/master/language/Syntax.md#property-accessors)という略記が使えます。この略記では下線文字は無名関数の引数として振舞うため、上記のインライン関数は次と等価です。

```haskell
_.address
```

これは何段階のプロパティでも動くため、`Entry`に関連する街を取り出す関数は次のように書けます。

```haskell
_.address.city
```

以下は一例です。

```text
> address = { street: "123 Fake St.", city: "Faketown", state: "CA" }
> entry = { firstName: "John", lastName: "Smith", address: address }
> _.lastName entry
"Smith"

> _.address.city entry
"Faketown"
```

## 住所録に問い合わせる

最小限の住所録アプリケーションの実装で必要になる最後の関数は、名前で人を検索し適切な`Entry`を返すものです。
これは小さな関数を組み合わせることでプログラムを構築するという、関数型プログラミングで鍵となる考え方のよい応用例になるでしょう。

住所録を絞り込めば該当する姓名を持つ項目だけを保持するようにできます。
そうすれば結果のリストの先頭（つまり最初）の要素を返せます。

この大まかな道筋の仕様があれば関数の型を計算できます。
まずPSCiを開いて`filter`関数と`head`関数の型を探してみましょう。

```text
$ spago repl

> import Data.List
> :type filter

forall (a :: Type). (a -> Boolean) -> List a -> List a

> :type head

forall (a :: Type). List a -> Maybe a
```

型の意味を理解するために、これらの2つの型の一部を取り出してみましょう。

`filter`は2引数のカリー化された関数です。
最初の引数は関数で、リストの要素を取り`Boolean`値を返します。
第2引数は要素のリストで、返り値は別のリストです。

`head`は引数としてリストを取り、 `Maybe a`という今までに見たことがない型を返します。
`Maybe
a`は型`a`の省略可能な値を表しており、JavaScriptのような言語で値がないことを示すための`null`を使う代わりとなる、型安全な代替を提供します。
後の章で改めて詳しく見ていきます。

`filter`と `head`の全称量化された型は、PureScriptコンパイラによって次のように _特殊化_ (specialized)
されます。

```haskell
filter :: (Entry -> Boolean) -> AddressBook -> AddressBook

head :: AddressBook -> Maybe Entry
```

関数の引数として姓名を渡す必要があるだろうということは分かっています。

`filter`に渡す関数も必要になることもわかります。この関数を `filterEntry`と呼ぶことにしましょう。 `filterEntry`は `Entry -> Boolean`という型を持っています。 `filter filterEntry`という関数適用の式は、 `AddressBook -> AddressBook`という型を持つでしょう。もしこの関数の結果を `head`関数に渡すと、型 `Maybe Entry`の結果を得ることになります。

これまでのことを纏めると、関数の妥当な型シグネチャは次のようになります。`findEntry`と呼ぶことにしましょう。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:findEntry_signature}}
```

この型シグネチャで書かれているのは、`findEntry`が姓と名前の2つの文字列及び`AddressBook`を引数に取り、省略可能な`Entry`を返すということです。
省略可能な結果は名前が住所録に見付かった場合にのみ値を持ちます。

そして、 `findEntry`の定義は次のようになります。

```haskell
findEntry firstName lastName book = head (filter filterEntry book)
  where
    filterEntry :: Entry -> Boolean
    filterEntry entry = entry.firstName == firstName && entry.lastName == lastName
```

一歩ずつこのコードを調べてみましょう。

`findEntry`は、どちらも文字列型である `firstName`と `lastName`、`AddressBook`型の
`book`という3つの名前をスコープに導入します。

定義の右辺では`filter`関数と`head`関数が組み合わさっています。
まず項目のリストを絞り込み、その結果に`head`関数を適用しています。

真偽型を返す関数 `filterEntry`は `where`節の内部で補助的な関数として定義されています。
このため、 `filterEntry`関数はこの定義の内部では使用できますが、外部では使用できません。
また、`filterEntry`はそれを包む関数の引数に依存でき、 `filterEntry`は指定された `Entry`を絞り込むために引数
`firstName`と `lastName`を使用しているので、 `filterEntry`が
`findEntry`の内部にあることは必須になっています。

なお、最上位での宣言と同じように、必ずしも`filterEntry`の型シグネチャを指定しなくても構いません。
ただし、ドキュメントの一形態として指定しておくことが推奨されます。

## 中置の関数適用

これまでお話しした関数のほとんどは*前置*関数適用でした。
関数名が引数の*前*に置かれていたということです。
例えば`insertEntry`関数を使って`Entry` (`john`) を空の`AddressBook`に追加する場合、以下のように書けます。

```haskell
> book1 = insertEntry john emptyBook
```

しかし本章には*中置*[2引数演算子](https://github.com/purescript/documentation/blob/master/language/Syntax.md#binary-operators)の例も含まれています。
`filterEntry`の定義中の`==`演算子がそうで、2つの引数の*間*に置かれています。
PureScriptのソースコードでこうした中置演算子は隠れた*前置*の実装への中置別称として定義されています。
例えば`==`は以下の行により前置の`eq`関数の中置別称として定義されています。

```haskell
infix 4 eq as ==
```

したがって`filterEntry`中の`entry.firstName == firstName`は`eq entry.firstName
firstName`で置き換えられます。
この節の後のほうで中置演算子を定義する例にもう少し触れます。

前置関数を演算子としての中置の位置に置くと、より読みやすいコードになる場面があります。
その一例が`mod`関数です。

```text
> mod 8 3
2
```

上の用例でも充分動作しますが、読みにくいです。
より馴染みのある表現の仕方は「8 mod 3」です。
バックスラッシュ (\`) の中に前置関数を包むとそのように書けます。

```text
> 8 `mod` 3
2
```

同様に、`insertEntry`をバックスラッシュで包むと中置演算子に変わります。
例えば以下の`book1`と`book2`は等価です。

```haskell
book1 = insertEntry john emptyBook
book2 = john `insertEntry` emptyBook
```

複数回`insertEntry`を適用することで複数の項目がある`AddressBook`を作ることができますが、以下のように前置関数
(`book3`) として適用するか中置演算子 (`book4`) として適用するかの2択があります。

```haskell
book3 = insertEntry john (insertEntry peggy (insertEntry ned emptyBook))
book4 = john `insertEntry` (peggy `insertEntry` (ned `insertEntry` emptyBook))
```

`insertEntry`には中置演算子別称（または同義語）も定義できます。
この演算子の名前に適当に`++`を選び、[優先度](https://github.com/purescript/documentation/blob/master/language/Syntax.md#precedence)を`5`にし、そして`infixr`を使って右[結合](https://github.com/purescript/documentation/blob/master/language/Syntax.md#associativity)とします。

```haskell
infixr 5 insertEntry as ++
```

この新しい演算子で上の`book4`の例を次のように書き直せます。

```haskell
book5 = john ++ (peggy ++ (ned ++ emptyBook))
```

新しい`++`演算子の右結合性により、意味を変えずに括弧を除去できます。

```haskell
book6 = john ++ peggy ++ ned ++ emptyBook
```

括弧を消去する他のよくある技法は、いつもの前置関数と一緒に`apply`の中置演算子`$`を使うというものです。

例えば前の`book3`の例は以下のように書き直せます。

```haskell
book7 = insertEntry john $ insertEntry peggy $ insertEntry ned emptyBook
```

括弧を`$`で置き換えるのは大抵入力しやすくなりますし（議論の余地がありますが）読みやすくなります。
この記号の意味を覚えるための記憶術として、ドル記号を2つの括弧に打ち消し線が引かれたものと見ることで、これで括弧が不必要になったのだと推測できるという方法があります。

なお、`($)`は言語にハードコードされた特別な構文ではありません。
単に`apply`という名前の普通の関数のための中置演算子であって、`Data.Function`で以下のように定義されています。

```haskell
apply :: forall a b. (a -> b) -> a -> b
apply f x = f x

infixr 0 apply as $
```

`apply`関数は、他の関数（型は`(a -> b)`）を最初の引数に、値（型は`a`）を2つ目の引数に取って、その値に対して関数を呼びます。
この関数が何ら意味のあることをしていないようだと思ったら、全くもって正しいです。
この関数がなくてもプログラムは論理的に同一です（[参照透過性](https://en.wikipedia.org/wiki/Referential_transparency)も見てください）。
この関数の構文的な利便性はその中置演算子に割り当てられた特別な性質からきています。
`$`は右結合 (`infixr`) で低い優先度 (`0`) の演算子ですが、これにより深い入れ子になった適用から括弧の束を削除できるのです。

さらなる`$`演算子を使った括弧退治のチャンスは以前の`findEntry`関数にあります。

```haskell
findEntry firstName lastName book = head $ filter filterEntry book
```

この行をより簡潔に書き換える方法を次節の「関数合成」で見ていきます。

名前の短い中置演算子を前置関数として使いたければ括弧で囲むことができます。

```text
> 8 + 3
11

> (+) 8 3
11
```

その代わりの手段として演算子は部分適用でき、これには式を括弧で囲んで[演算子節](https://github.com/purescript/documentation/blob/master/language/Syntax.md#operator-sections)中の引数として`_`を使います。これは簡単な無名関数を作るより便利な方法として考えることができます（以下の例ではそこから無名関数を名前に束縛しているので、もはや別に無名とも言えなくなっていますが）。

```text
> add3 = (3 + _)
> add3 2
5
```

纏めると、以下は引数に`5`を加える関数の等価な定義です。

```haskell
add5 x = 5 + x
add5 x = add 5 x
add5 x = (+) 5 x
add5 x = 5 `add` x
add5   = add 5
add5   = \x -> 5 + x
add5   = (5 + _)
add5 x = 5 `(+)` x  -- よおポチ、中置に目がないっていうから、中置の中に中置を入れといたぜ
```

## 関数合成

イータ変換を使うと `insertEntry`関数を簡略化できたのと同じように、引数をよく考察すると `findEntry`の定義を簡略化できます。

なお、引数 `book`は関数 `filter filterEntry`に渡され、この適用の結果が `head`に渡されます。これは言いかたを変えれば、
`filter filterEntry`と `head`の _合成_ (composition) に `book`が渡されるということです。

PureScriptの関数合成演算子は `<<<`と `>>>`です。前者は「逆方向の合成」であり、後者は「順方向の合成」です。

何れかの演算子を使用して `findEntry`の右辺を書き換えることができます。
逆順の合成を使用すると、右辺は次のようになります。

```haskell
(head <<< filter filterEntry) book
```

この形式なら最初の定義にイータ変換の技を適用でき、 `findEntry`は最終的に次のような形式に到達します。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:findEntry_implementation}}
    ...
```

右辺を次のようにしても同じく妥当です。

```haskell
filter filterEntry >>> head
```

どちらにしても、これは「`findEntry`は絞り込み関数と`head`関数の合成である」という
`findEntry`関数のわかりやすい定義を与えます。

どちらの定義のほうが分かりやすいかの判断はお任せしますが、このように関数を部品として捉えるとしばしば有用です。
各関数は1つの役目をこなすようにし、解法を関数合成を使って組み立てるのです。

## 演習

 1. （簡単）`findEntry`関数の定義の主な部分式の型を書き下し、 `findEntry`関数についてよく理解しているか試してみましょう。
    例えば`findEntry`の定義の中にある `head`関数の型は `AddressBook -> Maybe
    Entry`と特殊化されています。
    *補足*：この問題にはテストがありません。
 1. （普通）関数`findEntryByStreet :: String -> AddressBook -> Maybe
    Entry`を書いてください。
    この関数は与えられた通りの住所から`Entry`を見付け出します。
    *手掛かり*：`findEntry`にある既存のコードを再利用してください。
    実装した関数をPSCiと`spago test`を走らせてテストしてください。
 1. （普通）`filterEntry`を（`<<<`や`>>>`を使った）合成で置き換えて、`findEntryByStreet`を書き直してください。
    合成の対象は、プロパティ取得子（`_.`記法を使います）と、与えられた文字列引数が与えられた通りの住所に等しいかを判定する関数です。
 1. （普通）名前が`AddressBook`に存在するかどうかを調べて真偽値で返す関数`isInBook`を書いてみましょう。
    *手掛かり*：PSCiを使って`Data.List.null`関数の型を見付けてください。
    この関数はリストが空かどうかを調べます。
 1. （難しい）「重複」している住所録の項目を削除する関数`removeDuplicates`を書いてみましょう。
    項目が同じ姓名を共有していれば`address`フィールドに関係なく、項目が重複していると考えます。
    *手掛かり*：`Data.List.nubByEq`関数の型をPSCiを使って調べましょう。
    この関数は等価性の述語に基づいてリストから重複要素を削除します。
    なお、それぞれの重複する項目の集合において最初の要素（リストの先頭に最も近い）が保持する項目です。

## まとめ

この章では関数型プログラミングの新しい概念を幾つか押さえ、以下の方法を学びました。

- 対話的モードのPSCiを使用して、関数で実験したり思いついたことを試したりする。
- 正確さのための道具として、また実装のための道具として型を使う。
- 多引数の関数を表現するためにカリー化された関数を使う。
- 合成により小さな部品からプログラムを作る。
- `where`式を使ってコードを手際良く構造化する。
- `Maybe`型を使用してnull値を回避する。
- イータ変換や関数合成のような技法を使ってより分かりやすい仕様にリファクタする。

次の章からは、これらの考えかたに基づいて進めていきます。
