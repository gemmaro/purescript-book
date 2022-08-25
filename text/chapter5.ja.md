# パターン照合

## この章の目標

この章では、代数的データ型とパターン照合という、ふたつの新しい概念を導入します。
また、行多相というPureScriptの型システムの興味深い機能についても簡単に取り扱います。

**パターン照合** (pattern matching) は関数​​型プログラミングにおける一般的な手法で、
複数の場合に実装を分解することにより、開発者は潜在的に複雑な動作の関数を簡潔に書くことができます。

代数的データ型はPureScriptの型システムの機能であり、
型のある言語において同様の水準の表現力を可能にしています。
パターン照合とも密接に関連しています。

この章の目的は、代数的データ型やパターン照合を使用して、
単純なベクターグラフィックスを描画し操作するためのライブラリを書くことです。

## プロジェクトの準備

この章のソースコードはファイル `src/Data/Picture.purs`で定義されています。

`Data.Picture`モジュールは、簡単な図形を表すデータ型 `Shape`や、図形の集合である型
`Picture`、及びこれらの型を扱うための関数を定義しています。

このモジュールでは、データ構造の畳込みを行う関数を提供する `Data.Foldable`モジュールもインポートします。

```haskell
{{#include ../exercises/chapter5/src/Data/Picture.purs:module_picture}}
```

`Data.Picture`モジュールは`Number`モジュールもインポートしますが、こちらは`as`キーワードを使います。

```haskell
{{#include ../exercises/chapter5/src/Data/Picture.purs:picture_import_as}}
```

これは型や関数をモジュール内で使用できるようにしますが、
それは`Number.max`のように**修飾名**を使ったときのみです。
これは重複したインポートを避けたり、
何らかのものがどのモジュールからインポートされたのかを明らかにするのに役立ちます。

**注意**：元のモジュールと同じモジュール名を修飾名に使用するのは不要です。
`import Math as M`などのより短い名前にすることは可能ですし、かなりよくあります。

## 単純なパターン照合

それではコード例を見ることから始めましょう。
パターン照合を使用して2つの整数の最大公約数を計算する関数は、次のようになります。

```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:gcd}}
```

このアルゴリズムはユークリッドの互除法と呼ばれています。
その定義をオンラインで検索すると、
おそらく上記のコードによく似た数学の方程式が見つかるでしょう。
パターン照合の利点のひとつは、
上記のようにコードを場合分けして定義することができ、
数学関数の定義と似たような簡潔で宣言型なコードを書くことができることです。

パターン照合を使用して書かれた関数は、
条件と結果の組み合わせによって動作します。
この定義の各行は**選択肢** (alternative) や**場合** (case) と呼ばれています。
等号の左辺の式は**パターン**と呼ばれており、
それぞれの場合は空白で区切られた1つ以上のパターンで構成されています。
場合の集まりは、等号の右側の式が評価され値が返される前に、
引数が満たさなければならないどれかの条件を表現しています。
それぞれの場合は上からこの順番に試されていき、
最初に入力に適合した場合が返り値を決定します。

たとえば、 `gcd`関数は次の手順で評価されます。

- まず最初の場合が試されます。第2引数がゼロの場合、関数は `n`（最初の引数）を返します。
- そうでなければ、2番目の場合が試されます。
  最初の引数がゼロの場合、関数は `m`（第2引数）を返します。
- それ以外の場合、関数は最後の行の式を評価して返します。

パターンは値を名前に束縛することができることに注意してください。
この例の各行では `n`という名前と `m`という名前の両方、
またはどちらか一方に、入力された値を束縛しています。
これよりさまざまな種類のパターンについて学びますが、
これらのパターンは入力の引数から名前を選ぶさまざまな方法に対応付けられることがわかるでしょう。

## 単純なパターン

上記のコード例では、2種類のパターンを示しました。

- `Int`型の値が正確に一致する場合にのみ適合する、整数リテラルパターン
- 引数を名前に束縛する、変数パターン

単純なパターンには他にも種類があります。

- `Number`、`String`、`Char`、そして`Boolean`といったリテラル
- どんな引数とも適合するが名前に束縛はしない、
  アンダースコア (`_`) で表されるワイルドカードパターン

ここではこれらの単純なパターンを使用した、さらに2つの例を示します。

```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:fromString}}

{{#include ../exercises/chapter5/src/ChapterExamples.purs:toString}}
```

PSCiでこれらの関数を試してみてください。

## ガード

ユークリッドの互除法の例では、
`m > n`のときと `m <= n`のときの２つに分岐するために `if .. then .. else`式を使っていました。
こういうときには他に**ガード** (guard) を使うという選択肢もあります。

ガードはパターンによる制約に加えて満たされなくてはいけない真偽値の式です。
ガードを使用してユークリッドの互除法を書き直すと、次のようになります。

```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:gcdV2}}
```

この場合、3行目ではガードを使用して、最初の引数が第2引数よりも厳密に大きいという条件を付け加えています。
最後の行でのガードは式`otherwise`を使っており、キーワードのようにも見えますが、
実際にはただの`Prelude`における通常の束縛なのです。
```text
> :type otherwise
Boolean

> otherwise
true
```

この例が示すように、ガードは等号の左側に現れ、パイプ文字 (`|`) でパターンのリストと区切られています。

## 演習

1. （簡単）パターン照合を使用して、階乗関数`factorial`を書いてみましょう。
   **ヒント**:入力がゼロのときとゼロでないときの、ふたつのコーナーケースを考えてみてください。
   **補足**：これは前の章からの例の繰り返しですが、ここでは自力で書き直せるかやってみてください。
1. （やや難しい）\\( (1 + x) ^ n \\)を多項式展開した式にある
   \\( x ^ k \\)の項の係数を求める関数`binomial`を書いてください。
   これは`n`要素の集合から`k`要素の部分集合を選ぶ方法の数と同じです。
   数式\\( n! / k! (n - k)! \\)を使ってください。
   ここで \\( ! \\) は前に書いた階乗関数です。
   **ヒント**：パターン照合を使ってコーナーケースを制御してください。
   長い時間が掛かったりコールスタックのエラーでクラッシュしたりしたら、
   もっとコーナーケースを追加してみてください。
1. （やや難しい）[**パスカルの法則**](https://en.wikipedia.org/wiki/Pascal%27s_rule)を使って
   前の演習の同じ2項係数を計算する関数`pascal`を書いてください。

## 配列パターン

**配列リテラルパターン** (array literal patterns) は、固定長の配列に対して照合を行う方法を提供します。
たとえば、空の配列であることを特定する関数 `isEmpty`を書きたいとします。
最初の選択肢に空の配列パターン (`[]`) を用いるとこれを実現できます。

```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:isEmpty}}
```

次の関数では、長さ5の配列と適合し、配列の5つの要素をそれぞれ異なった方法で束縛しています。

```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:takeFive}}
```

最初のパターンは、第1要素と第2要素がそれぞれ0と1であるような、5要素の配列にのみ適合します。
その場合、関数は第3要素と第4要素の積を返します。
それ以外の場合は、関数は0を返します。
PSCiで試してみると、たとえば次のようになります。

```text
> :paste
… takeFive [0, 1, a, b, _] = a * b
… takeFive _ = 0
… ^D

> takeFive [0, 1, 2, 3, 4]
6

> takeFive [1, 2, 3, 4, 5]
0

> takeFive []
0
```

配列のリテラルパターンでは、固定長の配列と一致させることはできますが、
PureScriptは不特定の長さの配列を照合させる手段を提供していません。
そのような方法で不変な配列を分解すると、
実行速度が低下する可能性があるためです。
この種の照合を行うことができるデータ構造が必要な場合は、
`Data.List`を使うことをお勧めします。
そのほかの操作について、
より優れた漸近性能を提供するデータ構造も存在します。

## レコードパターンと行多相

**レコードパターン** (Record patterns) は（ご想像のとおり）レコードに照合します。

レコードパターンはレコードリテラルに見た目が似ていますが、
レコードリテラルでラベルと式を**コロン**で区切るのとは異なり、
レコードパターンではラベルとパターンを**等号**で区切ります。

たとえば、次のパターンは `first`と `last`と呼ばれるフィールドが含まれた任意のレコードにマッチし、
これらのフィールドの値はそれぞれ `x`と `y`という名前に束縛されます。

```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:showPerson}}
```

レコードパターンはPureScriptの型システムの興味深い機能である
**行多相** (row polymorphism) の良い例となっています。
もし上の`showPerson`を型シグネチャなしで定義していたとすると、
この型はどのように推論されるのでしょうか？
面白いことに、推論される型は上で与えた型とは同じではありません。

```text
> showPerson { first: x, last: y } = y <> ", " <> x

> :type showPerson
forall r. { first :: String, last :: String | r } -> String
```

この型変数 `r`とは何でしょうか？
PSCiで `showPerson`を使ってみると、面白いことがわかります。

```text
> showPerson { first: "Phil", last: "Freeman" }
"Freeman, Phil"

> showPerson { first: "Phil", last: "Freeman", location: "Los Angeles" }
"Freeman, Phil"
```

レコードにそれ以外のフィールドが追加されていても、
`showPerson`関数はそのまま動作するのです。
型が `String`であるようなフィールド `first`と `last`がレコードに少なくとも含まれていれば、
関数適用は正しく型付けされます。
しかし、フィールドが**不足**していると、 `showPerson`の呼び出しは**不正**となります。

```text
> showPerson { first: "Phil" }

Type of expression lacks required label "last"
```

`showPerson`の新しい型シグネチャを読むとこうです。
「`String`な`first`と`last`フィールド**と他のフィールドを何でも**持つあらゆるレコードを取り、
`String`を返す。」
なお、この振舞いは元の`showPerson`のものとは異なります。
行変数`r`がなければ`showPerson`は**厳密に**`first`と`last`フィールドしかないレコードのみを受け付けます。

次のように書くことができることにも注意してください。

```haskell
> showPerson p = p.last <> ", " <> p.first
```

この場合も、 PSCiは先ほどと同じ型を推論するでしょう。

## レコード同名利用

`showPerson`関数は引数内のレコードと一致し、
`first`と`last`フィールドを`x`と `y`という名前の値に束縛していたのでした。
別の方法として、フィールド名自体を再利用するだけで、このようなパターン一致を次のように単純化できます。

```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:showPersonV2}}
```

ここでは、プロパティの名前のみを指定し、名前に導入したい値を指定する必要はありません。
これは**レコード同名利用** (record pun) と呼ばれます。

レコード同名利用をレコードの**構築**に使用することもできます。
例えば、スコープ内に `first`と `last`という名前の値があれば、
`{ first, last }`を使って人物レコードを作ることができます。

```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:unknownPerson}}
```

これは、状況によってはコードの可読性を向上させるのに役立ちます。

## 入れ子になったパターン

配列パターンとレコードパターンはどちらも小さなパターンを組み合わせることで大きなパターンを構成しています。
これまでの例ではほとんどの場合で配列パターンとレコードパターンの内部に単純なパターンを使用していましたが、
パターンが自由に**入れ子**にすることができることも知っておくのが大切です。
入れ子になったパターンを使うと、
潜在的に複雑なデータ型に対しての条件分岐を用いて関数を定義できるようになります。

たとえば、このコードは2つのレコードパターンを結合します。

```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:livesInLA}}
```

## 名前付きパターン

入れ子のパターンを使う場合、パターンには**名前を付け**て追加で名前をスコープに持ち込むことができます。
任意のパターンに名前を付けるには、 `@`記号を使います。

たとえば、次の関数は2要素配列を整列するもので、2つの要素の名前を付けていますが、
配列自身にも名前を付けています。

```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:sortPair}}
```

このようにすれば対が既に整列されているときに新しい配列を割り当てなくて済みます。
なおもし入力の配列が**厳密に**2つの要素を含んでいなければ、
たとえ整列されていなかったとしても、この関数は単に元のまま変えずに返しています。

## 演習

1. （簡単）レコードパターンを使って、
   2つの `Person`レコードが同じ都市にいるか探す関数 `sameCity`を定義してみましょう。
1. （やや難しい）行多相を考慮すると、 `sameCity`関数の最も一般的な型は何でしょうか？
   先ほど定義した `livesInLA`関数についてはどうでしょうか？
   **補足**：この演習にテストはありません。
1. （やや難しい）配列リテラルパターンを使って、
   1要素の配列の唯一のメンバーを抽出する関数`fromSingleton`を書いてみましょう。
   1要素だけを持つ配列でない場合、
   関数は指定されたデフォルト値を返さなければなりません。
   この関数は `forall a. a -> Array a -> a`という型を持っていなければなりません。

## Case式

パターンは最上位にある関数宣言だけに現れるわけではありません。
`case`式を使って計算の途中の値に対してパターン照合を使うことができます。
case式には無名関数に似た種類の便利さがあります。
関数に名前を与えることがいつも望ましいわけではないように、
パターン照合を使いたいためだけに関数に名前をつけるようなことを避けられるようになります。

例を示しましょう。
次の関数は、配列の「最長ゼロ末尾」（和がゼロであるような、最も長い配列の末尾）を計算します。

```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:lzsImport}}

{{#include ../exercises/chapter5/src/ChapterExamples.purs:lzs}}
```

以下は例です。

```text
> lzs [1, 2, 3, 4]
[]

> lzs [1, -1, -2, 3]
[-1, -2, 3]
```

この関数は場合ごとの分析によって動作します。
もし配列が空なら、唯一の選択肢は空の配列を返すことです。
配列が空でない場合は、さらに2つの場合に分けるためにまず `case`式を使用します。
配列の合計がゼロであれば、配列全体を返します。
そうでなければ、配列の残りに対して再帰します。

## パターン照合の失敗と部分関数

case式のパターンを順番に照合していって、
もし選択肢のいずれの場合も入力が適合しなかった時は何が起こるのでしょうか？
この場合、**パターン照合失敗**によって、case式は実行時に失敗します。

簡単な例でこの動作を見てみましょう。

```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:unsafePartialImport}}

{{#include ../exercises/chapter5/src/ChapterExamples.purs:partialFunction}}
```

この関数は単一の場合しか含んでおらず、その場合では単一の入力である`true`にのみ照合します。
このファイルをコンパイルして PSCiでそれ以外の値を与えてテストすると、実行時エラーが発生します。

```text
> partialFunction false

Failed pattern match
```

どんな入力の組み合わせに対しても値を返すような関数は**全関数** (total function) と呼ばれ、
そうでない関数は**部分的** (partial) であると呼ばれます。

一般的には、可能な限り全関数として定義したほうが良いと考えられています。
もし関数が何らかの妥当な入力の集合について結果を返さないことがわかっているなら、
大抵は失敗であることを示すことができる値を返すほうがよいでしょう。
例えば何らかの`a`についての型`Maybe a`で、妥当な結果を返せないときは`Nothing`を使います。
この方法なら、型安全な方法で値の有無を示すことができます。

PureScriptコンパイラは、
パターンマッチが不完全で関数が全関数ではないことを検出するとエラーを生成します。
部分関数が安全である場合、
`unsafePartial`関数を使ってこれらのエラーを抑制することができます。
（その部分関数が安全だと言い切れるなら！）
もし上記の `unsafePartial`関数の呼び出しを取り除くと、コンパイラは次のエラーを生成します。

```text
A case expression could not be determined to cover all inputs.
The following additional cases are required to cover all inputs:

  false
```

これは値`false`が、定義されたどのパターンとも一致しないことを示しています。
一般的にこれらの警告には、複数の不一致のケースが含まれることがあります。

上記の型シグネチャも省略した場合は、次のようになります。

```haskell
partialFunction true = true
```

このとき、PSCiは興味深い型を推論します｡

```text
> :type partialFunction

Partial => Boolean -> Boolean
```

本書ではのちに`=>`記号を含むいろいろな型を見ることになります。
（これらは**型クラス**に関連しています。）
しかし、今のところは、PureScriptは型システムを使って部分関数を追跡していることと、
安全な場合に型検証器に明示する必要があることを確認すれば十分です。

コンパイラは、定義されたパターンが**冗長**であることを検出した場合
（前の方に定義されたパターンに一致するケースのみ）でも警告を生成します。

```haskell
redundantCase :: Boolean -> Boolean
redundantCase true = true
redundantCase false = false
redundantCase false = false
```

このとき、最後のケースは冗長であると正しく検出されます。

```text
A case expression contains unreachable cases:

  false
```

**注意**：PSCiは警告を表示しないので、
この例を再現するには、この関数をファイルとして保存し、 `pulp build`を使ってコンパイルします。

## 代数的データ型

この節では**代数的データ型** (algebraic data type, ADT) と呼ばれる、
PureScriptの型システムの機能を導入します。
この機能はパターン照合と地続きの関係があります。

しかしまずは切り口となる例について考えていきます。
この例では単純なベクターグラフィックスライブラリの実装というこの章の課題を解決する基礎を提供します。

直線、矩形、円、テキストなどの単純な図形の種類を表現する型を定義したいとします。
オブジェクト指向言語では、おそらくインタフェースもしくは抽象クラス `Shape`を定義し、
使いたいそれぞれの図形について具体的なサブクラスを定義するでしょう。

しかしながら、この方針は大きな欠点をひとつ抱えています。
`Shape`を抽象的に扱うためには、実行したいと思う可能性のあるすべての操作を事前に把握し、
`Shape`インタフェースに定義する必要があるのです。
このため、モジュール性を壊さずに新しい操作を追加することが難しくなります。

もし図形の種類が事前にわかっているなら、
代数的データ型はこうした問題を解決する型安全な方法を提供します。
モジュール性のある方法で `Shape`に新たな操作を定義し、
型安全性が維持できます。

代数的データ型としてどのように`Shape`が表現されるかを次に示します。

```haskell
{{#include ../exercises/chapter5/src/Data/Picture.purs:Shape}}

{{#include ../exercises/chapter5/src/Data/Picture.purs:Point}}
```

この宣言では`Shape`をそれぞれの構築子の和として定義しており、
各構築子では含まれるデータを指定します。
`Shape`は、中央 `Point`と半径（数値）を持つ `Circle`か、
`Rectangle`、 `Line`、 `Text`のいずれかです。
他には `Shape`型の値を構築する方法はありません。

代数的データ型の定義はキーワード `data`から始まり、
それに新しい型の名前と任意個の型引数が続きます。
その型の構築子（あるいは**データ構築子** (data constructor)）は等号の後に定義され、
パイプ文字 (`|`) で区切られます。
ADTの構築子が持つデータは原始型に限りません。
構築子にはレコード、配列、また他のADTさえも含むことができます。

それではPureScriptの標準ライブラリから別の例を見てみましょう。
オプショナルな値を定義するのに使われる `Maybe`型を本書の冒頭で扱いました。
`maybe`パッケージでは `Maybe`を次のように定義しています。

```haskell
data Maybe a = Nothing | Just a
```

この例では型引数 `a`の使用方法を示しています。
パイプ文字を「または」と読むことにすると、
この定義は「 `Maybe a`型の値は、無い (`Nothing`) か、
またはただの (`Just`) 型 `a`の値だ」とほぼ英語のように読むことができます。

なおデータ定義のどこにも構文`forall a`を使っていません。
`forall`構文は関数には必須ですが、`data`によるADTや`type`での型別称を定義するときは使われません。

データ構築子は再帰的なデータ構造を定義するために使用することもできます。
更に例を挙げると、要素が型 `a`の単方向連結リストのデータ型を定義はこのようになります。

```haskell
data List a = Nil | Cons a (List a)
```

この例は `lists`パッケージから持ってきました。
ここで `Nil`構築子は空のリストを表しており、
`Cons`は先頭となる要素と尾鰭から空でないリストを作成するために使われます。
`Cons`の2つ目のフィールドでデータ型 `List a`を使用しており、
再帰的なデータ型になっていることに注目してください。

## ADTの使用

代数的データ型の構築子を使用して値を構築するのはとても簡単です。
対応する構築子に含まれるデータに応じた引数を用意し、
その構築子を単に関数のように適用するだけです。

例えば、上で定義した `Line`構築子は2つの `Point`を必要としていますので、
`Line`構築子を使って `Shape`を構築するには、
型 `Point`のふたつの引数を与えなければなりません。

```haskell
{{#include ../exercises/chapter5/src/Data/Picture.purs:exampleLine}}
```

さて、代数的データ型で値を構築することは簡単ですが、
これをどうやって使ったらよいのでしょうか？
ここで代数的データ型とパターン照合との重要な接点が見えてきます。
代数的データ型の値を消費する唯一の方法は構築子に照合するパターンを使うことです。

例を見てみましょう。
`Shape`を `String`に変換したいとします。
`Shape`を構築するのにどの構築子が使用されたかを調べるには、
パターン照合を使用しなければなりません。
これには次のようにします。

```haskell
{{#include ../exercises/chapter5/src/Data/Picture.purs:showShape}}

{{#include ../exercises/chapter5/src/Data/Picture.purs:showPoint}}
```

各構築子はパターンとして使用することができ、
構築子への引数はそのパターンで束縛することができます。
`showShape`の最初の場合を考えてみましょう。
もし `Shape`が `Circle`構築子適合した場合、
2つの変数パターン `c`と `r`を使って
`Circle`の引数（中心と半径）がスコープに導入されます。
その他の場合も同様です。

## 演習

1. （簡単）`Circle`（型は`Shape`）を構築する関数`circleAtOrigin`を書いてください。
   中心は原点にあり、半径は`10.0`です。
1. （やや難しい）`Shape`を、原点を中心として`2.0`倍に拡大する関数`doubleScaleAndCenter`を書いてみましょう。
1. （やや難しい） `Shape`からテキストを抽出する関数`shapeText`を書いてください。
   この関数は `Maybe String`を返しますが、
   もし入力が `Text`を使用して構築されたのでなければ、返り値には `Nothing`構築子を使ってください。

## Newtype

代数的データ型の特別な場合として、**newtype**と呼ばれるものがあります。
newtypeはキーワード `data`の代わりにキーワード `newtype`を使用して導入します。

newtype宣言では**過不足なくひとつだけの**構築子を定義しなければならず、
その構築子は**過不足なくひとつだけの**引数を取る必要があります。
つまり、newtype宣言は既存の型に新しい名前を与えるものなのです。
実際、newtypeの値は、元の型と同じ実行時表現を持ってるので、実行時性能のオーバーヘッドがありません。
しかし、これらは型システムの観点から区別されます。
これは型安全性の追加の層を提供するのです。

例として、ボルト、アンペア、オームのような単位を表現するために、
`Number`の型レベルの別名を定義したくなる場合があるかもしれません。

```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:electricalUnits}}
```

それからこれらの型を使う関数と値を定義します。

```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:calculateCurrent}}
```

これによりつまらないミスを防ぐことができます。
例えば電源**なし**に**2つ**の電球により生み出される電流を計算しようとするなどです。

```haskell
current :: Amp
current = calculateCurrent lightbulb lightbulb
{-
TypesDoNotUnify:
  current = calculateCurrent lightbulb lightbulb
                             ^^^^^^^^^
  Could not match type
    Ohm
  with type
    Volt
-}
```

もし`newtype`なしに単に`Numebr`を使っていたら、コンパイラはこのミスを補足できません。

```haskell
-- これもコンパイルできますが、型安全ではありません。
calculateCurrent :: Number -> Number -> Number
calculateCurrent v r = v / r

battery :: Number
battery = 1.5

lightbulb :: Number
lightbulb = 500.0

current :: Number
current = calculateCurrent lightbulb lightbulb -- 補足されないミス
```

なお、newtypeは単一の構築子しかとれず、構築子は単一の値でなくてはなりませんが、
newtypeは任意の数の型変数を取ることが**できます**。
例えば以下のnewtypeは妥当な定義です。
（`err`と`a`は型変数で、`CouldError`構築子は型`Either err a`の**単一**の値を期待します。）

```Haskell
newtype CouldError err a = CouldError (Either err a)
```

また、newtypeの構築子はよくnewtype自身と同じ名前を持つことがあることにも注意してください。
ただこれは必須ではありません。
例えば固有の名前であっても妥当です。
```haskell
{{#include ../exercises/chapter5/src/ChapterExamples.purs:Coulomb}}
```

この場合`Coulomb`は**型構築子**（引数はゼロ）で`MakeCoulomb`は**データ構築子**です。
これらの構築子は異なる名前空間に属しており、`Volt`の例でそうだったように、名前に一意性があります。
これは全てのADTについて言えることです。
なお、型構築子とデータ構築子は異なる名前を持つことができますが、
実際には同じ名前を共有するのが普通です。
上の`Amp`と`Volt`の場合がこれです。

newtypeの別の応用は、実行時表現を変えることなく、既存の型に異なる**振舞い**を付加することです。
その利用例については次章で**型クラス**をお話しするときに押さえます。

## 演習

1. （簡単）`Watt`を`Number`の`newtype`として定義してください。
   それからこの新しい`Watt`型と上の`Amp`と`Volt`の定義を使って`calculateWattage`関数を定義してください。
```haskell
calculateWattage :: Amp -> Volt -> Watt
```
`Watt`中のワット数は与えられた`Amp`中の電流と与えられた`Volt`の電圧の積で計算できます。

## ベクターグラフィックスライブラリ

これまで定義してきたデータ型を使って、ベクターグラフィックスを扱う簡単なライブラリを作成していきましょう。

ただの `Shape`の配列であるような、 `Picture`という型同義語を定義しておきます。

```haskell
{{#include ../exercises/chapter5/src/Data/Picture.purs:Picture}}
```

デバッグしていると `Picture`を `String`として表示できるようにしたくなることもあるでしょう。
これはパターン照合を使用して定義された `showPicture`関数で行うことができます。

```haskell
{{#include ../exercises/chapter5/src/Data/Picture.purs:showPicture}}
```

試してみましょう。
モジュールを `spago build`でコンパイルし、 `spago repl`でPSCiを開きます。

```text
$ spago build
$ spago repl

> import Data.Picture

> showPicture [ Line { x: 0.0, y: 0.0 } { x: 1.0, y: 1.0 } ]

["Line [start: (0.0, 0.0), end: (1.0, 1.0)]"]
```

## 外接矩形の算出

このモジュールのコード例には、 `Picture`の最小外接矩形を計算する関数 `bounds`が含まれています。

`Bounds`型は外接矩形を定義します。

```haskell
{{#include ../exercises/chapter5/src/Data/Picture.purs:Bounds}}
```

`Picture`内の `Shape`の配列を走査し、最小の外接矩形を累積するため、
`bounds`は `Data.Foldable`の `foldl`関数を使用しています。

```haskell
{{#include ../exercises/chapter5/src/Data/Picture.purs:bounds}}
```

基底の場合では、空の `Picture`の最小外接矩形を求める必要がありますが、
`emptyBounds`で定義される空の外接矩形がその条件を満たしています。

累積関数 `combine`は `where`ブロックで定義されています。
`combine`は `foldl`の再帰呼び出しで計算された外接矩形と、
配列内の次の `Shape`を引数にとり、
ユーザ定義の演算子 `union`を使ってふたつの外接矩形の和を計算しています。
`shapeBounds`関数は、パターン照合を使用して、単一の図形の外接矩形を計算します。

## 演習

1. （やや難しい） ベクターグラフィックライブラリを拡張し、
   `Shape`の面積を計算する新しい操作 `area`を追加してください。
   この演習では、テキストの面積は0であるものとしてください。
1. （難しい） `Shape`を拡張し、新しいデータ構築子 `Clipped`を追加してください。
   `Clipped`は他の `Picture`を矩形に切り抜きます。
   切り抜いてきた`Picture`の境界を計算できるよう、
   `shapeBounds`関数を拡張してください。
   なお、これにより`Shape`は再帰的なデータ型になります。

## まとめ

この章では、関数型プログラミングから基本だが強力なテクニックであるパターン照合を扱いました。
複雑なデータ構造の部分と照合するために、
簡単なパターンの使い方だけではなく、
配列パターンやレコードパターンを使った深いデータ構造の一部の照合方法を見てきました。

またこの章では、パターン照合に密接に関連する代数的データ型を紹介しました。
代数的データ型のおかげでデータ構造を簡潔に記述することができ、
新たな操作でデータ型を拡張するためのモジュール性のある方法が提供されることを見てきました。

最後に強力な抽象化である**行多相**を扱いました。
これにより多くの既存のJavaScript関数に型を与えられます。

本書では今後も代数的データ型とパターン照合をいろんなところで使用するので、
今のうちにこれらに習熟しておくと後で実を結ぶことでしょう。
これ以外にも独自の代数的データ型を作成し、
パターン照合を使用してそれらを使う関数を書くことを試してみてください。

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