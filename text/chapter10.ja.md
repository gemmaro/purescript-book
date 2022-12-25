# 外部関数インタフェース

## この章の目標

この章でPureScriptの**外部関数インターフェース** (foreign function interface; FFI) を紹介します。
これによりPureScriptコードからJavaScriptコードへの呼び出し、およびその逆が可能になります。
これから扱うのは次のようなものです。

- 純粋で、作用のある、非同期なJavaScript関数をPureScriptから呼び出す。
- 型付けされていないデータを扱う。
- Encode and parse JSON using the `argonaut` package.

この章の終わりにかけて、住所録の例に立ち返ります。
この章の目的は、FFIを使ってアプリケーションに次の新しい機能を追加することです。

- Alert the user with a popup notification.
- フォームのデータを直列化してブラウザのローカルストレージに保存し、アプ
  リケーションが再起動したときにそれを再読み込みする

いくつかの一般にはそこまで重用されない追加の話題を押さえた補遺もあります。
自由にこれらの節を読んで構いませんが、
学習目標にあまり関係しなければ本の残りを読み進める妨げにならないようにしてください。

- 実行時のPureScriptの値の表現を理解する。
- JavaScriptからPureScriptを呼び出す。

## プロジェクトの準備

このモジュールのソースコードは、第3章、第7章及び第8章の続きになります。
今回もそれぞれのディレクトリから適切なソースファイルがソースファイルに含められています。

この章は`argonaut`ライブラリを依存関係として導入しています。
このライブラリはJSONに符号化したりJSONを復号化したりするために使います。

この章の演習は`test/MySolutions.purs`に書き、
`spago test`を走らせることによって`test/Main.purs`中の単体試験に対して確認することができます。

住所録アプリは`parcel src/index.html --open`で立ち上げることができます。
8章と同じ作業の流れを使っているので、より詳しい説明についてはそちらの章を参照してください。

## 免責事項

JavaScriptを扱う作業をできる限り簡単にするため、
PureScriptは直感的な外部関数インタフェースを提供します。
しかしながら、FFIはPureScriptの**高度な**機能であることには留意していただきたいと思います。
FFIを安全かつ効率的に使用するには、
扱うつもりであるデータの実行時の表現についてよく理解していなければなりません。
この章では、PureScriptの標準ライブラリのコードに付いて回る
そのような理解を与えることを目指しています。

PureScriptのFFIはとても柔軟に設計されています。
実際には、外部関数に最低限の型だけを与えるか、
それとも型システムを利用して外部のコードの誤った使い方を防ぐようにするか、
開発者が選ぶことができるということを意味しています。
標準ライブラリのコードは、後者の手法を好む傾向にあります。

簡単な例としては、
JavaScriptの関数で戻り値が `null`にならないことを保証することはできません。
実のところ、JavaScriptらしさのあるコードはかなり頻繁に `null`を返します！
しかし、大抵PureScriptの型にnull値が巣喰うことはありません。
そのため、FFIを使ってJavaScriptコードのインターフェイスを設計するときは、
これらの特殊な場合を適切に処理するのは開発者の責任です。

## PureScriptからJavaScriptを呼び出す

PureScriptからJavaScriptコードを使用する最も簡単な方法は、
**外部インポート宣言** (foreign import declaration) を使用し、
既存のJavaScriptの値に型を与えることです。
外部インポート宣言には**外部JavaScriptモジュール** (foreign JavaScript module) から
**エクスポート**された対応するJavaScriptでの宣言がなくてはなりません。

たとえば、特殊文字をエスケープすることによりURIのコンポーネントを符号化するJavaScriptの
`encodeURIComponent`関数について考えてみます。

```text
$ node

node> encodeURIComponent('Hello World')
'Hello%20World'
```

`null`でない文字列から `null`でない文字列への関数であり、副作用を持っていないので、この関数はその型 `String -> String`について適切な実行時表現を持っています。

次のような外部インポート宣言を使うと、この関数に型を割り当てることができます。

```haskell
{{#include ../exercises/chapter10/test/URI.purs}}
```

インポートしてくるための外部JavaScriptモジュールを書く必要もあります。
対応する外部JavaScriptモジュールは同名で拡張子が`.purs`から`.js`に変わったものです。
上のPureScriptモジュールが`URI.purs`として保存されているなら、
外部JavaScriptモジュールは`URI.js`として保存されます。
`encodeURIComponent`は既に定義されているので、`_encodeURIComponent`としてエクスポートせねばなりません。

```javascript
{{#include ../exercises/chapter10/test/URI.js}}
```

バージョン0.15からPureScriptはJavaScriptと通訳する際にESモジュールシステムを使います。
ESモジュールではオブジェクトに`export`キーワードを与えることで関数と値はモジュールからエクスポートされます。

これら2つの部品を使うことで、PureScriptで書かれた関数のように、
PureScriptから`encodeURIComponent`関数を使うことができます。
例えばPSCiで上記の計算を再現できます。

```text
$ spago repl

> import Test.URI
> _encodeURIComponent "Hello World"
"Hello%20World"
```

外部モジュールに自前の関数を定義することもできます。
以下は`Number`を平方する自前のJavaScript関数を作って呼び出す方法の一例です。

`test/Examples.js`:

```js
"use strict";

{{#include ../exercises/chapter10/test/Examples.js:square}}
```

`test/Examples.purs`:

```hs
module Test.Examples where

foreign import square :: Number -> Number
```

```text
$ spago repl

> import Test.Examples
> square 5.0
25.0
```

## 多変数​関数

第2章の`diagonal`関数を外部モジュールで書き直してみましょう。
この関数は直角三角形の対角線を計算します。


```hs
{{#include ../exercises/chapter10/test/Examples.purs:diagonal}}
```

PureScriptの関数は**カリー化**されていることを思い出してください。
`diagonal`は`Number`を取って**関数**を返す関数です。
そして返された関数は`Number`を取って`Number`を返します。


```js
{{#include ../exercises/chapter10/test/Examples.js:diagonal}}
```

もしくはES6の矢印構文ではこうです。
（後述するES6についての補足を査証してください。）


```js
{{#include ../exercises/chapter10/test/Examples.js:diagonal_arrow}}
```

```hs
{{#include ../exercises/chapter10/test/Examples.purs:diagonal_arrow}}
```

```text
$ spago repl

> import Test.Examples
> diagonal 3.0 4.0
5.0
> diagonalArrow 3.0 4.0
5.0
```

## カリー化されていない関数

JavaScriptでカリー化された関数を書くことは、
ただでさえJavaScriptらしいものではない上に、常に可能というわけでもありません。
よくある多変数なJavaScriptの関数は**カリー化されていない**形式を取るでしょう。

```js
{{#include ../exercises/chapter10/test/Examples.js:diagonal_uncurried}}
```

モジュール`Data.Function.Uncurried`は**ラッパー**型と
カリー化されていない関数を取り扱う関数をエクスポートします。

```hs
{{#include ../exercises/chapter10/test/Examples.purs:diagonal_uncurried}}
```

型構築子`Fn2`を調べると以下です。

```text
$ spago repl

> import Data.Function.Uncurried 
> :kind Fn2
Type -> Type -> Type -> Type
```

`Fn2`は3つの型引数を取ります。
`Fn2 a b c`は、型 `a`と `b`の2つの引数、
返り値の型 `c`をもつカリー化されていない関数の型を表現しています。
これを使って外部モジュールから`diagonalUncurried`をインポートしました。

カリー化されていない関数と引数を取る`runFn2`で呼び出すことができます。

```text
$ spago repl

> import Test.Examples
> import Data.Function.Uncurried
> runFn2 diagonalUncurried 3.0 4.0
5.0
```

`functions`パッケージでは0引数から10引数までの関数について同様の型構築子が定義されています。

## カリー化されていない関数についての補足

PureScriptのカリー化された関数にはもちろん利点があります。
部分的に関数を適用することができ、関数型に型クラスインスタンスを与えられます。
しかし効率上の代償も付いてくるのです。
効率性が決定的に重要なコードでは多変数を受け付けるカリー化されていないJavaScript関数を定義する必要が時々あります。

PureScriptでカリー化されていない関数を作ることもできます。
2引数の関数については`mkFn2`関数が使えます。

```haskell
{{#include ../exercises/chapter10/test/Examples.purs:uncurried_add}}
```

前と同様に`runFn2`関数を使うと、カリー化されていない2引数の関数を適用することができます。

```haskell
{{#include ../exercises/chapter10/test/Examples.purs:uncurried_sum}}
```

ここで重要なのは、引数がすべて適用されるなら、コンパイラは `mkFn2`関数や
`runFn2`関数を**インライン化**するということです。そのため、生成されるコードはとてもコンパクトになります。

```javascript
var uncurriedAdd = function (n, m) {
  return m + n | 0;
};

var uncurriedSum = uncurriedAdd(3, 10);
```

対照的に、こちらがこれまでのカリー化された関数です。

```haskell
{{#include ../exercises/chapter10/test/Examples.purs:curried_add}}
```

そして生成結果のコードが以下です。
入れ子の関数のため比較的簡潔ではありません。

```javascript
var curriedAdd = function (n) {
  return function (m) {
    return m + n | 0;
  };
};

var curriedSum = curriedAdd(3)(10);
```

## 現代的なJavaScriptの構文についての補足

前に見た矢印関数構文はES6の機能であり、そのためいくつかの古いブラウザ（名指しすればIE11）と互換性がありません。
執筆時点でWebブラウザをまだ更新していない[6%の利用者が矢印関数を使うことができないと推計](https://caniuse.com/#feat=arrow-functions)されています。

ほとんどの利用者にとって互換性があるようにするため、
PureScriptコンパイラによって生成されるJavaScriptコードは矢印関数を使っていません。
また、同じ理由で**公開するライブラリでも矢印関数を避ける**ことが推奨されます。

それでも自分のFFIコードで矢印関数を使うこともできますが、
デプロイの作業工程でES5に互換性のある関数に変換するために[Babel](https://github.com/babel/babel#intro)などのツールを含めるべきです。

ES6の矢印関数がより読みやすく感じたら[Lebab](https://github.com/lebab/lebab)のようなツールを使ってコンパイラの`output`ディレクトリにJavaScriptのオードを変換することができます。

```sh
npm i -g lebab
lebab --replace output/ --transform arrow,arrow-return
```

この操作により上の`curriedAdd`関数は以下に変換されます。

```js
var curriedAdd = n => m =>
  m + n | 0;
```

本書の残りの例では入れ子の関数の代わりに矢印関数を使います。

## 演習

1. （普通）`Test.MySolutions`モジュールの中に箱の体積を求めるJavaScriptの関数`volumeFn`を書いてください。
   `Data.Function.Uncurried`の`Fn`ラッパーを使ってください。
2. （普通）`volumeFn`を矢印関数を使って書き直し、`volumeArrow`としてください。

## 単純な型を渡す

以下のデータ型はPureScriptとJavaScriptの間でそのまま渡し合うことができます。

PureScript  | JavaScript
---         | ---
Boolean     | Boolean
String      | String
Int, Number | Number
Array       | Array
Record      | Object

`String`と`Number`という原始型の例は既に見てきました。
ここから`Array`や`Record`（JavaScriptでは`Object`）といった構造的な型を眺めていきます。

`Array`の受け渡しを実演するために、
以下に`Int`の`Array`を取って別の配列として累計の和を返すJavaScriptの関数の呼び出し方を示します。
JavaScriptは`Int`のための分離した型を持たないため、PureScriptでの`Int`と`Number`はJavaScriptでの`Number`に翻訳される点を思い起こしてください。

```hs
foreign import cumulativeSums :: Array Int -> Array Int
```

```js
export const cumulativeSums = arr => {
  let sum = 0
  let sums = []
  arr.forEach(x => {
    sum += x;
    sums.push(sum);
  });
  return sums;
};
```

```text
$ spago repl

> import Test.Examples
> cumulativeSums [1, 2, 3]
[1,3,6]
```

`Record`の受け渡しを実演するために、以下に2つの`Complex`な数をレコードとして取り、和を別のレコードとして返すJavaScriptの呼び出し方を示します。
PureScriptでの`Record`がJavaScriptでは`Object`として表現されることに注意してください。

```hs
type Complex = {
  real :: Number,
  imag :: Number
}

foreign import addComplex :: Complex -> Complex -> Complex
```

```js
export const addComplex = a => b => {
  return {
    real: a.real + b.real,
    imag: a.imag + b.imag
  }
};
```

```text
$ spago repl

> import Test.Examples
> addComplex { real: 1.0, imag: 2.0 } { real: 3.0, imag: 4.0 }
{ imag: 6.0, real: 4.0 }
```

なお、上の手法にはJavaScriptが期待通りの型を返すことへの信頼を要します。
PureScriptはJavaScriptのコードに型検査を適用することができないからです。
この型安全性の配慮について後のJSONの節でより詳しく記述していきます。
型の不整合から身を守る手法についても押さえます。

## 演習

1. （普通）`Complex`の数の配列を取って別の複素数の配列として累計の和を返すJavaScriptの関数`cumulativeSumsComplex`（と対応するPureScriptの外部インポート）を書いてください。

## 単純な型を越えて

`String`、`Number`、`Array`、そして`Record`といったJavaScript固有の表現を持つ型をFFI越しに送ったり受け取ったりする方法を数例見てきました。
ここから`Maybe`のようなPureScriptで使えるいくつかの他の型の使い方を押さえていきます。

外部宣言を使用して、配列についての `head`関数を改めて作成したいとしましょう。
JavaScriptでは次のような関数を書くことになるでしょう。

```javascript
export const head = arr =>
  arr[0];
```

この関数をどう型付けましょうか？
型 `forall a. Array a -> a`を与えようとしても、空の配列に対してこの関数は `undefined`を返します。
したがって型`forall a. Array a -> a`は正しくこの実装を表現していないのです。

代わりにこのコーナーケースを扱うために`Maybe`値を返したいところです。

```hs
foreign import maybeHead :: forall a. Array a -> Maybe a
```

しかしどうやって`Maybe`を返しましょうか。
つい以下のように書きたくなります。

```js
// こうしないでください
import Data_Maybe from '../Data.Maybe'

export const maybeHead = arr => {
  if (arr.length) {
    return Data_Maybe.Just.create(arr[0]);
  } else {
    return Data_Maybe.Nothing.value;
  }
}
```

外部モジュールで直接`Data.Maybe`モジュールをインポートして使うことはお勧めしません。
というのもコードがコード生成器の変化に対して脆くなるからです。
`create`や`value`は公開のAPIではありません。
加えて、このようにすることは不要なコードの消去のための`purs bundle`を使う際に問題を引き起こしえます。

推奨されるやり方はFFIで定義された関数に余剰の引数を加えて必要な関数を受け付けることです。

```js
export const maybeHeadImpl = just => nothing => arr => {
  if (arr.length) {
    return just(arr[0]);
  } else {
    return nothing;
  }
};
```

```hs
foreign import maybeHeadImpl :: forall a. (forall x. x -> Maybe x) -> (forall x. Maybe x) -> Array a -> Maybe a

maybeHead :: forall a. Array a -> Maybe a
maybeHead arr = maybeHeadImpl Just Nothing arr
```

ただし、次のように書きますが、

```hs
forall a. (forall x. x -> Maybe x) -> (forall x. Maybe x) -> Array a -> Maybe a
```

以下ではないことに注意です。

```hs
forall a. ( a -> Maybe a) -> Maybe a -> Array a -> Maybe a
```

どちらの形式でも動きますが、後者は`Just`と`Nothing`の場所での招かれざる入力により晒されやすくなります。
例えばより脆弱な場合では以下のようにして呼ぶことができます。

```hs
maybeHeadImpl (\_ -> Just 1000) (Just 1000) [1,2,3]
```

これはいかなる配列についても`Just 1000`を返します。
この脆弱性は`a`が`Int`のときに（これは入力の配列に基づきます）`(\_ -> Just 1000)`と`Just 1000`がシグネチャ`(a -> Maybe a)`と`Maybe a`にそれぞれ合致しているために許されているのです。

より安全な型シグネチャでは入力の配列に基づいて`a`が`Int`に決定されたとしても、`forall x`に絡むシグネチャに合致する妥当な関数を提供する必要があります。
`(forall x. Maybe x)`の*唯一*の選択肢は`Nothing`ですが、それは`Just`値が`x`の型を前提にしてしまい、するともはや全ての`x`については妥当でなくなってしまうからです。
`(forall x. x -> Maybe x)`の唯一の選択肢は`Just`（望んでいる引数）と`(\_ -> Nothing)`であり、後者は唯一残っている脆弱性になるのです。

## 外部型の定義

`Maybe a`を返す代わりに実は`arr[0]`を返したいのだとしましょう。
型`a`ないし`undefined`値（ただ`null`ではありません）のいずれかの値を表現する型がほしいです。
この型を`Undefined a`と呼びましょう。

**外部インポート宣言**を使うと、**外部型** (foreign type) を定義することができます。
構文は外部関数を定義するのと似ています。

```haskell
foreign import data Undefined :: Type -> Type
```

このキーワード`data`は型を定義していることを表しています。
値ではありせん。
型シグネチャの代わりに、新しい型の**種**を与えます。
この場合は`Undefined`の種が `Type -> Type`であると宣言しています。
言い換えれば`Undefined`は型構築子です。

これで元の`head`の定義を単に再利用することができます。

```javascript
export const undefinedHead = arr =>
  arr[0];
```

PureScriptモジュールには以下を追加します。

```haskell
foreign import undefinedHead :: forall a. Array a -> Undefined a
```

`undefinedHead`関数の本体は`undefined`かもしれない`arr[0]`を返します。
そしてこの型シグネチャはその事実を正しく反映しています。

この関数はその型の適切な実行時表現を持っていますが、
型 `Undefined a`の値を使用する方法がありませんので、まったく役に立ちません。
いや、言い過ぎました。
別のFFIでこの型を使えますからね。

値が未定義かどうかを教えてくれる関数を書くことができます。

```haskell
foreign import isUndefined :: forall a. Undefined a -> Boolean
```

外部JavaScriptモジュールで次のように定義できます。

```javascript
export const isUndefined = value =>
  value === undefined;
```

これでPureScriptで `isUndefined`と `undefinedHead`を一緒に使用すると、
便利な関数を定義することができます。

```haskell
isEmpty :: forall a. Array a -> Boolean
isEmpty = isUndefined <<< undefinedHead
```

このように、定義したこの外部関数はとても簡単です。
つまりPureScriptの型検査器を使うことによる利益が最大限得られるのです。
一般に、外部関数は可能な限り小さく保ち、できるだけアプリケーションの処理はPureScriptコードへ移動しておくことをおすすめします。

## 例外

他の選択肢としては、空の配列の場合に例外を投げる方法があります。
厳密に言えば、純粋な関数は例外を投げるべきではありませんが、それをする柔軟さはあります。
安全性に欠けていることを関数名で示します。

```haskell
foreign import unsafeHead :: forall a. Array a -> a
```

JavaScriptモジュールでは、 `unsafeHead`を以下のように定義することができます。

```javascript
export const unsafeHead = arr => {
  if (arr.length) {
    return arr[0];
  } else {
    throw new Error('unsafeHead: empty array');
  }
};
```

## 演習

1. （普通）二次多項式`a*x^2 + b*x + c = 0`を表現するレコードが与えられているとします。

    ```hs
    type Quadratic = {
      a :: Number,
      b :: Number,
      c :: Number
    }
    ```

    二次多項式を使ってこの多項式の根を求めるJavaScriptの関数`quadraticRootsImpl`とそのラッパーの`quadraticRoots :: Quadratic -> Pair Complex`を書いてください。
    2つの根を`Complex`の数の`Pair`として返してください。
    **ヒント**：`quadraticRoots`ラッパーを使って`Pair`の構築子を`quadraticRootsImpl`に渡してください。

1. （普通）関数`toMaybe :: forall a. Undefined a -> Maybe a`を書いてください。
   この関数は`undefined`を`Nothing`に、`a`の値を`Just a`に変換します。

1. （難しい）`toMaybe`が備わっていれば`maybeHead`を以下に書き換えられます。

    ```hs
    maybeHead :: forall a. Array a -> Maybe a
    maybeHead = toMaybe <<< undefinedHead
    ```

    これは前の実装よりも良い手法なのでしょうか。
    **補足**：この演習のための単体試験はありません。

## 型クラスメンバー関数を使う

ちょうど前にFFIを越えて`Maybe`の構築子を渡す手引きをしましたが、
今回はJavaScriptを呼び出すPureScriptを書く別の場合です。
JavaScriptの呼び出しでも続けざまにPureScriptの関数を呼び出します。
ここでは型クラスのメンバー関数のFFIを越えた渡し方を探ります。

型`x`に合う適切な`show`のインスタンスを期待する外部JavaScript関数を書くことから始めます。

```js
export const boldImpl = show => x =>
  show(x).toUpperCase() + "!!!";
```

それから対応するシグネチャを書きます。

```hs
foreign import boldImpl :: forall a. (a -> String) -> a -> String
```

そして`show`の正しいインスタンスを渡すラッパー関数も書きます。

```hs
bold :: forall a. Show a => a -> String
bold x = boldImpl show x
```

代わりにポイントフリー形式だとこうです。

```hs
bold :: forall a. Show a => a -> String
bold = boldImpl show
```

そうしてラッパーを呼び出すことができます。

```text
$ spago repl

> import Test.Examples
> import Data.Tuple
> bold (Tuple 1 "Hat")
"(TUPLE 1 \"HAT\")!!!"
```

以下は複数の関数を渡すことを実演する別の例です。
これらの関数には複数引数関数 (`eq`) が含まれます。

```js
export const showEqualityImpl = eq => show => a => b => {
  if (eq(a)(b)) {
    return "Equivalent";
  } else {
    return show(a) + " is not equal to " + show(b);
  }
}
```

```hs
foreign import showEqualityImpl :: forall a. (a -> a -> Boolean) -> (a -> String) -> a -> a -> String

showEquality :: forall a. Eq a => Show a => a -> a -> String
showEquality = showEqualityImpl eq show
```

```text
$ spago repl

> import Test.Examples
> import Data.Maybe
> showEquality Nothing (Just 5)
"Nothing is not equal to (Just 5)"
```

## 作用のある関数

`bold`関数を拡張してコンソールにログ出力するようにしましょう。
ログ出力は`Effect`であり、`Effect`はJavaScriptで無引数関数として表現されます。
つまり`()`と矢印記法だとこうです。

```js
export const yellImpl = show => x => () =>
  console.log(show(x).toUpperCase() + "!!!");
```

新しい外部インポートは返る型が`String`から`Effect Unit`に変わった点以外は以前と同じです。

```hs
foreign import yellImpl :: forall a. (a -> String) -> a -> Effect Unit

yell :: forall a. Show a => a -> Effect Unit
yell = yellImpl show
```

REPLで試すと文字列が（引用符で囲まれず）直接コンソールに印字され`unit`値が返ることに気付きます。

```text
$ spago repl

> import Test.Examples
> import Data.Tuple
> yell (Tuple 1 "Hat")
(TUPLE 1 "HAT")!!!
unit
```

`Effect.Uncurried`に`EffectFn`ラッパーというものもあります。
これらは既に見た`Data.Function.Uncurried`の`Fn`ラッパーに似ています。
これらのラッパーがあればカリー化されていない作用のある関数をPureScriptで呼び出すことができます。

一般的にこれらを使うのは、
こうしたAPIをカリー化された関数に包むのではなく、
既存のJavaScriptライブラリのAPIを直接呼び出したいときぐらいです。
したがってカリー化していない`yell`の例を見せてもあまり意味がありません。
というのもJavaScriptがPureScriptの型クラスのメンバーに依っているからで、
さらにそれは既存のJavaScriptの生態系にそのメンバーが見付からないためです。

その代わりに以前の`diagonal`の例を変更し、結果を返すことに加えてログ出力を含めるとこうなります。

```js
export const diagonalLog = function(w, h) {
  let result = Math.sqrt(w * w + h * h);
  console.log("Diagonal is " + result);
  return result;
};
```

```hs
foreign import diagonalLog :: EffectFn2 Number Number Number
```

```text
$ spago repl

> import Test.Examples
> import Effect.Uncurried
> runEffectFn2 diagonalLog 3.0 4.0
Diagonal is 5
5.0
```

## 非同期関数

JavaScriptのプロミスは`aff-promise`ライブラリの助けを借りて直接PureScriptの非同期作用に翻訳されます。
より多くの情報についてはライブラリの[ドキュメント](https://pursuit.purescript.org/packages/purescript-aff-promise)をあたってください。
ここではいくつかの例に触れるだけとします。

JavaScriptの`wait`プロミス（または非同期関数）をPureScriptのプロジェクトで使いたいとします。
`ms`ミリ秒分だけ送らせて実行させるのに使うことができます。

```js
const wait = ms => new Promise(resolve => setTimeout(resolve, ms));
```

単に`Effect`（無引数関数）に包んで公開するだけでよいです。

```js
export const sleepImpl = ms => () =>
  wait(ms);
```

そして以下のようにインポートします。

```hs
foreign import sleepImpl :: Int -> Effect (Promise Unit)

sleep :: Int -> Aff Unit
sleep = sleepImpl >>> toAffE
```

そうしてこの`Promise`を`Aff`ブロック中で以下のように走らせることができます。

```text
$ spago repl

> import Prelude
> import Test.Examples
> import Effect.Class.Console
> import Effect.Aff
> :pa
… launchAff_ do
…   log "waiting"
…   sleep 300
…   log "done waiting"
…
waiting
unit
done waiting
```

REPLでの非同期ログ出力はブロック全体が実行を終了するまで印字するのを待つ点に注意しましょう。
このコードは`spago test`で走らせたときは、印字の**合間に**僅かな遅延があり、より予測に近い振舞いをします。

プロミスから値を返す別の例を見てみましょう。
この関数は`async`と`await`を使って書かれていますが、
これはプロミスの糖衣構文に過ぎません。

```js
async function diagonalWait(delay, w, h) {
  await wait(delay);
  return Math.sqrt(w * w + h * h);
}

export const diagonalAsyncImpl = delay => w => h => () =>
  diagonalWait(delay, w, h);
```

`Number`を返すため、この型を`Promise`と`Aff`のラッパーの中に表します。

```hs
foreign import diagonalAsyncImpl :: Int -> Number -> Number -> Effect (Promise Number)

diagonalAsync :: Int -> Number -> Number -> Aff Number
diagonalAsync i x y = toAffE $ diagonalAsyncImpl i x y
```

```text
$ spago repl

import Prelude
import Test.Examples
import Effect.Class.Console
import Effect.Aff
> :pa
… launchAff_ do
…   res <- diagonalAsync 300 3.0 4.0
…   logShow res
…
unit
5.0
```

## 演習
上の節の演習はまだやるべきこと一覧にあります。
もし何か良い演習の考えがあればご提案ください。

## JSON

アプリケーションでJSONを使うことには多くの理由があります。
例えばWebのAPIと疎通するよくある手段であるためです。
この節では他の用例についてもお話ししましょう。
構造的なデータをFFI越しに渡す際の型安全性を向上させる手法から始めます。

少し前のFFI関数`cumulativeSums`と`addComplex`を再訪し、
それぞれに1つバグを混入させてみましょう。

```js
export const cumulativeSumsBroken = arr => {
  let sum = 0
  let sums = []
  arr.forEach(x => {
    sum += x;
    sums.push(sum);
  });
  sums.push("Broken"); // Bug
  return sums;
};

export const addComplexBroken = a => b => {
  return {
    real: a.real + b.real,
    broken: a.imag + b.imag // Bug
  }
};
```

返る型が正しくない事実があるにも関わらず、
元の型シグネチャを使うことができ、コードはそれでもコンパイルされます。

```hs
foreign import cumulativeSumsBroken :: Array Int -> Array Int

foreign import addComplexBroken :: Complex -> Complex -> Complex
```

コードを実行することさえ可能で、そうすると予期しない結果を生み出すか実行時エラーになります。

```text
$ spago repl

> import Test.Examples
> import Data.Foldable (sum)

> sums = cumulativeSumsBroken [1, 2, 3]
> sums
[1,3,6,Broken]
> sum sums
0

> complex = addComplexBroken { real: 1.0, imag: 2.0 } { real: 3.0, imag: 4.0 }
> complex.real
4.0
> complex.imag + 1.0
NaN
> complex.imag
  var str = n.toString();
              ^
TypeError: Cannot read property 'toString' of undefined
```

例えば結果の`sums`はもはや正しい`Array Int`ではありませんが、
これは`String`が配列に含まれているからです。
そして更なる操作は即時のエラーではなく予期しない振舞いを生み出します。
というのもこれらの`sums`の`sum`は`10`ではなく`0`だからです。
これでは捜索の難しいバグになりかねませんね。

同様に`addComplexBroken`を呼び出すときは1つもエラーが出ません。
しかしながら`Complex`の結果の`imag`フィールドにアクセスすると予期しない振舞い（`7.0`ではなく`Nan`を返すため）やはっきりしない実行時エラーを生じることでしょう。

PureScriptのコードにバグ一匹通さないようにするため、JavaScriptのコードでJSONを使いましょう。

`argonaut`ライブラリには必要としているJSONの復号化と符号化の機能が備わっています。
このライブラリには素晴らしい[ドキュメント](https://github.com/purescript-contrib/purescript-argonaut#documentation)があるので、本書では基本的な用法だけを押さえます。

返る型を`Json`として定義するようにして、代わりとなる外部インポートをつくるとこうなります。

```hs
foreign import cumulativeSumsJson :: Array Int -> Json
foreign import addComplexJson :: Complex -> Complex -> Json
```

単純に既存の壊れた関数を指し示しているだけである点に注意します。

```js
export const cumulativeSumsJson = cumulativeSumsBroken
export const addComplexJson = addComplexBroken
```

そして返された`Json`の値を復号化するラッパーを書きます。

```hs
{{#include ../exercises/chapter10/test/Examples.purs:cumulativeSumsDecoded}}

{{#include ../exercises/chapter10/test/Examples.purs:addComplexDecoded}}
```

それから返る型への復号が成功しなかったどんな値も`Left`の`String`なエラーとして表れます。

```text
$ spago repl

> import Test.Examples

> cumulativeSumsDecoded [1, 2, 3]
(Left "Couldn't decode Array (Failed at index 3): Value is not a Number")

> addComplexDecoded { real: 1.0, imag: 2.0 } { real: 3.0, imag: 4.0 }
(Left "JSON was missing expected field: imag")
```

うまく動くバージョンで呼び出すと`Right`の値が返ります。

次のREPLブロックを走らせる前に、うまく動くバージョンを指し示すように`test/Examples.js`に以下の変更を加えて、これを手元で試してみましょう。

```js
export const cumulativeSumsJson = cumulativeSums
export const addComplexJson = addComplex
```

```text
$ spago repl

> import Test.Examples

> cumulativeSumsDecoded [1, 2, 3]
(Right [1,3,6])

> addComplexDecoded { real: 1.0, imag: 2.0 } { real: 3.0, imag: 4.0 }
(Right { imag: 6.0, real: 4.0 })
```

JSONを使うことは、`Map`や`Set`のような他の構造的な型をFFI越しに渡す最も簡単な方法でもあります。
ただしJSONは真偽値、数値、文字列、配列、そして他のJSONの値からなるオブジェクトのみから構成されるため、JSONでは直接`Map`や`Set`を書くことができません。
しかしこれらの構造を配列として表現することはでき（キーとバリューもまたJSONで表現されているとします）、それから`Map`や`Set`に復号し直すことができるのです。

以下は`String`のキーと`Int`のバリューからなる`Map`を変更する外部関数シグネチャと、それに伴うJSONの符号化と復号化を扱うラッパー関数の例です。

```hs
{{#include ../exercises/chapter10/test/Examples.purs:mapSetFooJson}}
```

関数合成の絶好の用例になっていますね。
これらの両方の代替案は上のものと等価です。

```hs
mapSetFoo :: Map String Int -> Either JsonDecodeError (Map String Int)
mapSetFoo = decodeJson <<< mapSetFooJson <<< encodeJson

mapSetFoo :: Map String Int -> Either JsonDecodeError (Map String Int)
mapSetFoo = encodeJson >>> mapSetFooJson >>> decodeJson
```

以下はJavaScriptでの実装です。
`Array.from`の工程が、復号の前にJavaScriptの`Map`をJSONに親和性のある形式に変換し、PureScriptの`Map`に変換し直すために必須である点に注意してください。

```js
export const mapSetFooJson = j => {
  let m = new Map(j);
  m.set("Foo", 42);
  return Array.from(m);
};
```

これで`Map`をFFI越しに送ったり受け取ったりできます。

```text
$ spago repl

> import Test.Examples
> import Data.Map
> import Data.Tuple

> myMap = fromFoldable [ Tuple "hat" 1, Tuple "cat" 2 ]

> :type myMap
Map String Int

> myMap
(fromFoldable [(Tuple "cat" 2),(Tuple "hat" 1)])

> mapSetFoo myMap
(Right (fromFoldable [(Tuple "Foo" 42),(Tuple "cat" 2),(Tuple "hat" 1)]))
```

## 演習

1. （普通）`Map`中の全ての値の`Set`を返すJavaScriptの関数とPureScriptのラッパー`valuesOfMap :: Map
   String Int -> Either JsonDecodeError (Set Int)`を書いてください。
1. （簡単）より広い種類のマップに関して動作するよう、前のJavaScriptの関数の新しいラッパーを書いてください。シグネチャは`valuesOfMapGeneric
   :: forall k v. Map k v -> Either JsonDecodeError (Set v)`です。
   なお`k`と`v`にいくつかの型クラス制約を加える必要があるでしょう。
   コンパイラが導いてくれます。
1. （普通）少し前の`quadraticRoots`を書き換えて`quadraticRootSet`としてください。
   この関数は`Complex`の根をJSONを介して（`Pair`の代わりに）`Set`として返します。
1. （難しい）少し前の`quadraticRoots`を書き換えて`quadraticRootsSafe`としてください。
   この関数はJSONを使って`Complex`の根の`Pair`をFFI越しに渡します。
   JavaScriptでは`Pair`構築子を使わないでください。
   ただしその代わりに復号器に互換性のある形式で対を返すだけにしてください。
   **ヒント**：`DecodeJson`インタンスを`Pair`に書く必要があるでしょう。
   自前の復号インスタンスを書く上での説明については[argonautのドキュメント](https://github.com/purescript-contrib/purescript-argonaut-codecs/tree/main/docs#writing-new-instances)をあたってください。
   [decodeJsonTuple](https://github.com/purescript-contrib/purescript-argonaut-codecs/blob/master/src/Data/Argonaut/Decode/Class.purs)インスタンスも参考になるかもしれません。
   「孤立インスタンス」を作ることを避けるために、`Pair`に`newtype`ラッパーが必要になる点に注意してください。
1. （普通）2次元配列を含むJSON文字列を構文解析して復号する`parseAndDecodeArray2D :: String -> Either String (Array (Array Int))`関数を書いてください。
   例えば`"[[1, 2, 3], [4, 5], [6]]"`です。
   **ヒント**：復号の前に`jsonParser`を使って`String`を`Json`に変換する必要があるでしょう。
1. （普通）以下のデータ型は値が葉にある二分木を表現します。

     ```haskell
     data Tree a
       = Leaf a
       | Branch (Tree a) (Tree a)
     ```

     汎化された`EncodeJson`及び`DecodeJson`インスタンスを`Tree`型に導出してください。
     このやり方についての説明は[argonautのドキュメント](https://github.com/purescript-contrib/purescript-argonaut-codecs/tree/main/docs#generics)をあたってください。
     なお、この演習の単体試験を有効にするには汎化された`Show`及び`Eq`インスタンスも必要になります。
     しかしJSONのインスタンスと格闘したあとではこれらの実装は直感的に進むでしょう。
1. （難しい）以下の`data`型は整数か文字列かでJSONで異なって表現されます。

     ```haskell
     data IntOrString
       = IntOrString_Int Int
       | IntOrString_String String
     ```

     この振舞いを実装する`IntOrString`データ型に`EncodeJson`及び`DecodeJson`インスタンスを書いてください。
     **ヒント**：`Control.Alt`の`alt`演算子が役立つかもしれません。

## 住所録

この節では新しく獲得したFFIとJSONの知識を適用して第8章の住所録の例を構築していきたいと思います。以下の機能を加えていきます。

- 保存ボタンをフォームの底に置き、クリックしたときにフォームの状態をJSON
  に直列化してローカルストレージに保存します。
- ページの再読み込み時にローカルストレージからJSON文書を自動的に取得しま
  す。フォームのフィールドにはこの文書の内容を入れます。
- フォームの状態を保存したり読み込んだりするのに問題があればポップアップ
  の警告を出します。

`Effect.Storage`モジュールに以下のWebストレージAPIのためのFFIラッパーをつくることから始めていきます。

- `setItem`はキーと値（両方とも文字列）を受け取り、指定されたキーでロー
  カルストレージに値を格納する計算を返します。
- `getItem`はキーを取り、ローカルストレージから関連付けられたバリューの
  取得を試みます。しかし`window.localStorage`の`getItem`メソッドは
  `null`を返しうるので、返る型は`String`ではなく`Json`です。

```haskell
foreign import setItem :: String -> String -> Effect Unit

foreign import getItem :: String -> Effect Json
```

以下はこれらの関数に対応するJavaScriptの実装で、`Effect/Storage.js`にあります。

```js
export const setItem = key => value => () =>
  window.localStorage.setItem(key, value);

export const getItem = key => () =>
  window.localStorage.getItem(key);
```

以下のように保存ボタンを作ります。

```hs
saveButton :: R.JSX
saveButton =
  D.label
    { className: "form-group row col-form-label"
    , children:
        [ D.button
            { className: "btn-primary btn"
            , onClick: handler_ validateAndSave
            , children: [ D.text "Save" ]
            }
        ]
    }
```

そして`validateAndSave`関数中では、検証された`person`をJSON文字列とし、`setItem`を使って書き込みます。

```hs
validateAndSave :: Effect Unit
validateAndSave = do
  log "Running validators"
  case validatePerson' person of
    Left errs -> log $ "There are " <> show (length errs) <> " validation errors."
    Right validPerson -> do
      setItem "person" $ stringify $ encodeJson validPerson
      log "Saved"
```

なおこの段階でコンパイルしようとすると以下のエラーに遭遇します。

```text
  No type class instance was found for
    Data.Argonaut.Encode.Class.EncodeJson PhoneType
```

これはなぜかというと`Person`レコード中の`PhoneType`が`EncodeJson`インスタンスを必要としているからです。
単純に汎用符号化インスタンスと復号化インスタンスを導出すれば完了です。
この仕組みについてより詳しくはargonautのドキュメントで見られます。

```hs
{{#include ../exercises/chapter10/src/Data/AddressBook.purs:import}}

{{#include ../exercises/chapter10/src/Data/AddressBook.purs:PhoneType_generic}}
```

これで`person`をローカルストレージに保存できます。
しかしデータを取得できない限りあまり便利ではありません。
次はそれに取り掛かりましょう。

ローカルストレージから「person」文字列を取得することから始めましょう。

```hs
item <- getItem "person"
```

それからローカルストレージから`Person`レコードへの文字列の変換を扱うお助け関数をつくります。
なおこのストレージ中の文字列は`null`かもしれないので、うまく`String`として復号化されるまでは外部の`Json`として表現します。
道中には他にも多くの変換工程があり、それぞれで`Either`の値を返します。
そのためこれらを`do`ブロックの中にまとめるのは理に適っています。

```hs
processItem :: Json -> Either String Person
processItem item = do
  jsonString <- decodeJson item
  j          <- jsonParser jsonString
  decodeJson j
```

そうしてこの結果が成功しているかどうか調べます。
もし失敗していればエラーをログ出力し既定の`examplePerson`を使います。
そうでなければローカルストレージから取得した人物を使います。

```hs
initialPerson <- case processItem item of
  Left  err -> do
    log $ "Error: " <> err <> ". Loading examplePerson"
    pure examplePerson
  Right p   -> pure p
```

最後にこの`initialPerson`を`props`レコードを介してコンポーネントに渡します。

```hs
-- Create JSX node from react component.
app = element addressBookApp { initialPerson }
```

そして状態フックで使うために別の方から拾い上げます。

```hs
mkAddressBookApp :: Effect (ReactComponent { initialPerson :: Person })
mkAddressBookApp =
  reactComponent "AddressBookApp" \props -> R.do
    Tuple person setPerson <- useState props.initialPerson
```

仕上げとして、それぞれの`Left`値の`String`に`lmap`を使って前置し、エラー文言の質を向上させます。

```hs
processItem :: Json -> Either String Person
processItem item = do
  jsonString <- lmap ("No string in local storage: " <> _) $ decodeJson item
  j          <- lmap ("Cannot parse JSON string: "   <> _) $ jsonParser jsonString
  lmap               ("Cannot decode Person: "       <> _) $ decodeJson j
```

最初のエラーのみこのアプリの通常の操作内で起こります。
他のエラーはWebブラウザの開発ツールを開いてローカルストレージ中に保存された「person」文字列を編集し、そのページを参照することで引き起こせます。
どのようにJSON文字列を変更したかが、どのエラーの引き金になるかを決定します。
それぞれのエラーを引き起こせるかどうかやってみてください。

これでローカルストレージについては押さえました。
次に`alert`アクションを実装していきます。
このアクションは`Effect.Console`モジュールの`log`アクションによく似ています。
唯一の相違点は`alert`アクションが`window.alert`メソッドを使うことで、
対して`log`アクションは`console.log`メソッドを使っています。
そういうわけで`alert`は`window.alert`が定義された環境でのみ使うことができます。
例えばWebブラウザなどです。

```hs
foreign import alert :: String -> Effect Unit
```

```js
export const alert = msg => () =>
  window.alert(msg);
```

この警告が次のいずれかの場合に現れるようにしたいです。

- 利用者が検証エラーを含むフォームを保存しようと試みている。
- 状態がローカルストレージから取得できない。

以上は単に以下の行で`log`を`alert`に置き換えるだけで達成できます。

```hs
Left errs -> alert $ "There are " <> show (length errs) <> " validation errors."

alert $ "Error: " <> err <> ". Loading examplePerson"
```

## 演習

 1. （普通）`localStorage`オブジェクトの `removeItem`メソッドのラッパーを書き、
    `Effect.Storage`モジュールに外部関数を追加してください
 1. （普通）「リセット」ボタンを追加してください。
    このボタンをクリックすると新しく作った`removeItem`関数を呼び出して
    ローカルストレージから「人物」の項目を削除します。
 1. （簡単）JavaScriptの `Window`オブジェクトの `confirm`メソッドのラッパーを書き、
    `Effect.Alert`モジュールにその外部関数を追加してください。
 1. （普通）利用者が「リセット」ボタンをクリックしたときにこの`confirm`関数を呼び出し、
    本当にアドレス帳を白紙にしたいか尋ねるようにしてください。

## まとめ

この章では、PureScriptから外部のJavaScriptコードを扱う方法を学びました。また、FFIを使用して信頼できるコードを書く時に生じる問題について見てきました。

- 外部関数が正しい表現を持っていることを確かめる重要性を見てきました。
- 外部型や`Json`データ型を使用することによって、null値やJavaScriptの他の
  型のデータのような特殊な場合に対処する方法を学びました。
- 安全にJSONデータを直列化・直列化復元する方法を見ました。

より多くの例については、Githubの `purescript`組織、`purescript-contrib`組織および
`purescript-node`組織が、FFIを使用するライブラリの例を多数提供しています。残りの章では、型安全な方法で現実世界の問題を解決するために使うライブラリを幾つか見ていきます。

# 補遺

## JavaScriptからPureScriptを呼び出す

少なくとも単純な型を持った関数については、JavaScriptからPureScript関数を呼び出すのはとても簡単です。

例として以下のような簡単なモジュールを見てみましょう。

```haskell
module Test where

gcd :: Int -> Int -> Int
gcd 0 m = m
gcd n 0 = n
gcd n m
  | n > m     = gcd (n - m) m
  | otherwise = gcd (m - n) n
```

この関数は、減算を繰り返すことによって2つの数の最大公約数を見つけます。
関数を定義するのにPureScriptを使いたくなるかもしれない良い例となっていますが、
JavaScriptからそれを呼び出すためには条件があります。
PureScriptでパターン照合と再帰を使用してこの関数を定義するのは簡単で、実装する開発者は型検証器の恩恵を受けることができます。

この関数をJavaScriptから呼び出す方法を理解するには、PureScriptの関数は常に引数がひとつのJavaScript関数へと変換され、引数へは次のようにひとつづつ適用していかなければならないことを理解するのが重要です。

```javascript
import Test from 'Test.js';
Test.gcd(15)(20);
```

ここでは、コードがPureScriptモジュールをESモジュールにコンパイルする `spago build`でコンパイルされていると仮定しています。
そのため、 `import`を使って `Test`モジュールをインポートした後、 `Test`オブジェクトの `gcd`関数を参照することができました。

`pulp build -O --to file.js`を使用して、ブラウザ用のJavaScriptコードをバンドルすることもできます。
その場合、グローバルなPureScript名前空間から `Test`モジュールにアクセスします。デフォルトは `PS`です。

```javascript
var Test = PS.Test;
Test.gcd(15)(20);
```

## 名前の生成を理解する

PureScriptはコード生成時にできるだけ名前を保存することを目的としています。具体的には、少なくともトップレベルで宣言される名前については、PureScriptやJavaScriptのキーワードでなければほとんどの識別子が保存されます。

識別子としてJavaScriptのキーワードを使う場合は、名前はダブルダラー記号でエスケープされます。たとえば、次のPureScriptコードを考えてみます。

```haskell
null = []
```

これは以下のJavaScriptを生成します。

```javascript
var $$null = [];
```

また、識別子に特殊文字を使用したい場合は、単一のドル記号を使用してエスケープされます。たとえば、このPureScriptコードを考えます。

```haskell
example' = 100
```

これは以下のJavaScriptを生成します。

```javascript
var example$prime = 100;
```

コンパイルされたPureScriptコードがJavaScriptから呼び出されることを意図している場合、識別子は英数字のみを使用し、JavaScriptの予約語を避けることをお勧めします。
ユーザ定義演算子がPureScriptコードでの使用のために提供される場合でも、JavaScriptから使うための英数字の名前を持った代替関数を提供しておくことをお勧めします。

## 実行時のデータ表現

型はプログラムがある意味で「正しい」ことをコンパイル時に判断できるようにします。つまり、その点については壊れることがありません。しかし、これは何を意味するのでしょうか？PureScriptでは式の型は実行時の表現と互換性がなければならないことを意味します。

そのため、PureScriptとJavaScriptコードを一緒に効率的に使用できるように、実行時のデータ表現について理解することが重要です。これは、与えられた任意のPureScriptの式について、その値が実行時にどのように評価されるかという挙動を理解できるべきであることを意味しています。

PureScriptの式は、実行時に特に単純な表現を持っているということは朗報です。型を考慮すれば式の実行時のデータ表現を把握することが常に可能です。

単純な型については、対応関係はほとんど自明です。たとえば、式が型 `Boolean`を持っていれば、実行時のその値 `v`は `typeof v ===
'boolean'`を満たします。つまり、型 `Boolean`の式は `true`もしくは
`false`のどちらか一方の（JavaScriptの）値へと評価されます。特に`null`や `undefined`に評価される型
`Boolean`のPureScriptの式はありません。

`Int`や`Number`や`String`の型の式についても同様のことが成り立ちます。`Int`や`Number`型の式は
`null`でないJavaScriptの数へと評価されますし、 `String`型の式は
`null`でないJavaScriptの文字列へと評価されます。たとえ`typeof`を使うことによって型`Number`の値と見分けがつかなくなっても、型`Int`の式は実行時に整数に評価されます。

`Unit`についてはどうでしょうか？`Unit`には現住 (`unit`)
が1つのみで値が観測できないため、実のところ実行時に何で表現されるかは重要ではありません。古いコードは`{}`を使って表現する傾向がありました。しかし比較的新しいコードでは`undefined`を使う傾向にあります。なので、`Unit`を表現するのに使うものは本当に何でも問題にならないのですが、`undefined`を使うことが推奨されます。（関数から何も返さないときも`undefined`を返します。）

もっと複雑な型についてはどうでしょうか？

すでに見てきたように、PureScriptの関数は引数がひとつのJavaScriptの関数に対応しています。厳密に言えば、任意の型 `a`、 `b`について、式 `f`の型が `a -> b`で、式 `x`が型 `a`についての適切な実行時表現の値へと評価されるなら、 `f`はJavaScriptの関数へと評価され、 `x`を評価した結果に `f`を適用すると、それは型 `b`の適切な実行時表現を持ちます。簡単な例としては、 `String -> String`型の式は、 `null`でないJavaScript文字列から `null`でないJavaScript文字列への関数へと評価されます。

ご想像のとおり、PureScriptの配列はJavaScriptの配列に対応しています。しかし、PureScriptの配列は均質であり、つまりすべての要素が同じ型を持っていることは覚えておいてください。具体的には、もしPureScriptの式
`e`が何らかの型 `a`について型 `Array a`を持っているなら、 `e`はすべての要素が型
`a`の適切な実行時表現を持った（`null`でない）JavaScript配列へと評価されます。

PureScriptのレコードがJavaScriptのオブジェクトへと評価されることはすでに見てきました。ちょうど関数と配列の場合のように、そのラベルに関連付けられている型を考慮すれば、レコードのフィールドのデータの実行時の表現についても推論することができます。もちろん、レコードのそれぞれのフィールドは、同じ型である必要はありません。

## ADTの表現

PureScriptコンパイラは、代数的データ型のすべての構築子についてそれぞれ関数を定義し、新たなJavaScriptオブジェクト型を作成します。これらの構築子はこれらのプロトタイプに基づいて新しいJavaScriptオブジェクトを作成する関数に対応しています。

たとえば、次のような単純なADTを考えてみましょう。

```haskell
data ZeroOrOne a = Zero | One a
```

PureScriptコンパイラは、次のようなコードを生成します。

```javascript
function One(value0) {
    this.value0 = value0;
};

One.create = function (value0) {
    return new One(value0);
};

function Zero() {
};

Zero.value = new Zero();
```

ここで2つのJavaScriptオブジェクト型 `Zero`と
`One`を見てください。JavaScriptのキーワード`new`を使用すると、それぞれの型の値を作成することができます。引数を持つ構築子については、コンパイラは
`value0`、 `value1`などと呼ばれるフィールドに対応するデータを格納します。

PureScriptコンパイラは補助関数も生成します。引数のない構築子については、コンパイラは構築子が使われるたびに
`new`演算子を使うのではなく、データを再利用できるように
`value`プロパティを生成します。ひとつ以上の引数を持つ構築子では、適切な表現を持つ引数を取り適切な構築子を適用する
`create`関数をコンパイラは生成します。

2引数以上の構築子についてはどうでしょうか？その場合でも、PureScriptコンパイラは新しいオブジェクト型と補助関数を作成します。しかし今回は、補助関数は2引数のカリー化された関数です。たとえば、次のような代数的データ型を考えます。

```haskell
data Two a b = Two a b
```

このコードからは、次のようなJavaScriptコードが生成されます。

```javascript
function Two(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
};

Two.create = function (value0) {
    return function (value1) {
        return new Two(value0, value1);
    };
};
```

ここで、オブジェクト型 `Two`の値はキーワード`new`または `Two.create`関数を使用すると作成することができます。

newtypeの場合はまた少し異なります。newtypeは単一の引数を取る単一の構築子を持つよう制限された代数的データ型であることを思い出してください。この場合には、実際はnewtypeの実行時表現は、その引数の型と同じになります。

例えば、電話番号を表す次のようなnewtypeを考えます。

```haskell
newtype PhoneNumber = PhoneNumber String
```

これは実行時にはJavaScriptの文字列として表されます。newtypeは型安全性の追加の層を提供しますが、実行時の関数呼び出しのオーバーヘッドがないので、ライブラリを設計するのに役に立ちます。

## 量化された型の表現

量化された型（多相型）の式は、制限された表現を実行時に持っています。実際には、所与の量化された型を持つ式が比較的少ないということですが、これによってとても効率的に解決できることを意味しています。

例えば、次の多相型を考えてみます。

```haskell
forall a. a -> a
```

この型を持っている関数にはどんなものがあるでしょうか。少なくともひとつはこの型を持つ関数が存在しています。すなわち、
`Prelude`で定義されている恒等関数 `id`です。

```haskell
id :: forall a. a -> a
id a = a
```

実のところ、 `id`の関数はこの型の**唯一の**（全）関数です！これは確かに間違いなさそうに見えますが（この型を持った
`id`とは明らかに異なる式を書こうとしてみてください）、これを確かめるにはどうしたらいいでしょうか。これは型の実行時表現を考えることによって確認することができます。

量化された型 `forall a. t`の実行時表現はどうなっているのでしょうか。さて、この型の実行時表現を持つ任意の式は、型 `a`をどのように選んでも型 `t`の適切な実行時表現を持っていなければなりません。上の例では、型 `forall a. a -> a`の関数は、 `String -> String`、 `Number -> Number`、 `Array Boolean -> Array Boolean`などといった型について、適切な実行時表現を持っていなければなりません。 これらは、文字列から文字列、数から数の関数でなくてはなりません。

しかし、それだけでは十分ではありません。量化された型の実行時表現は、これよりも更に厳しくなります。任意の式が**パラメトリック多相的**でなければなりません。つまり、その実装において、引数の型についてのどんな情報も使うことができないのです。この追加の条件は、考えられる多相型のうち、以下のJavaScriptの関数のような問題のある実装を防止します。

```javascript
function invalid(a) {
    if (typeof a === 'string') {
        return "Argument was a string.";
    } else {
        return a;
    }
}
```

確かにこの関数は文字列から文字列、数から数へというような関数ではありますが、追加の条件を満たしていません。引数の実行時の型を調べており、したがって、この関数は型 `forall a. a -> a`の正しい実装だとはいえないのです。

関数の引数の実行時の型を検査することができなければ、唯一の選択肢は引数をそのまま返すことだけであり、したがって `id`はたしかに `forall a. a -> a`の唯一の実装なのです。

**パラメトリック多相** (parametric polymorphism) と**パラメトリック性** (parametricity)
についての詳しい議論は本書の範囲を超えています。ただ注目していただきたいことは、PureScriptの型は、実行時に**消去**されているので、PureScriptの多相関数は（FFIを使わない限り）引数の実行時表現を検査することが**できず**、そのためこの多相的なデータの表現が適切になっているということなのです。

## 制約のある型の表現

型クラス制約を持つ関数は、実行時に面白い表現を持っています。関数の振る舞いはコンパイラによって選ばれた型クラスのインスタンスに依存する可能性があるため、関数には**型クラス辞書**
(type class dictionary)
と呼ばれる追加の引数が与えられます。この辞書には選ばれたインスタンスから提供される型クラスの関数の実装が含まれます。

例えば、 `Show`型クラスを使った制約のある型を持つ、次のような単純なPureScript関数について考えます。

```haskell
shout :: forall a. Show a => a -> String
shout a = show a <> "!!!"
```

生成されるJavaScriptは次のようになります。

```javascript
var shout = function (dict) {
    return function (a) {
        return show(dict)(a) + "!!!";
    };
};
```

`shout`は1引数ではなく、2引数の（カリー化された）関数にコンパイルされていることに注意してください。最初の引数 `dict`は
`Show`制約の型クラス辞書です。 `dict`には型 `a`の `show`関数の実装が含まれています。

最初の引数として明示的に`Data.Show`の型クラス辞書を渡すと、JavaScriptからこの関数を呼び出すことができます。

```javascript
import { showNumber } from 'Data.Show'

shout(showNumber)(42);
```

## 演習

 1. （簡単）これらの型の実行時の表現は何でしょうか。

     ```haskell
     forall a. a
     forall a. a -> a -> a
     forall a. Ord a => Array a -> Boolean
     ```

     これらの型を持つ式についてわかることはなんでしょうか。
1. （普通）`spago build`を使ってコンパイルし、NodeJSの `import`機能を使ってモジュールをインポートすることで、JavaScriptから `arrays`ライブラリの関数を使ってみてください。**ヒント**：生成されたCommonJSモジュールがNodeJSモジュールのパスで使用できるように、出力パスを設定する必要があります。

## 副作用の表現

`Effect`モナドも外部型として定義されています。その実行時表現はとても簡単です。型 `Effect
a`の式は引数なしのJavaScript関数へと評価されます。この関数はあらゆる副作用を実行し型 `a`の適切な実行時表現で値を返します。

`Effect`型構築子の定義は、 `Effect`モジュールで次のように与えられています。

```haskell
foreign import data Effect :: Type -> Type
```

簡単な例として、 `random`パッケージで定義される `random`関数を考えてみてください。その型は次のようなものでした。

```haskell
foreign import random :: Effect Number
```

`random`関数の定義は次のように与えられます。

```javascript
export const random = Math.random;
```

`random`関数は実行時には引数なしの関数として表現されていることに注目してください。これは乱数生成という副作用を実行しそれを返しますが、返り値は
`Number`型の実行時表現と一致します。それは `null`でないJavaScriptの数です。

もう少し興味深い例として、`console`パッケージ中の`Effect.Console`モジュールで定義された `log`関数を考えてみましょう。
`log`関数は次の型を持っています。

```haskell
foreign import log :: String -> Effect Unit
```

この定義は次のようになっています。

```javascript
export const log = function (s) {
  return function () {
    console.log(s);
  };
};
```

実行時の
`log`の表現は、単一の引数のJavaScript関数で、引数なしの関数を返します。内側の関数はコンソールにメッセージを書き込むという副作用を実行します。

`Effect a`型の式は、通常のJavaScriptのメソッドのようにJavaScriptから呼び出すことができます。例えば、この
`main`関数は何らかの型 `a`について`Effect a`という型でなければならないので、次のように実行することができます。

```javascript
import { main } from 'Main'

main();
```

`spago bundle-app --to`または `spago run`を使用するときは、`Main`モジュールが定義されている場合は常に、この
`main`の呼び出しを自動的に生成することができます。
