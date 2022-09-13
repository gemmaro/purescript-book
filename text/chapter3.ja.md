# 関数とレコード

## この章の目標

この章では、関数およびレコードというPureScriptプログラムの2つの構成要素を導入します。
さらに、どのようにPureScriptプログラムを構造化するのか、どのように型をプログラム開発に役立てるかを見ていきます。

連絡先のリストを管理する簡単​​な住所録アプリケーションを作成していきます。このコード例により、PureScriptの構文からいくつかの新しい概念を導入します。

このアプリケーションのフロントエンドは対話式モードであるPSCiを使うようにしていますが、このコードを土台にJavaScriptでフロントエンドを書くこともできるでしょう。
実際に後の章で、フォームの検証と保存および復元の機能を追加します。

## プロジェクトの準備

この章のソースコードは `src/Data/AddressBook.purs`というファイルに含まれています。
このファイルは次のようなモジュール宣言とインポート一覧から始まります。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:imports}}
```

ここでは、いくつかのモジュールをインポートします。

- `Control.Plus`モジュールには`empty`値が定義されています。
- `Data.List`モジュールは`lists`パッケージで提供されておりSpagoを使ってインストールできます。
  連結リストを使うために必要ないくつかの関数が含まれています。
- `Data.Maybe`モジュールは、オプショナルな値を扱うためのデータ型と関数を定義しています。

訳者注：ダブルドット (`..`) を使用すると、
指定された型コンストラクタのすべてのデータコンストラクタをインポートできます。

このモジュールのインポート内容が括弧内で明示的に列挙されていることに注目してください。明示的な列挙はインポート内容の衝突を避けるのに役に立つので、一般に良い習慣です。

ソースコードリポジトリを複製したと仮定すると、この章のプロジェクトは次のコマンドでSpagoを使用して構築できます。

```text
$ cd chapter3
$ spago build
```

## 単純な型

JavaScriptのプリミティブ型に対応する組み込みデータ型として、PureScriptでは数値型と文字列型、真偽型の３つが定義されています。
これらは`Prim`モジュールで定義されており、全てのモジュールに暗黙にインポートされます。
これらはそれぞれ `Number`、 `String`、
`Boolean`と呼ばれており、PSCiで`:type`コマンドを使うと簡単な値の型を表示させて確認できます。

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

整数は、小数点以下を省くことによって、型 `Number`の浮動小数点数の値と区別されます。

```text
> :type 1
Int
```

二重引用符を使用する文字列リテラルとは異なり、文字リテラルは一重引用符で囲みます。

```text
> :type 'a'
Char
```

配列はJavaScriptの配列に対応していますが、JavaScriptの配列とは異なり、PureScriptの配列のすべての要素は同じ型を持つ必要があります。

```text
> :type [1, 2, 3]
Array Int

> :type [true, false]
Array Boolean

> :type [1, false]
Could not match type Int with type Boolean.
```

最後の例で起きているエラーは型検証器によって報告されたもので、
配列の2つの要素の型を**単一化**（Unification、等価にするの意）しようとして失敗したことを示しています。

レコードはJavaScriptのオブジェクトに対応しており、レコードリテラルはJavaScriptのオブジェクトリテラルと同じ構文になっています。

```text
> author = { name: "Phil", interests: ["Functional Programming", "JavaScript"] }

> :type author
{ name :: String
, interests :: Array String
}
```

この型が示しているのは、指定されたオブジェクトは、 `String`型のフィールド `name` と `Array String`つまり
`String`の配列の型のフィールド `interests` という２つの**フィールド** (field) を持っているということです。

レコードのフィールドは、ドットに続けて参照したいフィールドのラベルを書くと参照することができます。

```text
> author.name
"Phil"

> author.interests
["Functional Programming","JavaScript"]
```

PureScriptの関数はJavaScriptの関数に対応しています。PureScriptの標準ライブラリは多くの関数の例を提供しており、この章ではそれらをもう少し詳しく見ていきます。

```text
> import Prelude
> :type flip
forall a b c. (a -> b -> c) -> b -> a -> c

> :type const
forall a b. a -> b -> a
```

ファイルのトップレベルでは、等号の直前に引数を指定することで関数を定義することができます。

```haskell
add :: Int -> Int -> Int
add x y = x + y
```

バックスラッシュに続けて空白文字で区切られた引数名のリストを書くことで、関数をインラインで定義することもできます。
PSCiで複数行の宣言を入力するには、 `:paste`コマンドを使用して「貼り付けモード」に入ります。
このモードでは、**Control-D**キーシーケンスを使用して宣言を終了します。

```text
> :paste
… add :: Int -> Int -> Int
… add = \x y -> x + y
… ^D
```

PSCiでこの関数が定義されていると、次のように関数の隣に２つの引数を空白で区切って書くことで、関数をこれらの引数に**適用** (apply)
することができます。

```text
> add 10 20
30
```

## 量化された型

前の節ではPreludeで定義された関数の型をいくつか見てきました。たとえば `flip`関数は次のような型を持っていました。

```text
> :type flip
forall a b c. (a -> b -> c) -> b -> a -> c
```

この `forall`キーワードは、 `flip`が**全称量化された型** (universally quantified type)
を持っていることを示しています。
これは、 `a`や `b`、 `c`をどの型に置き換えても、 `flip`はその型でうまく動作するという意味です。

例えば、 `a`を `Int`、 `b`を `String`、 `c`を `String`というように選んでみたとします。
この場合、 `flip`の型を次のように**特殊化** (specialize) することができます。

```text
(Int -> String -> String) -> String -> Int -> String
```

量化された型を特殊化したいということをコードで示す必要はありません。特殊化は自動的に行われます。たとえば、すでにその型の
`flip`を持っていたかのように、次のように単に `flip`を使用することができます。

```text
> flip (\n s -> show n <> s) "Ten" 10

"10Ten"
```

`a`、 `b`、 `c`の型はどんな型でも選ぶことができるといっても、型の不整合は生じないようにしなければなりません。
`flip`に渡す関数の型は、他の引数の型と整合性がなくてはなりません。第２引数として文字列 `"Ten"`、第３引数として数
`10`を渡したのはそれが理由です。もし引数が逆になっているとうまくいかないでしょう。

```text
> flip (\n s -> show n <> s) 10 "Ten"

Could not match type Int with type String
```

## 字下げについての注意

JavaScriptとは異なり、PureScriptのコードは字下げの大きさに影響されます (indentation-sensitive)。
これはHaskellと同じようになっています。
コード内の空白の多寡は無意味ではなく、Cのような言語で中括弧によってコードのまとまりを示しているように、PureScriptでは空白がコードのまとまりを示すのに使われているということです。

宣言が複数行にわたる場合は、最初の行以外は最初の行の字下げより深く字下げしなければなりません。

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

後者では、PureScriptコンパイラはそれぞれの行ごとにひとつ、つまり**2つ**の宣言であると構文解析します。

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

PureScriptのいくつかの予約語（例えば `where`や `of`、
`let`）は新たなコードのまとまりを導入しますが、そのコードのまとまり内の宣言はそれより深く字下げされている必要があります。

```haskell
example x y z = foo + bar
  where
    foo = x * y
    bar = y * z
```

ここで `foo`や `bar`の宣言は `example`の宣言より深く字下げされていることに注意してください。

ただし、ソースファイルの先頭、最初の `module`宣言における予約語 `where`だけは、この規則の唯一の例外になっています。

## 独自の型の定義

PureScriptで新たな問題に取り組むときは、まずはこれから扱おうとする値の型の定義を書くことから始めるのがよいでしょう。最初に、住所録に含まれるレコードの型を定義してみます。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:Entry}}
```

これは `Entry`という**型同義語** (type synonym、型シノニム) を定義しています。
型 `Entry`は等号の右辺と同じ型ということです。
レコードの型はいずれも文字列である `firstName`、 `lastName`、 `phone`という３つのフィールドからなります。
前者の２つのフィールドは型 `String`を持ち、 `address`は以下のように定義された型 `Address`を持っています。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:Address}}
```

なお、レコードには他のレコードを含めることができます。

それでは、3つめの型同義語も定義してみましょう。住所録のデータ構造としては、単に項目の連結リストとして格納することにします。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:AddressBook}}
```

`List Entry`は `Array Entry`とは同じではないということに注意してください。 `Array
Entry`は住所録の項目の**配列**を意味しています。

## 型構築子と種

`List`は**型構築子**（type constructor、型コンストラクタ）の一例になっています。
`List`そのものは型ではなく、何らかの型 `a`があるとき `List a`が型になっています。
つまり、 `List`は**型引数** (type argument) `a`をとり、新たな型 `List a`を**構築**するのです。

ちょうど関数適用と同じように、型構築子は他の型に並べることで適用されることに注意してください。型 `List　Entry`は実は型構築子
`List`が型 `Entry`に**適用**されたものです。これは住所録項目のリストを表しています。

（型注釈演算子 `::`を使って）もし型 `List`の値を間違って定義しようとすると、今まで見たことのないような種類のエラーが表示されるでしょう。

```text
> import Data.List
> Nil :: List
In a type-annotated expression x :: t, the type t must have kind Type
```

これは**種エラー** (kind error) です。
値がその**型**で区別されるのと同じように、型はその**種** (kind)
によって区別され、間違った型の値が**型エラー**になるように、**間違った種**の型は**種エラー**を引き起こします。

`Number`や `String`のような、値を持つすべての型の種を表す `Type`と呼ばれる特別な種があります。

型構築子にも種があります。
たとえば、種 `Type -> Type`はちょうど `List`のような型から型への関数を表しています。
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

PureScriptの**種システム**は他にも面白い種に対応していますが、それらについては本書の他の部分で見ていくことになるでしょう。

## 住所録の項目の表示

それでは最初に、文字列で住所録の項目を表現するような関数を書いてみましょう。
まずは関数に型を与えることから始めます。
型の定義は省略することも可能ですが、ドキュメントとしても役立つので型を書いておくようにすると良いでしょう。
実際、トップレベルの宣言に型註釈が含まれていないと、PureScriptコンパイラが警告を出します。
型宣言は関数の名前とその型を `::`記号で区切るようにして書きます。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:showEntry_signature}}
```

`showEntry`は引数として `Entry`を取り `string`を返す関数であるということを、この型シグネチャは言っています。
`showEntry`のコードは次のとおりです。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:showEntry_implementation}}
```

この関数は `Entry`レコードの3つのフィールドを連結し、単一の文字列にします。ここで使用される `showAddress`は
`address`フィールドを連接し、単一の文字列にする関数です。 `showAddress`の定義は次のとおりです。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:showAddress}}
```

関数定義は関数の名前で始まり、引数名のリストが続きます。関数の結果は等号の後ろに定義します。フィールドはドットに続けてフィールド名を書くことで参照することができます。PureScriptでは、文字列連結はJavaScriptのような単一のプラス記号ではなく、ダイアモンド演算子（ `<>`）を使用します。

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

レコードリテラルを使うと、住所録の項目を作成することができます。レコードリテラルはJavaScriptの無名オブジェクトと同じような構文で名前に束縛します。

```text
> address = { street: "123 Fake St.", city: "Faketown", state: "CA" }
```

​それでは、この例に関数を適用してみてください。

```text
> showAddress address

"123 Fake St., Faketown, CA"
```

`showEntry`も、住所を含む住所録項目の記録例を作って試しましょう。

```text
> entry = { firstName: "John", lastName: "Smith", address: address }
> showEntry entry

"Smith, John: 123 Fake St., Faketown, CA"
```

## 住所録の作成

今度は住所録の操作を支援する関数をいくつか書いてみましょう。
空の住所録を表す値が必要ですが、これには空のリストを使います。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:emptyBook}}
```

既存の住所録に値を挿入する関数も必要でしょう。この関数を `insertEntry`と呼ぶことにします。関数の型を与えることから始めましょう。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:insertEntry_signature}}
```

この型シグネチャに書かれているのは、最初の引数として `Entry`、第二引数として `AddressBook`を取り、新しい
`AddressBook`を返すということです。

既存の `AddressBook`を直接変更することはしません。
その代わりに、同じデータが含まれている新しい `AddressBook`を返すようにします。
このように、 `AddressBook`は**不変データ構造** (immutable data structure) の一例となっています。
これはPureScriptにおける重要な考え方です。
変更はコードの副作用であり、効率の良いコードの振る舞いの判断を妨げます。
そのため、我々は可能な限り純粋な関数や不変のデータを好むのです。

`insertEntry`を実装するのに`Data.List`の`Cons`関数が使えます。
この関数の型を見るには、PSCiを起動し `:type`コマンドを使います。

```text
$ spago repl

> import Data.List
> :type Cons

forall a. a -> List a -> List a
```

`Cons`は、なんらかの型 `a`の値と、型
`a`を要素に持つリストを引数にとり、同じ型の要素を持つ新しいリストを返すということを、この型シグネチャは言っています。 `a`を
`Entry`型として特殊化してみましょう。

```haskell
Entry -> List Entry -> List Entry
```

しかし、 `List Entry`はまさに `AddressBook`ですから、次と同じになります。

```haskell
Entry -> AddressBook -> AddressBook
```

今回の場合、すでに適切な入力があります。 `Entry`と `AddressBook`に `Cons`を適用すると、新しい
`AddressBook`を得ることができます。これこそまさに私たちが求めていた関数です！

`insertEntry`の実装は次のようになります。

```haskell
insertEntry entry book = Cons entry book
```

等号の左側にある２つの引数 `entry`と `book`がスコープに導入されますから、これらに `Cons`関数を適用して結果の値を作成しています。

## カリー化された関数

PureScriptでは、関数は常にひとつの引数だけを取ります。
`insertEntry`関数は２つの引数を取るように見えますが、これは実際には**カリー化された関数** (curried function)
の一例となっています。

`insertEntry`の型に含まれる `->`は右結合の演算子であり、つまりこの型はコンパイラによって次のように解釈されます。

```haskell
Entry -> (AddressBook -> AddressBook)
```

すなわち、 `insertEntry`は関数を返す関数である、ということです！この関数は単一の引数 `Entry`を取り、それから単一の引数
`AddressBook`を取り新しい `AddressBook`を返す新しい関数を返すのです。

これは例えば、最初の引数だけを与えると `insertEntry`を**部分適用** (partial application)
できることを意味します。
PSCiでこの結果の型を見てみましょう。

```text
> :type insertEntry entry

AddressBook -> AddressBook
```

期待したとおり、戻り値の型は関数になっていました。
この結果の関数に、2つ目の引数を適用することもできます。

```text
> :type (insertEntry entry) emptyBook
AddressBook
```

ここで括弧は不要であることにも注意してください。次の式は同等です。

```text
> :type insertEntry entry emptyBook
AddressBook
```

これは関数適用が左結合であるためで、
なぜ単に空白で区切るだけで関数に引数を与えることができるのかの説明にもなっています。

関数の型の`->`演算子は関数の**型構築子**です。
この演算子は2つの型引数を取ります。
左右の被演算子はそれぞれ関数の引数の型と返値の型です。

本書では今後、「2引数の関数」というように表現することがあることに注意してください。
しかしそれはカリー化された関数を意味していると考えるべきで、その関数は最初の引数を取り2つ目の引数を取る別の関数を返すのです。

今度は `insertEntry`の定義について考えてみます。

```haskell
insertEntry :: Entry -> AddressBook -> AddressBook
insertEntry entry book = Cons entry book
```

もし式の右辺に明示的に括弧をつけるなら、 `(Cons entry) book`となります。
`insertEntry entry`はその引数が単に関数 `(Cons entry)`に渡されるような関数だということです。
でもこの2つの関数はどんな入力についても同じ結果を返しますから、つまりこれらは同じ関数です！
よって、両辺から引数 `book`を削除できます。

```haskell
insertEntry :: Entry -> AddressBook -> AddressBook
insertEntry entry = Cons entry
```

しかし今や同様の議論により、両辺から `entry`も削除することができます。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:insertEntry}}
```

この処理は**イータ変換** (eta conversion)
と呼ばれ、（その他の技法を併用して）引数を参照することなく関数を定義する**ポイントフリー形式** (point-free form)
へと関数を書き換えるのに使うことができます。

`insertEntry`の場合には、イータ変換によって「`insertEntry`は単にリストに対するconsだ」となり、関数の定義はとても明確になりました。
しかしながら、一般的にポイントフリー形式のほうがいいのかどうかには議論の余地があります。

## プロパティ取得子

よくあるパターンの1つとして、レコード中の個別のフィールド（または「プロパティ」）を取得することがあります。
`Entry`から`Address`を取り出すインライン関数は次のように書けます。

```haskell
\entry -> entry.address
```

PureScriptでは[**プロパティ取得子**](https://github.com/purescript/documentation/blob/master/language/Syntax.md#property-accessors)という略記が使えます。
この略記では下線文字は無名関数の引数として振舞うため、上記のインライン関数は次と等価です。

```haskell
_.address
```

これは何段階のプロパティでも動くため、`Entry`に関連付く街を取り出す関数は次のように書けます。

```haskell
_.address.city
```

以下は例です。

```text
> address = { street: "123 Fake St.", city: "Faketown", state: "CA" }
> entry = { firstName: "John", lastName: "Smith", address: address }
> _.lastName entry
"Smith"

> _.address.city entry
"Faketown"
```

## あなたの住所録は？

最小限の住所録アプリケーションの実装で必要になる最後の関数は、名前で人を検索し適切な
`Entry`を返すものです。これは小さな関数を組み合わせることでプログラムを構築するという、関数型プログラミングで鍵となる考え方のよい応用例になるでしょう。

まずは住所録をフィルタリングし、該当する姓名を持つ項目だけを保持するようにするのがいいでしょう。それから、結果のリストの先頭の (head)
要素を返すだけです。

この大まかな仕様に従って、この関数の型を計算することができます。
まずPSCiを起動し、 `filter`関数と `head`関数の型を見てみましょう。

```text
$ spago repl

> import Data.List
> :type filter

forall a. (a -> Boolean) -> List a -> List a

> :type head

forall a. List a -> Maybe a
```

型の意味を理解するために、これらの2つの型の一部を取り出してみましょう。

`filter`はカリー化された2引数の関数です。
最初の引数は、リストの要素を取り `Boolean`値を結果として返す関数です。
第2引数は要素のリストで、返り値は別のリストです。

`head`は引数としてリストをとり、 `Maybe a`という今まで見たことがないような型を返します。 `Maybe a`は型
`a`のオプショナルな値、つまり
`a`の値を持つか持たないかのどちらかの値を示しており、JavaScriptのような言語で値がないことを示すために使われる
`null`の型安全な代替手段を提供します。これについては後の章で詳しく扱います。

`filter`と `head`の全称量化された型は、PureScriptコンパイラによって次のように**特殊化** (specialized)
されます。

```haskell
filter :: (Entry -> Boolean) -> AddressBook -> AddressBook

head :: AddressBook -> Maybe Entry
```

検索する関数の引数として姓と名前を渡す必要があるのもわかっています。

`filter`に渡す関数も必要になることもわかります。この関数を `filterEntry`と呼ぶことにしましょう。 `filterEntry`は `Entry -> Boolean`という型を持っています。 `filter filterEntry`という関数適用の式は、 `AddressBook -> AddressBook`という型を持つでしょう。もしこの関数の結果を `head`関数に渡すと、型 `Maybe Entry`の結果を得ることになります。

これまでのことをまとめると、関数の妥当な型シグネチャは次のようになります。
`findEntry`と呼ぶことにしましょう。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:findEntry_signature}}
```

`findEntry`は、姓と名前の2つの文字列、および `AddressBook`を引数にとり、
`Entry`のオプション型の値を結果として返すということを、この型シグネチャは言っています。
オプショナルな結果は、名前が住所録で発見された場合にのみ値を持ちます。

そして、 `findEntry`の定義は次のようになります。

```haskell
findEntry firstName lastName book = head (filter filterEntry book)
  where
    filterEntry :: Entry -> Boolean
    filterEntry entry = entry.firstName == firstName && entry.lastName == lastName
```

一歩ずつこのコードを調べてみましょう。

`findEntry`は、
どちらも文字列型である `firstName`と `lastName`、
`AddressBook`型の `book`という3つの名前をスコープに導入します。

定義の右辺では `filter`関数と `head`関数が組み合わされています。まず項目のリストをフィルタリングし、その結果に
`head`関数を適用しています。

真偽型を返す関数 `filterEntry`は `where`節の内部で補助的な関数として定義されています。このため、
`filterEntry`関数はこの定義の内部では使用できますが、外部では使用することができません。また、
`filterEntry`はそれを包む関数の引数に依存することができ、 `filterEntry`は指定された
`Entry`をフィルタリングするために引数 `firstName`と `lastName`を使用しているので、 `filterEntry`が
`findEntry`の内部にあることは必須になっています。

最上位での宣言と同じように、必ずしも
`filterEntry`の型シグネチャを指定しなくてもよいことに注意してください。ただし、ドキュメントとしても役に立つので型シグネチャを書くことは推奨されています。

## 中置の関数適用

これまでお話しした関数のほとんどは**前置**関数適用でした。
関数名が引数の**前**に置かれていたということです。
例えば`insertEntry`関数を使って`Entry` (`john`) を空の`AddressBook`に追加する場合、以下のように書けます。

```haskell
> book1 = insertEntry john emptyBook
```

しかしこの章には**中置**[2引数演算子](https://github.com/purescript/documentation/blob/master/language/Syntax.md#binary-operators)の例も含まれています。
例えば`filterEntry`の定義中の`==`演算子で、演算子が2つの引数の**間**に置かれています。
実はこうした中置演算子はPureScriptのソースコードで、
背後にある**前置**版の実装への中置別称として定義されています。
例えば`==`は以下の行により前置の`eq`関数の中置別称として定義されています。

```haskell
infix 4 eq as ==
```

したがって`filterEntry`中の`entry.firstName == firstName`は`eq entry.firstName
firstName`で置き換えられます。
この節の後のほうで中置演算子を定義する例をもう少し押さえます。

前置関数を演算子としての中置の位置に置くとより読みやすいコードになる場面があります。
その一例が`mod`関数です。

```text
> mod 8 3
2
```

上の用例は正しく動きますが、読みづらいです。
より馴染みのある表現の仕方は「8 mod 3」ですが、
バックスラッシュ (\`) の中に前置関数を包めばこのように書けます。

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

`insertEntry`に中置演算子別称（または同義語）を定義することもできます。
この演算子の名前に適当に`++`を選び、
[優先度](https://github.com/purescript/documentation/blob/master/language/Syntax.md#precedence)を`5`にし、
そして`infixr`を使って右[結合](https://github.com/purescript/documentation/blob/master/language/Syntax.md#associativity)とします。

```haskell
infixr 5 insertEntry as ++
```

この新しい演算子で上の`book4`の例を次のように書き直せます。

```haskell
book5 = john ++ (peggy ++ (ned ++ emptyBook))
```

そして新しい`++`演算子が右結合なので意味を変えずに括弧を除去できます。

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
単に`apply`という名前の通常の関数のための中置演算子であって、`Data.Function`で以下のように定義されています。

```haskell
apply :: forall a b. (a -> b) -> a -> b
apply f x = f x

infixr 0 apply as $
```

`apply`関数は、他の関数（型は`(a -> b)`）を最初の引数に、値（型は`a`）を2つ目の引数に取って、その値に対して関数を呼びます。
この関数が何ら意味のあることをしていないようだと思ったら、まったくもって正しいです！
この関数がなくてもプログラムは論理的に同一です。
（[参照透過性](https://en.wikipedia.org/wiki/Referential_transparency)も見てください。）
この関数の構文的な利便性はその中置演算子に割り当てられた特別な性質からきています。
`$`は右結合 (`infixr`) で低い優先度 (`0`) の演算子ですが、これにより深い入れ子になった適用から括弧の束を削除できるのです。

さらなる`$`演算子を使った括弧退治の機会は、以前の`findEntry`関数にあります。
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

その代わりの手段として演算子は部分適用することができ、これには式を括弧で囲んで[演算子節](https://github.com/purescript/documentation/blob/master/language/Syntax.md#operator-sections)中の引数として`_`を使います。
これは簡単な無名関数を作るより便利な方法として考えることができます。
（以下の例ではそこから無名関数を名前に束縛しているので、もはや別に無名とも言えなくなっていますが。）

```text
> add3 = (3 + _)
> add3 2
5
```

まとめると、以下は引数に`5`を加える関数の等価な定義です。

```haskell
add5 x = 5 + x
add5 x = add 5 x
add5 x = (+) 5 x
add5 x = 5 `add` x
add5   = add 5
add5   = \x -> 5 + x
add5   = (5 + _)
add5 x = 5 `(+)` x  -- よおポチ、中置に目がないっていうから、中置の中に中置を入れといたぜ！
```

## 関数合成

イータ変換を使うと `insertEntry`関数を簡略化できたのと同じように、引数をよく考察すると
`findEntry`の定義を簡略化することができます。

引数 `book`が関数 `filter filterEntry`に渡され、この適用の結果が
`head`に渡されることに注目してください。これは言いかたを変えれば、 `filter filterEntry`と `head`の**合成**
(composition) に `book`が渡されるということです。

PureScriptの関数合成演算子は `<<<`と `>>>`です。前者は「逆方向の合成」であり、後者は「順方向の合成」です。

いずれかの演算子を使用して `findEntry`の右辺を書き換えることができます。逆順の合成を使用すると、右辺は次のようになります。

```
(head <<< filter filterEntry) book
```

この形式なら最初の定義にイータ変換の技を適用することができ、 `findEntry`は最終的に次のような形式に到達します。

```haskell
{{#include ../exercises/chapter3/src/Data/AddressBook.purs:findEntry_implementation}}
    ...
```

右辺を次のようにしても同じく妥当です。

```haskell
filter filterEntry >>> head
```

どちらにしても、これは「 `findEntry`はフィルタリング関数と `head`関数の合成である」という
`findEntry`関数のわかりやすい定義を与えます。

どちらの定義のほうがわかりやすいかの判断はお任せしますが、このように関数を部品として捉えると有用なことがよくあります。
関数はひとつの役目だけをこなし、機能を関数合成で組み立てるというように。

## 演習

 1. （簡単） `findEntry`関数の定義の主な部分式の型を書き下し、 `findEntry`関数についてよく理解しているか試してみましょう。
    たとえば、 `findEntry`の定義のなかにある `head`関数の型は `AddressBook -> Maybe
    Entry`と特殊化されています。
    **補足**：この問題にはテストがありません。
 1. （普通）関数`findEntryByStreet :: String -> AddressBook -> Maybe
    Entry`を書いてください。
    この関数は与えられた通りの住所から`Entry`を見付け出します。
    **ヒント**：`findEntry`にある既存のコードを再利用してください。
    実装した関数をPSCiと`spago test`を走らせることでテストしてください。
 1. （普通）`filterEntry`を（`<<<`や`>>>`を使った）合成で置き換えて、`findEntryByStreet`を書き直してください。
    合成の対象は、プロパティ取得子（`_.`記法を使います）と、与えられた文字列引数が与えられた通りの住所に等しいかを判定する関数です。
 1. （普通） 指定された名前が `AddressBook`に存在するかどうかを調べて真偽値で返す関数`isInBook`を書いてみましょう。
    **ヒント**：リストが空かどうかを調べる `Data.List.null`関数の型をPSCiで調べてみてみましょう。
 1. （難しい） 「重複」している項目を住所録から削除する関数 `removeDuplicates`を書いてみましょう。
    項目が同じ姓名を共有していれば`address`フィールドに関係なく、項目が重複していると考えます。
    **ヒント**：関数 `Data.List.nubBy`の型を、PSCiを使用して調べてみましょう。
    この関数は値同士の等価性を定義する述語関数に基づいてリストから重複要素を削除します。
    なお、それぞれの重複する項目の集合における最初の要素（リストの先頭に最も近い）が保持する項目です。

## まとめ

この章では、関数型プログラミングの新しい概念をいくつか導入しました。

- 対話的モードPSCiを使用して関数を調べるなど思いついたことを試す方法
- 検証や実装の道具としての型の役割
- 多引数関数を表現する、カリー化された関数の使用
- 関数合成で小さな部品を組み合わせてのプログラムの構築
- `where`節を利用したコードの構造化
- `Maybe`型を使用してnull値を回避する方法
- イータ変換や関数合成のような手法を利用した、よりわかりやすいコードへの再構成

次の章からは、これらの考えかたに基づいて進めていきます。

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