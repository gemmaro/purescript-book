# 外部関数インターフェース

## この章の目標

This chapter will introduce PureScript's _foreign function interface_ (or
_FFI_), which enables communication from PureScript code to JavaScript code
and vice versa. We will cover how to:

- 純粋で、作用のある、非同期なJavaScript関数をPureScriptから呼び出す。
- 型付けされていないデータを扱う。
- `argonaut`パッケージを使ってJSONにエンコードしたりJSONを構文解析したりする。

この章の終わりにかけて、住所録の例に立ち返ります。
この章の目的は、FFIを使ってアプリケーションに次の新しい機能を追加することです。

- 利用者にポップアップ通知で警告する。
- フォームのデータを直列化してブラウザのローカルストレージに保存し、アプリケーションが再起動したときにそれを再読み込みする

There is also an addendum covering some additional topics that are not as
commonly sought-after. Feel free to read these sections, but don't let them
stand in the way of progressing through the remainder of the book if they're
less relevant to your learning objectives:

- 実行時のPureScriptの値の表現を理解する。
- JavaScriptからPureScriptを呼び出す。

## プロジェクトの準備

The source code for this module is a continuation of the source code from
chapters 3, 7, and 8. As such, the source tree includes the appropriate
source files from those chapters.

この章は`argonaut`ライブラリを依存関係として導入しています。
このライブラリはJSONにエンコードしたりJSONをデコードしたりするために使います。

この章の演習は`test/MySolutions.purs`に書き、`spago
test`を走らせることによって`test/Main.purs`中の単体試験について確認できます。

住所録アプリは`parcel src/index.html
--open`で立ち上げることができます。8章と同じ作業の流れになっているので、より詳しい説明についてはそちらの章を参照してください。

## 免責事項

PureScript provides a straightforward foreign function interface to make
working with JavaScript as simple as possible. However, it should be noted
that the FFI is an _advanced_ feature of the language. To use it safely and
effectively, you should understand the runtime representation of the data
you plan to work with. This chapter aims to impart such an understanding as
pertains to code in PureScript's standard libraries.

PureScript's FFI is designed to be very flexible. In practice, this means
that developers have a choice between giving their foreign functions very
simple types or using the type system to protect against accidental misuses
of foreign code. Code in the standard libraries tends to favor the latter
approach.

簡単な例としては、JavaScriptの関数で戻り値が `null`にならないことは保証できません。
実のところ、JavaScriptらしさのあるコードはかなり頻繁に `null`を返します。
しかし、大抵PureScriptの型にnull値が巣喰うことはありません。
そのため、FFIを使ってJavaScriptコードのインターフェイスを設計するとき、これらの特殊な場合を適切に処理するのは開発者の責任です。

## PureScriptからJavaScriptを呼び出す

PureScriptからJavaScriptコードを使用する最も簡単な方法は、 _外部インポート宣言_ (foreign import
declaration) を使用し、既存のJavaScriptの値に型を与えることです。
外部インポート宣言には _外部JavaScriptモジュール_ (foreign JavaScript module) から _エクスポートされた_
対応するJavaScriptでの宣言がなくてはなりません。

例えば特殊文字をエスケープすることによりURIのコンポーネントをエンコードするJavaScriptの
`encodeURIComponent`関数について考えてみます。

```text
$ node

node> encodeURIComponent('Hello World')
'Hello%20World'
```

This function has the correct runtime representation for the function type `String -> String`, since it takes non-null strings to non-null strings and has no other side-effects.

次のような外部インポート宣言を使うと、この関数に型を割り当てることができます。

```haskell
{{#include ../exercises/chapter10/test/URI.purs}}
```

We also need to write a foreign JavaScript module to import it from. A
corresponding foreign JavaScript module is one of the same name but the
extension changed from `.purs` to `.js`. If the Purescript module above is
saved as `URI.purs`, then the foreign JavaScript module is saved as
`URI.js`.  Since `encodeURIComponent` is already defined, we have to export
it as `_encodeURIComponent`:

```javascript
{{#include ../exercises/chapter10/test/URI.js}}
```

バージョン0.15からPureScriptはJavaScriptと通訳する際にESモジュールシステムを使います。
ESモジュールではオブジェクトに`export`キーワードを与えることで関数と値がモジュールからエクスポートされます。

これら2つの部品を使うことで、PureScriptで書かれた関数のように、PureScriptから`encodeURIComponent`関数を使うことができます。
例えばPSCiで上記の計算を再現できます。

```text
$ spago repl

> import Test.URI
> _encodeURIComponent "Hello World"
"Hello%20World"
```

外部モジュールには独自の関数も定義できます。
以下は`Number`を平方する独自のJavaScript関数を作って呼び出す方法の一例です。

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

## 多変数関数

第2章の`diagonal`関数を外部モジュールで書き直してみましょう。
この関数は直角三角形の対角線を計算します。

```hs
{{#include ../exercises/chapter10/test/Examples.purs:diagonal}}
```

Recall that functions in PureScript are _curried_. `diagonal` is a function
that takes a `Number` and returns a _function_ that takes a `Number` and
returns a `Number`.

```js
{{#include ../exercises/chapter10/test/Examples.js:diagonal}}
```

もしくはES6の矢印構文ではこうです（後述するES6についての補足を参照してください）。

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

JavaScriptでカリー化された関数を書くことは、ただでさえJavaScriptらしいものではない上に、常に可能というわけでもありません。
よくある多変数なJavaScriptの関数は _カリー化されていない_ 形式を取るでしょう。

```js
{{#include ../exercises/chapter10/test/Examples.js:diagonal_uncurried}}
```

モジュール`Data.Function.Uncurried`は*梱包*型とカリー化されていない関数を取り扱う関数をエクスポートします。

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
`Fn2 a b c`は、型 `a`と `b`の2つの引数、返り値の型 `c`をもつカリー化されていない関数の型を表現しています。
これを使って外部モジュールから`diagonalUncurried`をインポートしました。

We can then call it with `runFn2`, which takes the uncurried function and
then the arguments.

```text
$ spago repl

> import Test.Examples
> import Data.Function.Uncurried
> runFn2 diagonalUncurried 3.0 4.0
5.0
```

`functions`パッケージでは0引数から10引数までの関数について同様の型構築子が定義されています。

## カリー化されていない関数についての補足

PureScript's curried functions have certain advantages. It allows us to
partially apply functions, and to give type class instances for function
types – but it comes with a performance penalty. For performance-critical
code, it is sometimes necessary to define uncurried JavaScript functions
which accept multiple arguments.

PureScriptでカリー化されていない関数を作ることもできます。
2引数の関数については`mkFn2`関数が使えます。

```haskell
{{#include ../exercises/chapter10/test/Examples.purs:uncurried_add}}
```

前と同様に`runFn2`関数を使うと、カリー化されていない2引数の関数を適用できます。

```haskell
{{#include ../exercises/chapter10/test/Examples.purs:uncurried_sum}}
```

ここで重要なのは、引数が全て適用されるなら、コンパイラは `mkFn2`関数や `runFn2`関数を*インライン化*するということです。
そのため、生成されるコードはとても簡潔になります。

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

And the resulting generated code, which is less compact due to the nested
functions:

```javascript
var curriedAdd = function (n) {
  return function (m) {
    return m + n | 0;
  };
};

var curriedSum = curriedAdd(3)(10);
```

## 現代的なJavaScriptの構文についての補足

The arrow function syntax we saw earlier is an ES6 feature, which is
incompatible with some older browsers (namely IE11). As of writing, it is
[estimated that arrow functions are unavailable for the 6% of
users](https://caniuse.com/#feat=arrow-functions) who have not yet updated
their web browser.

To be compatible with the most users, the JavaScript code generated by the
PureScript compiler does not use arrow functions. It is also recommended to
**avoid arrow functions in public libraries** for the same reason.

You may still use arrow functions in your own FFI code, but then you should
include a tool such as [Babel](https://github.com/babel/babel#intro) in your
deployment workflow to convert these back to ES5 compatible functions.

ES6の矢印関数がより読みやすく感じたら[Lebab](https://github.com/lebab/lebab)のようなツールを使ってコンパイラの`output`ディレクトリにJavaScriptのコードを変換できます。

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
   `Data.Function.Uncurried`の梱包`Fn`を使ってください。
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

To demonstrate passing `Array`s, here's how to call a JavaScript function
that takes an `Array` of `Int` and returns the cumulative sum as another
array. Recall that since JavaScript does not have a separate type for `Int`,
both `Int` and `Number` in PureScript translate to `Number` in JavaScript.

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

To demonstrate passing `Records`, here's how to call a JavaScript function
that takes two `Complex` numbers as records and returns their sum as another
record. Note that a `Record` in PureScript is represented as an `Object` in
JavaScript:

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

Note that the above techniques require trusting that JavaScript will return
the expected types, as PureScript cannot apply type checking to JavaScript
code. We will describe this type safety concern in more detail later on in
the JSON section, as well as cover techniques to protect against type
mismatches.

## 演習

1. （普通）`Complex`な数の配列を取って別の複素数の配列として累計の和を返すJavaScriptの関数`cumulativeSumsComplex`（と対応するPureScriptの外部インポート）を書いてください。

## 単純な型を越えて

`String`、`Number`、`Array`、そして`Record`といった、JavaScript固有の表現を持つ型をFFI越しに送ったり受け取ったりする方法を数例見てきました。
ここから`Maybe`のようなPureScriptで使える幾つかの他の型の使い方を押さえていきます。

外部宣言を使用して、配列についての `head`関数を改めて作成したいとしましょう。
JavaScriptでは次のような関数を書くことになるでしょう。

```javascript
export const head = arr =>
  arr[0];
```

この関数をどう型付けましょうか。
型 `forall a. Array a -> a`を与えようとしても、空の配列に対してこの関数は `undefined`を返します。
したがって型`forall a. Array a -> a`は正しくこの実装を表現していないのです。

代わりにこの特殊な場合を扱うために`Maybe`値を返したいところです。

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

外部モジュールで直接`Data.Maybe`モジュールをインポートして使うことはお勧めしません。というのもコードがコード生成器の変化に対して脆くなるからです。`create`や`value`は公開のAPIではありません。加えて、このようにすると、不要なコードを消去する`purs
bundle`を使う際に問題を引き起こす可能性があります。

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

And not:

```hs
forall a. (a -> Maybe a) -> Maybe a -> Array a -> Maybe a
```

While both forms work, the latter is more vulnerable to unwanted inputs in
place of `Just` and `Nothing`.

例えば、比較的脆い方では、以下のように呼び出せるでしょう。

```hs
maybeHeadImpl (\_ -> Just 1000) (Just 1000) [1,2,3]
```

これは如何なる配列の入力に対しても`Just 1000`を返します。

This vulnerability is allowed because `(\_ -> Just 1000)` and `Just 1000` match the signatures of `(a -> Maybe a)` and `Maybe a`, respectively, when `a` is `Int` (based on input array).

より安全な型シグネチャでは、入力の配列に基づいて`a`が`Int`に決定されたとしても、`forall x`に絡むシグネチャに合致する妥当な関数を提供する必要があります。`(forall x. Maybe x)`の *唯一* の選択肢は`Nothing`ですが、それは`Just`値が`x`の型を前提にしてしまうと、もはや全ての`x`については妥当でなくなってしまうからです。`(forall x. x -> Maybe x)`の唯一の選択肢は`Just`（望まれている引数）と`(\_ -> Nothing)`であり、後者は唯一残っている脆弱性になるのです。

## 外部型の定義

Suppose instead of returning a `Maybe a`, we want to return `arr[0]`. We
want a type that represents a value either of type `a` or the `undefined`
value (but not `null`). We'll call this type `Undefined a`.

_外部インポート宣言_ を使うと、*外部型* (foreign type) を定義できます。構文は外部関数を定義するのと似ています。

```haskell
foreign import data Undefined :: Type -> Type
```

このキーワード`data`は*型*を定義していることを表しています。
値ではありせん。
型シグネチャの代わりに、新しい型の*種*を与えます。
この場合は`Undefined`の種が `Type -> Type`であると宣言しています。
言い換えれば`Undefined`は型構築子です。

We can now reuse our original definition for `head`:

```javascript
export const undefinedHead = arr =>
  arr[0];
```

PureScriptモジュールには以下を追加します。

```haskell
foreign import undefinedHead :: forall a. Array a -> Undefined a
```

The body of the `undefinedHead` function returns `arr[0]`, which may be
`undefined`, and the type signature correctly reflects that fact.

This function has the correct runtime representation for its type, but it's
quite useless since we have no way to use a value of type `Undefined
a`. Well, not exactly. We can use this type in another FFI!

値が未定義かどうかを教えてくれる関数を書くことができます。

```haskell
foreign import isUndefined :: forall a. Undefined a -> Boolean
```

外部JavaScriptモジュールで次のように定義できます。

```javascript
export const isUndefined = value =>
  value === undefined;
```

これでPureScriptで `isUndefined`と `undefinedHead`を一緒に使用すると、便利な関数を定義できます。

```haskell
isEmpty :: forall a. Array a -> Boolean
isEmpty = isUndefined <<< undefinedHead
```

Here, the foreign function we defined is very simple, which means we can
benefit from using PureScript's typechecker as much as possible. This is
good practice in general: foreign functions should be kept as small as
possible, and application logic moved into PureScript code wherever
possible.

## 例外

他の選択肢としては、空の配列の場合に例外を投げる方法があります。
厳密に言えば、純粋な関数は例外を投げるべきではありませんが、そうする柔軟さはあります。
安全性に欠けていることを関数名で示します。

```haskell
foreign import unsafeHead :: forall a. Array a -> a
```

JavaScriptモジュールでは、`unsafeHead`を以下のように定義できます。

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

    二次多項式を使ってこの多項式の根を求めるJavaScriptの関数`quadraticRootsImpl`とその梱包の`quadraticRoots :: Quadratic -> Pair Complex`を書いてください。
    2つの根を`Complex`の数の`Pair`として返してください。
    *手掛かり*：梱包`quadraticRoots`を使って`Pair`の構築子を`quadraticRootsImpl`に渡してください。

1. （普通）関数`toMaybe :: forall a. Undefined a -> Maybe a`を書いてください。
   この関数は`undefined`を`Nothing`に、`a`の値を`Just a`に変換します。

1. （難しい）`toMaybe`が準備できたら、`maybeHead`を以下に書き換えられます。

    ```hs
    maybeHead :: forall a. Array a -> Maybe a
    maybeHead = toMaybe <<< undefinedHead
    ```

    これは前の実装よりも良いやり方なのでしょうか。
    *補足*：この演習のための単体試験はありません。

## 型クラスメンバー関数を使う

Like our earlier guide on passing the `Maybe` constructor over FFI, this is
another case of writing PureScript that calls JavaScript, which calls
PureScript functions again. Here we will explore how to pass type class
member functions over the FFI.

We start with writing a foreign JavaScript function that expects the
appropriate instance of `show` to match the type of `x`.

```js
export const boldImpl = show => x =>
  show(x).toUpperCase() + "!!!";
```

それから対応するシグネチャを書きます。

```hs
foreign import boldImpl :: forall a. (a -> String) -> a -> String
```

And a wrapper function that passes the correct instance of `show`:

```hs
bold :: forall a. Show a => a -> String
bold x = boldImpl show x
```

Alternatively, in point-free form:

```hs
bold :: forall a. Show a => a -> String
bold = boldImpl show
```

そうして梱包を呼び出すことができます。

```text
$ spago repl

> import Test.Examples
> import Data.Tuple
> bold (Tuple 1 "Hat")
"(TUPLE 1 \"HAT\")!!!"
```

以下は複数の関数を渡す別の実演例です。
これらの関数には複数引数の関数 (`eq`) が含まれます。

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
ログ出力は`Effect`であり、`Effect`はJavaScriptにおいて無引数関数として表現されます。
つまり`()`と矢印記法だとこうです。

```js
export const yellImpl = show => x => () =>
  console.log(show(x).toUpperCase() + "!!!");
```

新しくなった外部インポートは、返る型が`String`から`Effect Unit`に変わった点以外は以前と同じです。

```hs
foreign import yellImpl :: forall a. (a -> String) -> a -> Effect Unit

yell :: forall a. Show a => a -> Effect Unit
yell = yellImpl show
```

When testing this in the repl, notice that the string is printed directly to
the console (instead of being quoted), and a `unit` value is returned.

```text
$ spago repl

> import Test.Examples
> import Data.Tuple
> yell (Tuple 1 "Hat")
(TUPLE 1 "HAT")!!!
unit
```

`Effect.Uncurried`に梱包`EffectFn`というものもあります。
これらは既に見た`Data.Function.Uncurried`の梱包`Fn`に似ています。
これらの梱包があればカリー化されていない作用のある関数をPureScriptで呼び出すことができます。

You'd generally only use these if you want to call existing JavaScript
library APIs directly rather than wrapping those APIs in curried
functions. So it doesn't make much sense to present an example of uncurried
`yell`, where the JavaScript relies on PureScript type class members since
you wouldn't find that in the existing JavaScript ecosystem.

翻って以前の`diagonal`の例を変更し、結果を返すことに加えてログ出力を含めるとこうなります。

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

`aff-promise`ライブラリの助けを借りるとJavaScriptのプロミスは直接PureScriptの非同期作用に翻訳されます。
詳細についてはライブラリの[ドキュメント](https://pursuit.purescript.org/packages/purescript-aff-promise)をあたってください。
ここでは幾つかの例に触れるだけとします。

JavaScriptの`wait`プロミス（または非同期関数）をPureScriptのプロジェクトで使いたいとします。
`ms`ミリ秒分だけ送らせて実行させるのに使うことができます。

```js
const wait = ms => new Promise(resolve => setTimeout(resolve, ms));
```

単に`Effect`（無引数関数）に包んで公開するだけで大丈夫です。

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

そうして`Aff`ブロック中でこの`Promise`を以下のように走らせることができます。

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

Note that asynchronous logging in the repl waits to print until the entire
block has finished executing. This code behaves more predictably when run
with `spago test` where there is a slight delay _between_ prints.

他にプロミスから値を返す例を見てみましょう。
この関数は`async`と`await`を使って書かれていますが、これはプロミスの糖衣構文に過ぎません。

```js
async function diagonalWait(delay, w, h) {
  await wait(delay);
  return Math.sqrt(w * w + h * h);
}

export const diagonalAsyncImpl = delay => w => h => () =>
  diagonalWait(delay, w, h);
```

`Number`を返すため、この型を`Promise`と`Aff`の梱包の中で表現します。

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

上の節の演習はまだやるべきことの一覧にあります。
もし何か良い演習の考えがあればご提案ください。

## JSON

There are many reasons to use JSON in an application; for example, it's a
common means of communicating with web APIs. This section will discuss other
use-cases, too, beginning with a technique to improve type safety when
passing structural data over the FFI.

少し前のFFI関数`cumulativeSums`と`addComplex`を再訪し、それぞれに1つバグを混入させてみましょう。

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

We can use the original type signatures, and the code will still compile,
despite the incorrect return types.

```hs
foreign import cumulativeSumsBroken :: Array Int -> Array Int

foreign import addComplexBroken :: Complex -> Complex -> Complex
```

コードの実行さえ可能で、そうすると予期しない結果を生み出すか実行時エラーになります。

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

例えば結果の`sums`はもはや正しい`Array Int`ではありませんが、それは`String`が配列に含まれているからです。
そして更なる操作は即時のエラーではなく予期しない挙動を生み出します。
というのもこれらの`sums`の`sum`は`10`ではなく`0`だからです。
これでは捜索の難しいバグになりかねませんね。

同様に`addComplexBroken`を呼び出すときは1つもエラーが出ません。
しかし、`Complex`の結果の`imag`フィールドにアクセスすると予期しない挙動（`7.0`ではなく`Nan`を返すため）やはっきりしない実行時エラーを生じることでしょう。

PureScriptのコードにバグ一匹通さないようにするため、JavaScriptのコードでJSONを使いましょう。

`argonaut`ライブラリにはこのために必要なJSONのデコードとエンコードの機能が備わっています。
このライブラリには素晴らしい[ドキュメント](https://github.com/purescript-contrib/purescript-argonaut#documentation)があるので、本書では基本的な用法だけを押さえます。

返る型を`Json`として定義するようにして、代わりとなる外部インポートをつくるとこうなります。

```hs
foreign import cumulativeSumsJson :: Array Int -> Json
foreign import addComplexJson :: Complex -> Complex -> Json
```

単純に既存の壊れた関数を指している点に注意します。

```js
export const cumulativeSumsJson = cumulativeSumsBroken
export const addComplexJson = addComplexBroken
```

そして返された`Json`の値をデコードする梱包を書きます。

```hs
{{#include ../exercises/chapter10/test/Examples.purs:cumulativeSumsDecoded}}

{{#include ../exercises/chapter10/test/Examples.purs:addComplexDecoded}}
```

そうすると返る型へのデコードが成功しなかったどんな値も`Left`の`String`なエラーとして表れます。

```text
$ spago repl

> import Test.Examples

> cumulativeSumsDecoded [1, 2, 3]
(Left "Couldn't decode Array (Failed at index 3): Value is not a Number")

> addComplexDecoded { real: 1.0, imag: 2.0 } { real: 3.0, imag: 4.0 }
(Left "JSON was missing expected field: imag")
```

正常に動作するバージョンで呼び出すと`Right`の値が返ります。

次のREPLブロックを走らせる前に、正常に動作するバージョンを指すように、`test/Examples.js`へ以下の変更を加えて、手元で試してみましょう。

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

JSONを使うのは、`Map`や`Set`のようなその他の構造的な型をFFI越しに渡す、最も簡単な方法でもあります。
JSONは真偽値、数値、文字列、配列、そして他のJSONの値からなるオブジェクトのみから構成されるため、JSONでは直接`Map`や`Set`を書けません。
しかしこれらの構造を配列としては表現でき（キーとバリューもまたJSONで表現されているとします）、それから`Map`や`Set`に復元できるのです。

以下は`String`のキーと`Int`のバリューからなる`Map`を変更する外部関数シグネチャと、それに伴うJSONのエンコードとデコードを扱う梱包関数の例です。

```hs
{{#include ../exercises/chapter10/test/Examples.purs:mapSetFooJson}}
```

関数合成の絶好の用例になっていますね。
以下の代案は両方とも上のものと等価です。

```hs
mapSetFoo :: Map String Int -> Either JsonDecodeError (Map String Int)
mapSetFoo = decodeJson <<< mapSetFooJson <<< encodeJson

mapSetFoo :: Map String Int -> Either JsonDecodeError (Map String Int)
mapSetFoo = encodeJson >>> mapSetFooJson >>> decodeJson
```

以下はJavaScriptでの実装です。
なお、`Array.from`の工程は、JavaScriptの`Map`をJSONに親和性のある形式に変換し、デコードでPureScriptの`Map`に変換し直すために必須です。

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

1. （普通）`Map`中の全てのバリューの`Set`を返すJavaScriptの関数とPureScriptの梱包`valuesOfMap :: Map
   String Int -> Either JsonDecodeError (Set Int)`を書いてください。
1. （簡単）より広い種類のマップに関して動作するよう、前のJavaScriptの関数の新しい梱包を書いてください。
   シグネチャは`valuesOfMapGeneric :: forall k v. Map k v -> Either
   JsonDecodeError (Set v)`です。
   なお、`k`と`v`に幾つかの型クラス制約を加える必要があるでしょう。
   コンパイラが導いてくれます。
1. (Medium) Rewrite the earlier `quadraticRoots` function as
   `quadraticRootsSet` that returns the `Complex` roots as a `Set` via JSON
   (instead of as a `Pair`).
1. (Difficult) Rewrite the earlier `quadraticRoots` function as `quadraticRootsSafe` that uses JSON to pass the `Pair` of `Complex` roots over FFI. Don't use the `Pair` constructor in JavaScript, but instead, just return the pair in a decoder-compatible format.
_Hint_: You'll need to write a `DecodeJson` instance for `Pair`. Consult the [argonaut docs](https://github.com/purescript-contrib/purescript-argonaut-codecs/tree/main/docs#writing-new-instances) for instruction on writing your own decode instance. Their [decodeJsonTuple](https://github.com/purescript-contrib/purescript-argonaut-codecs/blob/master/src/Data/Argonaut/Decode/Class.purs) instance may also be a helpful reference.  Note that you'll need a `newtype` wrapper for `Pair` to avoid creating an "orphan instance".
1. (Medium) Write a `parseAndDecodeArray2D :: String -> Either String (Array (Array Int))` function to parse and decode a JSON string containing a 2D array, such as `"[[1, 2, 3], [4, 5], [6]]"`. _Hint_: You'll need to use `jsonParser` to convert the `String` into `Json` before decoding.
1. (Medium) The following data type represents a binary tree with values at the leaves:

     ```haskell
     data Tree a
       = Leaf a
       | Branch (Tree a) (Tree a)
     ```

     汎化された`EncodeJson`及び`DecodeJson`インスタンスを`Tree`型用に導出してください。
     このやり方についての説明は[argonautのドキュメント](https://github.com/purescript-contrib/purescript-argonaut-codecs/tree/main/docs#generics)をあたってください。
     なお、この演習の単体試験を有効にするには、汎化された`Show`及び`Eq`インスタンスも必要になります。
     しかしJSONのインスタンスと格闘したあとでは、これらの実装は直感的に進むことでしょう。
1. （難しい）以下の`data`型は整数か文字列かによってJSONで異なって表現されます。

     ```haskell
     data IntOrString
       = IntOrString_Int Int
       | IntOrString_String String
     ```

     この挙動を実装する`IntOrString`データ型に、`EncodeJson`及び`DecodeJson`インスタンスを書いてください。
     *手掛かり*：`Control.Alt`の`alt`演算子が役立つかもしれません。

## 住所録

In this section, we will apply our newly-acquired FFI and JSON knowledge to
build on our address book example from Chapter 8. We will add the following
features:

- 保存ボタンをフォームの一番下に配置し、クリックしたときにフォームの状態をJSONに直列化してローカルストレージに保存します。
- ページの再読み込み時にローカルストレージからJSON文書を自動的に取得します。
  フォームのフィールドにはこの文書の内容を入れます。
- フォームの状態を保存したり読み込んだりするのに問題があればポップアップの警告を出します。

`Effect.Storage`モジュールに以下のWebストレージAPIのためのFFIの梱包をつくることから始めていきます。

- `setItem`はキーと値（両方とも文字列）を受け取り、指定されたキーでローカルストレージに値を格納する計算を返します。
- `getItem`はキーを取り、ローカルストレージから関連付けられたバリューの取得を試みます。
  しかし`window.localStorage`の`getItem`メソッドは`null`を返しうるので、返る型は`String`ではなく`Json`です。

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

なお、この段階でコンパイルしようとすると以下のエラーに遭遇します。

```text
  No type class instance was found for
    Data.Argonaut.Encode.Class.EncodeJson PhoneType
```

This is because `PhoneType` in the `Person` record needs an `EncodeJson`
instance. We'll also derive a generic encode instance and a decode instance
while we're at it. More information on how this works is available in the
argonaut docs:

```hs
{{#include ../exercises/chapter10/src/Data/AddressBook.purs:import}}

{{#include ../exercises/chapter10/src/Data/AddressBook.purs:PhoneType_generic}}
```

これで`person`をローカルストレージに保存できます。
しかしデータを取得できない限りあまり便利ではありません。
次はそれに取り掛かりましょう。

ローカルストレージから「person」文字列で取得することから始めましょう。

```hs
item <- getItem "person"
```

Then we'll create a helper function to convert the string from local storage
to our `Person` record. Note that this string in storage may be `null`, so
we represent it as a foreign `Json` until it is successfully decoded as a
`String`. There are a number of other conversion steps along the way – each
of which returns an `Either` value, so it makes sense to organize these
together in a `do` block.

```hs
processItem :: Json -> Either String Person
processItem item = do
  jsonString <- decodeJson item
  j          <- jsonParser jsonString
  decodeJson j
```

Then we inspect this result to see if it succeeded. If it fails, we'll log
the errors and use our default `examplePerson`, otherwise, we'll use the
person retrieved from local storage.

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

そして状態フックで使うために別の箇所で拾い上げます。

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

Only the first error should ever occur during the normal operation of this
app. You can trigger the other errors by opening your web browser's dev
tools, editing the saved "person" string in local storage, and refreshing
the page. How you modify the JSON string determines which error is
triggered. See if you can trigger each of them.

That covers local storage. Next, we'll implement the `alert` action, similar
to the `log` action from the `Effect.Console` module. The only difference is
that the `alert` action uses the `window.alert` method, whereas the `log`
action uses the `console.log` method. As such, `alert` can only be used in
environments where `window.alert` is defined, such as a web browser.

```hs
foreign import alert :: String -> Effect Unit
```

```js
export const alert = msg => () =>
  window.alert(msg);
```

この警告が次の何れかの場合に現れるようにしたいです。

- 利用者が検証エラーを含むフォームを保存しようと試みている。
- 状態がローカルストレージから取得できない。

以上は単に以下の行で`log`を`alert`に置き換えるだけで達成できます。

```hs
Left errs -> alert $ "There are " <> show (length errs) <> " validation errors."

alert $ "Error: " <> err <> ". Loading examplePerson"
```

## 演習

 1. （普通）`localStorage`オブジェクトの `removeItem`メソッドの梱包を書き、
    `Effect.Storage`モジュールに外部関数を追加してください
 1. （普通）「リセット」ボタンを追加してください。
    このボタンをクリックすると新しく作った`removeItem`関数を呼び出してローカルストレージから「人物」の項目を削除します。
 1. （簡単）JavaScriptの `Window`オブジェクトの `confirm`メソッドの梱包を書き、
    `Effect.Alert`モジュールにその外部関数を追加してください。
 1. （普通）利用者が「リセット」ボタンをクリックしたときにこの`confirm`関数を呼び出し、本当にアドレス帳を白紙にしたいか尋ねるようにしてください。

## まとめ

In this chapter, we've learned how to work with foreign JavaScript code from
PureScript, and we've seen the issues involved with writing trustworthy code
using the FFI:

- 外部関数が正しい表現を持っていることを確かめる重要性を見てきました。
- We learned how to deal with corner cases like null values and other types
  of JavaScript data by using foreign types or the `Json` data type.
- 安全にJSONデータを直列化・直列化復元する方法を見ました。

For more examples, the `purescript`, `purescript-contrib`, and
`purescript-node` GitHub organizations provide plenty of examples of
libraries that use the FFI. In the remaining chapters, we will see some of
these libraries put to use to solve real-world problems in a type-safe way.

## 補遺

### JavaScriptからPureScriptを呼び出す

少なくとも単純な型を持つ関数については、JavaScriptからPureScript関数を呼び出すのはとても簡単です。

例として以下のような簡単なモジュールを見てみましょう。

```haskell
module Test where

gcd :: Int -> Int -> Int
gcd 0 m = m
gcd n 0 = n
gcd n m
  | n > m     = gcd (n - m) m
  | otherwise = gcd (m – n) n
```

この関数は、減算を繰り返すことによって2つの数の最大公約数を見つけます。
PureScriptでパターン照合と再帰を使用してこの関数を定義するのは簡単で、実装する開発者は型検証器の恩恵を受けることができます。
そういうわけで関数を定義するのにPureScriptを使いたくなるかもしれない良い例となっていますが、JavaScriptからそれを呼び出すためには条件があります。

この関数をJavaScriptから呼び出す方法を理解する上で重要なのは、PureScriptの関数は常に引数が1つのJavaScript関数へと変換され、引数へは次のように1つずつ適用していかなければならないということです。

```javascript
import Test from 'Test.js';
Test.gcd(15)(20);
```

Here, I assume the code was compiled with `spago build`, which compiles
PureScript modules to ES modules. For that reason, I could reference the
`gcd` function on the `Test` object, after importing the `Test` module using
`import`.

`spago bundle-app`や`spago
bundle-module`コマンドを使って生成されたJavaScriptを単一のファイルにまとめることもできます。
詳細な情報については[ドキュメント](https://github.com/purescript/spago#bundle-a-project-into-a-single-js-file)をあたってください。

### 名前の生成を理解する

PureScript aims to preserve names during code generation as much as
possible. In particular, most identifiers that are neither PureScript nor
JavaScript keywords can be expected to be preserved, at least for names of
top-level declarations.

識別子としてJavaScriptのキーワードを使う場合は、名前は2重のドル記号でエスケープされます。
例えば次のPureScriptコードを考えてみます。

```haskell
null = []
```

Generates the following JavaScript:

```javascript
var $$null = [];
```

また、識別子に特殊文字を使用したい場合は、単一のドル記号を使用してエスケープされます。
例えばこのPureScriptコードを考えます。

```haskell
example' = 100
```

Generates the following JavaScript:

```javascript
var example$prime = 100;
```

Where compiled PureScript code is intended to be called from JavaScript, it
is recommended that identifiers only use alphanumeric characters and avoid
JavaScript keywords. If user-defined operators are provided for use in
PureScript code, it is good practice to provide an alternative function with
an alphanumeric name for use in JavaScript.

### 実行時のデータ表現

Types allow us to reason at compile-time that our programs are "correct" in
some sense – that is, they will not break at runtime. But what does that
mean? In PureScript, it means that the type of an expression should be
compatible with its representation at runtime.

そのため、PureScriptとJavaScriptコードを一緒に効率的に使用できるように、実行時のデータ表現について理解することが重要です。
これはつまり、与えられた任意のPureScriptの式について、その値が実行時にどのように評価されるかという挙動を理解できるべきだということです。

幸いにもPureScriptの式はとりわけ実行時に単純な表現を持っています。
型を考慮すれば式の実行時のデータ表現を把握することが常に可能です。

単純な型については、対応関係はほとんど自明です。
例えば式が型 `Boolean`を持っていれば、実行時のその値 `v`は `typeof v === 'boolean'`を満たします。
つまり、型 `Boolean`の式は `true`もしくは `false`のどちらか一方の（JavaScriptの）値へと評価されます。
特に`null`や `undefined`に評価される型`Boolean`なPureScriptの式はありません。

A similar law holds for expressions of type `Int`, `Number`, and `String` –
expressions of type `Int` or `Number` evaluate to non-null JavaScript
numbers, and expressions of type `String` evaluate to non-null JavaScript
strings. Expressions of type `Int` will evaluate to integers at runtime,
even though they cannot be distinguished from values of type `Number` by
using `typeof`.

What about `Unit`? Well, since `Unit` has only one inhabitant (`unit`) and
its value is not observable, it doesn't matter what it's represented with at
runtime. Old code tends to represent it using `{}`. Newer code, however,
tends to use `undefined`. So, although it doesn't matter what you use to
represent `Unit`, it is recommended to use `undefined` (not returning
anything from a function also returns `undefined`).

もっと複雑な型についてはどうでしょうか。

As we have already seen, PureScript functions correspond to JavaScript functions of a single argument. More precisely, if an expression `f` has type `a -> b` for some types `a` and `b`, and an expression `x` evaluates to a value with the correct runtime representation for type `a`, then `f` evaluates to a JavaScript function, which, when applied to the result of evaluating `x`, has the correct runtime representation for type `b`. As a simple example, an expression of type `String -> String` evaluates to a function that takes non-null JavaScript strings to non-null JavaScript strings.

As you might expect, PureScript's arrays correspond to JavaScript
arrays. But remember – PureScript arrays are homogeneous, so every element
has the same type. Concretely, if a PureScript expression `e` has type
`Array a` for some type `a`, then `e` evaluates to a (non-null) JavaScript
array, all of whose elements have the correct runtime representation for
type `a`.

We've already seen that PureScript's records evaluate to JavaScript
objects. As for functions and arrays, we can reason about the runtime
representation of data in a record's fields by considering the types
associated with its labels. Of course, the fields of a record are not
required to be of the same type.

### ADTの表現

For every constructor of an algebraic data type, the PureScript compiler
creates a new JavaScript object type by defining a function. Its
constructors correspond to functions that create new JavaScript objects
based on those prototypes.

例えば次のような単純なADTを考えてみましょう。

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

ここで2つのJavaScriptオブジェクト型 `Zero`と `One`を見てください。
JavaScriptのキーワード`new`を使用すると、それぞれの型の値を作成できます。
引数を持つ構築子については、コンパイラは `value0`、 `value1`などという名前のフィールドに、対応するデータを格納します。

PureScriptコンパイラは補助関数も生成します。
引数のない構築子については、コンパイラは構築子が使われるたびに `new`演算子を使うのではなく、データを再利用できるように
`value`プロパティを生成します。
1つ以上の引数を持つ構築子では、コンパイラは適切な表現を持つ引数を取り適切な構築子を適用する `create`関数を生成します。

What about constructors with more than one argument? In that case, the
PureScript compiler also creates a new object type, and a helper
function. This time, however, the helper function is a curried function of
two arguments. For example, this algebraic data type:

```haskell
data Two a b = Two a b
```

Generates this JavaScript code:

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

Here, values of the object type `Two` can be created using the `new` keyword
or by using the `Two.create` function.

The case of newtypes is slightly different. Recall that a newtype is like an
algebraic data type, restricted to having a single constructor taking a
single argument. In this case, the runtime representation of the newtype is
the same as its argument type.

For example, this newtype represents telephone numbers is represented as a
JavaScript string at runtime:

```haskell
newtype PhoneNumber = PhoneNumber String
```

This is useful for designing libraries since newtypes provide an additional
layer of type safety without the runtime overhead of another function call.

### 量化された型の表現

量化された型（多相型）の式は、実行時は制限された表現になっています。
実際、所与の量化された型を持つ式がより少なくなりますが、それによりかなり効率的に推論できるのです。

例えば、次の多相型を考えてみます。

```haskell
forall a. a -> a
```

この型を持っている関数にはどんなものがあるでしょうか。
実は少なくとも1つ、この型を持つ関数が存在します。

```haskell
identity :: forall a. a -> a
identity a = a
```

> なお、`Prelude`に定義された実際の[`identity`](https://pursuit.purescript.org/packages/purescript-prelude/docs/Control.Category#v:identity)関数は僅かに違った型を持ちます。

実のところ、`identity`関数はこの型の*唯一の*（全）関数です。
これは確かに間違いなさそうに思えますが（この型を持った `id`とは明らかに異なる式を書こうとしてみてください）、確かめるにはどうしたらいいでしょうか。
型の実行時表現を考えることによって確かめられます。

量化された型 `forall a. t`の実行時表現はどうなっているのでしょうか。さて、この型の実行時表現を持つ任意の式は、型 `a`をどのように選んでも型 `t`の適切な実行時表現を持っていなければなりません。上の例では、型 `forall a. a -> a`の関数は、 `String -> String`、 `Number -> Number`、 `Array Boolean -> Array Boolean`などといった型について、適切な実行時表現を持っていなければなりません。 これらは、文字列から文字列、数から数の関数でなくてはなりません。

But that is not enough – the runtime representation of a quantified type is
more strict than this. We require any expression to be _parametrically
polymorphic_ – that is, it cannot use any information about the type of its
argument in its implementation. This additional condition prevents
problematic implementations such as the following JavaScript function from
inhabiting a polymorphic type:

```javascript
function invalid(a) {
    if (typeof a === 'string') {
        return "Argument was a string.";
    } else {
        return a;
    }
}
```

Certainly, this function takes strings to strings, numbers to numbers, etc. But it does not meet the additional condition, since it inspects the (runtime) type of its argument, so this function would not be a valid inhabitant of the type `forall a. a -> a`.

Without being able to inspect the runtime type of our function argument, our only option is to return the argument unchanged. So `identity` is indeed the only inhabitant of the type `forall a. a -> a`.

A full discussion of _parametric polymorphism_ and _parametricity_ is beyond
the scope of this book. Note, however, that since PureScript's types are
_erased_ at runtime, a polymorphic function in PureScript _cannot_ inspect
the runtime representation of its arguments (without using the FFI), so this
representation of polymorphic data is appropriate.

### 制約のある型の表現

Functions with a type class constraint have an interesting representation at
runtime. Because the function's behavior might depend on the type class
instance chosen by the compiler, the function is given an additional
argument, called a _type class dictionary_, which contains the
implementation of the type class functions provided by the chosen instance.

For example, here is a simple PureScript function with a constrained type
that uses the `Show` type class:

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

### 演習

 1. （簡単）これらの型の実行時の表現は何でしょうか。

     ```haskell
     forall a. a
     forall a. a -> a -> a
     forall a. Ord a => Array a -> Boolean
     ```

     これらの型を持つ式についてわかることは何でしょうか。
1. （普通）`spago build`を使ってコンパイルし、NodeJSの `import`機能を使ってモジュールをインポートすることで、JavaScriptから `arrays`ライブラリの関数を使ってみてください。
   *手掛かり*：生成されたCommonJSモジュールがNodeJSモジュールのパスで使用できるように、出力パスを設定する必要があります。

### 副作用の表現

The `Effect` monad is also defined as a foreign type. Its runtime
representation is quite simple – an expression of type `Effect a` should
evaluate to a JavaScript function of **no arguments**, which performs any
side-effects and returns a value with the correct runtime representation for
type `a`.

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

Notice that the `random` function is represented at runtime as a function of
no arguments. It performs the side effect of generating a random number,
returns it, and the return value matches the runtime representation of the
`Number` type: it is a non-null JavaScript number.

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

実行時の `log`の表現は、単一の引数のJavaScript関数で、引数なしの関数を返します。
内側の関数はコンソールに文言を書き込むという副作用を実行します。

`Effect a`型の式は、通常のJavaScriptのメソッドのようにJavaScriptから呼び出すことができます。例えば、この
`main`関数は何らかの型`a`について`Effect a`という型でなければならないので、次のように実行できます。

```javascript
import { main } from 'Main'

main();
```

When using `spago bundle-app --to` or `spago run`, this call to `main` is
generated automatically whenever the `Main` module is defined.
