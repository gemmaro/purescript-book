# 非同期作用

## この章の目標

This chapter focuses on the `Aff` monad, which is similar to the `Effect`
monad, but represents _asynchronous_ side-effects. We'll demonstrate
examples of asynchronously interacting with the filesystem and making HTTP
requests. We'll also cover managing sequential and parallel execution of
asynchronous effects.

## プロジェクトの準備

この章で導入する新しいPureScriptライブラリは以下です。

- `aff` - `Aff`モナドを定義します。
- `node-fs-aff` - `Aff`を使った非同期のファイルシステム操作。
- `affjax` - AJAXと`Aff`を使ったHTTPリクエスト。
- `parallel` - `Aff`の並列実行。

When running outside of the browser (such as in our Node.js environment),
the `affjax` library requires the `xhr2` NPM module, which is listed as a
dependency in the `package.json` of this chapter. Install that by running:

```shell
$ npm install
```

## 非同期なJavaScript

JavaScriptで非同期なコードに取り組む上で便利な手段は[`async`と`await`](https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Asynchronous/Async_await)です。
[非同期なJavaScriptに関するこの記事](https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Asynchronous/Introducing)を見るとより背景情報がわかります。

以下は、この技法を使ってあるファイルの内容を別のファイルに複製する例です。

```js
import { promises as fsPromises } from 'fs'

async function copyFile(file1, file2) {
  let data = await fsPromises.readFile(file1, { encoding: 'utf-8' });
  fsPromises.writeFile(file2, data, { encoding: 'utf-8' });
}

copyFile('file1.txt', 'file2.txt')
.catch(e => {
  console.log('There was a problem with copyFile: ' + e.message);
});
```

It is also possible to use callbacks or synchronous functions, but those are
less desirable because:

- コールバックは過剰な入れ子に繋がります。これは「コールバック地獄」や「悪夢のピラミッド」として知られています。
- 同期関数はアプリ中の他のコードの実行を堰き止めてしまいます。

## 非同期なPureScript

PureScriptでの`Aff`モナドはJavaScriptの`async`/`await`構文に似た人間工学を供します。以下は前と同じ`copyFile`の例ですが、`Aff`を使ってPureScriptで書き換えられています。

```hs
{{#include ../exercises/chapter9/test/Copy.purs:copyFile}}
```

なお、`main`は`Effect
Unit`でなければならないので、`launchAff_`を使って`Aff`から`Effect`へと変換せねばなりません。

It is also possible to re-write the above snippet using callbacks or
synchronous functions (for example, with `Node.FS.Async` and `Node.FS.Sync`,
respectively), but those share the same downsides as discussed earlier with
JavaScript, so that coding style is not recommended.

The syntax for working with `Aff` is very similar to working with
`Effect`. They are both monads and can therefore be written with do
notation.

例えば`readTextFile`のシグネチャを見れば、これがファイルの内容を`String`とし、`Aff`に包んで返していることがわかります。

```hs
readTextFile :: Encoding -> FilePath -> Aff String
```

do記法中では束縛矢印 (`<-`) で返却された文字列を「開封」できます。

```hs
my_data <- readTextFile UTF8 file1
```

それから`writeTextFile`に文字列引数として渡します。

```hs
writeTextFile :: Encoding -> FilePath -> String -> Aff Unit
```

上の例で他に目を引く`Aff`固有の特徴は`attempt`のみです。これは`Aff`のコードの実行中に遭遇したエラーや例外を捕捉して`Either`内に保管するものです。

```hs
attempt :: forall a. Aff a -> Aff (Either Error a)
```

読者ならきっと、前の章から概念の知識を引き出し、その知識と上の`copyFile`の例で学んだ新しい`Aff`パターンを組み合わせることで、以下の演習に挑戦できるでしょう。

## 演習

 1. (Easy) Write a `concatenateFiles` function that concatenates two text
    files.

 1. (Medium) Write a function `concatenateMany` to concatenate multiple text
    files, given an array of input and output file names. _Hint_: use
    `traverse`.

 1. （普通）ファイル中の文字数を返すか、エラーがあればそれを返す関数`countCharacters :: FilePath -> Aff
    (Either Error Int)`を書いてください。

## 更なるAffの資料

If you haven't already looked at the [official Aff
guide](https://pursuit.purescript.org/packages/purescript-aff/), skim
through that now. It's not a direct prerequisite for completing the
remaining exercises in this chapter, but you may find it helpful to lookup
some functions on Pursuit.

以下の補足資料についてもあたってみるとよいでしょう。しかし繰り返しになりますがこの章の演習はこれらの内容に依りません。

- [DrewのAffに関する投稿](https://blog.drewolson.org/asynchronous-purescript)
- [更なるAffの説明と例](https://github.com/JordanMartinez/purescript-jordans-reference/tree/latestRelease/21-Hello-World/02-Effect-and-Aff/src/03-Aff)

## HTTPクライアント

The `affjax` library offers a convenient way to make asynchronous AJAX HTTP
requests with `Aff`. Depending on what environment you are targeting, you
need to use either the
[purescript-affjax-web](https://github.com/purescript-contrib/purescript-affjax-web)
or the
[purescript-affjax-node](https://github.com/purescript-contrib/purescript-affjax-node)
library.

In the rest of this chapter, we will be targeting node and thus using
`purescript-affjax-node`.  Consult the [Affjax
docs](https://pursuit.purescript.org/packages/purescript-affjax) for more
usage information. Here is an example that makes HTTP GET requests at a
provided URL and returns the response body or an error message:

```hs
{{#include ../exercises/chapter9/test/HTTP.purs:getUrl}}
```

これをREPLで呼び出す際は、`launchAff_`で`Aff`からREPLに互換性のある`Effect`へと変換する必要があります。

```shell
$ spago repl

> :pa
… import Prelude
… import Effect.Aff (launchAff_)
… import Effect.Class.Console (log)
… import Test.HTTP (getUrl)
…
… launchAff_ do
…   str <- getUrl "https://reqres.in/api/users/1"
…   log str
…
unit
{"data":{"id":1,"email":"george.bluth@reqres.in","first_name":"George","last_name":"Bluth", ...}}
```

## 演習

1. （簡単）与えられたURLにHTTPの`GET`を要求し、応答本文をファイルに書き込む関数`writeGet`を書いてください。

## 並列計算

`Aff`モナドとdo記法を使って、非同期計算を順番に実行されるように合成する方法を見てきました。
非同期計算を*並列にも*合成できたら便利でしょう。
`Aff`があれば2つの計算を次々に開始するだけで並列に計算できます。

The `parallel` package defines a type class `Parallel` for monads like
`Aff`, which support parallel execution. When we met applicative functors
earlier in the book, we observed how applicative functors can be useful for
combining parallel computations. In fact, an instance for `Parallel` defines
a correspondence between a monad `m` (such as `Aff`) and an applicative
functor `f` that can be used to combine computations in parallel:

```hs
class (Monad m, Applicative f) <= Parallel f m | m -> f, f -> m where
  sequential :: forall a. f a -> m a
  parallel :: forall a. m a -> f a
```

このクラスは2つの関数を定義しています。

- `parallel`：モナド`m`中の計算を取り、アプリカティブ関手`f`中の計算に変えます。
- `sequential`：反対方向に変換します。

The `aff` library provides a `Parallel` instance for the `Aff` monad. It
uses mutable references to combine `Aff` actions in parallel by keeping
track of which of the two continuations has been called. When both results
have been returned, we can compute the final result and pass it to the main
continuation.

アプリカティブ関手では任意個の引数の関数の持ち上げができるので、このアプリカティブコンビネータを使ってより多くの計算を並列に実行できます。
`traverse`や`sequence`といった、アプリカティブ関手を扱う全ての標準ライブラリ関数から恩恵を受けることもできます。

We can also combine parallel computations with sequential portions of code
by using applicative combinators in a do notation block, or vice versa,
using `parallel` and `sequential` to change type constructors where
appropriate.

直列実行と並列実行の間の違いを実演するために、100個の10ミリ秒の遅延からなる配列をつくり、それからその遅延を両方の手法で実行します。REPLで試すと`seqDelay`が`parDelay`より遥かに遅いことに気付くでしょう。並列実行が`sequence_`を`parSequence_`で置き換えるだけで有効になるところに注目です。

```hs
{{#include ../exercises/chapter9/test/ParallelDelay.purs:delays}}
```

```shell
$ spago repl

> import Test.ParallelDelay

> seqDelay -- This is slow
unit

> parDelay -- This is fast
unit
```

以下は並列で複数回HTTP要求する、より現実味のある例です。
`getUrl`関数を再利用して2人の利用者から並列で情報を取得します。
この場合では`parTarverse`（`traverse`の並列版）が使われていますね。
この例は代わりに`traverse`でも問題なく動きますがより遅くなるでしょう。

```hs
{{#include ../exercises/chapter9/test/ParallelFetch.purs:fetchPar}}
```

```shell
$ spago repl

> import Test.ParallelFetch

> fetchPar
unit
["{\"data\":{\"id\":1,\"email\":\"george.bluth@reqres.in\", ... }"
,"{\"data\":{\"id\":2,\"email\":\"janet.weaver@reqres.in\", ... }"
]
```

利用できる並列関数の完全な一覧は[Pursuitの`parallel`のドキュメント](https://pursuit.purescript.org/packages/purescript-parallel/docs/Control.Parallel)にあります。[parallelのaffのドキュメントの節](https://github.com/purescript-contrib/purescript-aff#parallel-execution)にもより多くの例が含まれています。

## 演習

1. (Easy) Write a `concatenateManyParallel` function with the same signature
   as the earlier `concatenateMany` function but reads all input files in
   parallel.

1. （普通）与えられたURLへHTTP `GET`を要求して以下の何れかを返す`getWithTimeout :: Number -> String
   -> Aff (Maybe String)`関数を書いてください。
    - `Nothing`: 要求してから与えられた時間制限（ミリ秒単位）より長く掛かった場合。
    - 文字列の応答：時間制限を越える前に要求が成功した場合。

1. (Difficult) Write a `recurseFiles` function that takes a "root" file and
   returns an array of all paths listed in that file (and listed in the
   listed files too). Read listed files in parallel. Paths are relative to
   the directory of the file they appear in. _Hint:_ The `node-path` module
   has some helpful functions for negotiating directories.

例えば次のような`root.txt`ファイルから始まるとします。

```shell
$ cat root.txt
a.txt
b/a.txt
c/a/a.txt

$ cat a.txt
b/b.txt

$ cat b/b.txt
c/a.txt

$ cat b/c/a.txt

$ cat b/a.txt

$ cat c/a/a.txt
```

期待される出力は次の通り。

```hs
["root.txt","a.txt","b/a.txt","b/b.txt","b/c/a.txt","c/a/a.txt"]
```

## まとめ

In this chapter, we covered asynchronous effects and learned how to:

- `aff`ライブラリを使って`Aff`モナド中で非同期コードを走らせる。
- `affjax`ライブラリを使って非同期にHTTPリクエストする。
- `parallel`ライブラリを使って並列に非同期コードを走らせる。
