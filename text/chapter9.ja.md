# 非同期作用

## この章の目標

この章では`Aff`モナドに集中します。
これは`Effect`モナドに似たものですが、*非同期*な副作用を表現するものです。
ファイルシステムとやりとりしてHTTPリクエストを作る、非同期な例を実演していきます。
また非同期作用の直列ないし並列の実行の管理方法も押さえます。

## プロジェクトの準備

この章で導入する新しいPureScriptライブラリは以下です。

- `aff` - `Aff`モナドを定義します。
- `node-fs-aff` - `Aff`を使った非同期のファイルシステム操作。
- `affjax` - AJAXと`Aff`を使ったHTTPリクエスト。
- `parallel` - `Aff`の並列実行。

When running outside of the browser (such as in our Node.js environment),
the `affjax` library requires the `xhr2` NPM module, which is listed as
dependency in the `package.json` of this chapter. Install that by running:

```shell
$ npm install
```

## 非同期なJavaScript

JavaScriptで非同期なコードに取り組む上で便利な手段は[`async`と`await`](https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Asynchronous/Async_await)です。
[非同期なJavaScriptに関するこの記事](https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Asynchronous/Introducing)を見るとより背景情報がわかります。

以下はこの技法を使ってあるファイルの内容を別のファイルに複製する例です。

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

コールバックや同期関数を使うことも可能ですが、以下の理由から望ましくあ
りません。

- コールバックは過剰な入れ子に繋がります。これは「コールバック地獄」や
  「悪夢のピラミッド」として知られています。
- 同期関数はアプリ中の他のコードの実行を堰き止めてしまいます。

## 非同期なPureScript

PureScriptでに`Aff`モナドはJavaScriptの`async`/`await`構文に似た人間工学を供します。
以下は前と同じ`copyFile`の例ですが、`Aff`を使ってPureScriptで書き換えられています。

```hs
{{#include ../exercises/chapter9/test/Copy.purs:copyFile}}
```

上のコード片をコールバックや同期関数を使って書き換えることも可能ですが
（例えば`Node.FS.Async`や`Node.FS.Sync`をそれぞれ使います）、
JavaScriptで前にお話ししたように同じ短所がここでも通用するため、
それらのコーディング形式は推奨されません。

`Aff`を扱う文法は`Effect`を扱うものと大変似ています。
どちらもモナドですし、したがってdo記法で書くことができます。

例えば`readTextFile`のシグネチャを見れば、
これがファイルの内容を`String`とし、`Aff`に包んで返していることがわかります。
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

上の例で他に目を引く`Aff`固有の特徴は`attempt`のみです。
これは`Aff`のコードの実行中に遭遇したエラーや例外を補足して`Either`内に保管するものです。
```hs
attempt :: forall a. Aff a -> Aff (Either Error a)
```

読者ならきっと、前の章から概念の知識を引き出し、
その知識と上の`copyFile`の例で学んだ新しい`Aff`パターンを結合することで、
以下の演習に挑戦することができるでしょう。

## 演習

 1. （簡単）2つのテキストフ​​ァイルを連結する関数`concatenateFiles`を書いてください。

 1. （普通）入力ファイル名の配列と出力ファイル名が与えられたとき、
    複数のテキストファイルを連結する関数 `concatenateMany`を書いてください。
    **ヒント**：`traverse`を使ってください。

 1. （普通）ファイル中の文字数を返すかエラーがあればそれを返す関数`countCharacters :: FilePath -> Aff
    (Either Error Int)`を書いてください。

## 更なるAffの資料

もしまだ[公式のAffガイド](https://pursuit.purescript.org/packages/purescript-aff/)を見ていなければ、今ざっと目を通してください。
この章の残りの演習を完了するための事前要件ではありませんが、
Pursuitで何らかの関数を見付けだす助けになるかもしれません。

以下の補助的な資料にあたることもご自由にどうぞ。
でも繰り返しますがこの章の演習はこれらに依存していません。

* [DrewによるAffの投稿](https://blog.drewolson.org/asynchronous-purescript)
* [更なるAffの説明と例][1]

[1]:
https://github.com/JordanMartinez/purescript-jordans-reference/tree/latestRelease/21-Hello-World/02-Effect-and-Aff/src/03-Aff

## HTTPクライアント

`affjax`ライブラリは`Aff`で非同期AJAX HTTP要求を作る便利な手段を提供します。
対象としている環境が何であるかによって、[purescript-affjax-web](https://github.com/purescript-contrib/purescript-affjax-web)または[purescript-affjax-node](https://github.com/purescript-contrib/purescript-affjax-node)のどちらかのライブラリを使う必要があります。
この章の以降ではNodeを対象としていくので、`purescript-affjax-node`を使います。
より詳しい使用上の情報は[affjaxのドキュメント](https://pursuit.purescript.org/packages/purescript-affjax)にあたってください。
以下は与えられたURLに向けたHTTPのGET要求をし、応答本文ないしエラー文言を返す例です。

```hs
{{#include ../exercises/chapter9/test/HTTP.purs:getUrl}}
```

これをREPLで呼び出す際は、`launchAff_`を`Aff`からREPLに互換性のある`Effect`へと変換する必要があります。

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

1. （簡単）HTTPの`GET`要求を与えられたURLに行い、応答本文をファイルに書き込む関数`writeGet`を書いてください。

## 並列計算

`Aff`モナドとdo記法を使って、非同期計算を順番に実行されるように合成する方法を見てきました。
非同期計算を**並列に**合成することもできたら便利でしょう。
`Aff`があれば2つの計算を次々に開始するだけで並列に計算できます。

`parallel`パッケージは`Aff`のようなモナドのための型クラス`Parallel`を定義しており、
並列実行に対応しています。
以前に本書でアプリカティブ関手に出会ったとき、
並列計算を合成するときにアプリカティブ関手がどのように便利なのかを観察しました。
実は`Parallel`のインスタンスは、（`Aff`のような）モナド`m`と、
並列に計算を合成するために使われるアプリカティブ関手`f`との対応関係を定義しているのです。

```hs
class (Monad m, Applicative f) <= Parallel f m | m -> f, f -> m where
  sequential :: forall a. f a -> m a
  parallel :: forall a. m a -> f a
```

このクラスは2つの関数を定義しています。

- `parallel`：モナド `m`中の計算を取り、アプリカティブ関手`f`中の計算に
  変えます。
- `sequential`：反対方向の変換を行います。

`aff`ライブラリは `Aff`モナドの `Parallel`インスタンスを提供します。
これは、2つの継続 (continuation) のどちらが呼び出されたかを把握することによって、
変更可能な参照を使用して並列に `Aff`アクションを組み合わせます。
両方の結果が返されたら、最終結果を計算してメインの継続に渡すことができます。

アプリカティブ関手では任意個引数の関数の持ち上げができるので、
このアプリカティブコンビネータを使ってより多くの計算を並列に実行することができます。
`traverse`や`sequence`といった、アプリカティブ関手を扱う
すべての標準ライブラリ関数から恩恵を受けることもできます。

必要に応じて `parralel`と`sequential`を使って型構築子を変更することで、
do記法ブロック中でアプリカティブコンビネータを使い、
直列的なコードの一部で並列計算を結合したり、
またはその逆を行ったりすることができます。

直列実行と並列実行の間の違いを実演するために、
100個の10ミリ秒の遅延からなる配列をつくり、
それからその遅延を両方の手法で実行します。
REPLで試すと`seqDelay`が`parDelay`より遥かに遅いことに気付くでしょう。
並列実行が`sequence_`を`parSequence_`で置き換えるだけで有効になることに注目です。

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

以下は複数のHTTP要求を並列で行う、より現実味のある例です。
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

利用できる並列関数の完全な一覧は[Pursuitの`parallel`のドキュメント](https://pursuit.purescript.org/packages/purescript-parallel/docs/Control.Parallel)で見付かります。
[parallelのaffのドキュメントの節](https://github.com/purescript-contrib/purescript-aff#parallel-execution)にもより多くの例が含まれています。

## 演習

1. （簡単）前の`concatenateMany`関数と同じシグネチャを持つ`concatenateManyParallel`関数を書いてください。
   ただし全ての入力ファイルを並列に読むようにしてください。

1. （普通）与えられたURLへHTTP `GET`要求を行い以下のいずれかを返す`getWithTimeout :: Number -> String
   -> Aff (Maybe String)`関数を書いてください。
    - `Nothing`: 要求してから与えられた時間制限（ミリ秒単位）より長く掛かった場合。
    - 文字列の応答：時間制限を越える前に要求が成功した場合。

1. （難しい）「根」のファイルを取り、そのファイルの中の全てのパスの一覧（そして一覧にあるファイルの中の一覧も）の配列を返す`recurseFiles`関数を書いてください。
   一覧になったファイルを並列に読んでください。
   パスはそのファイルが表れたディレクトリから相対的なものです。
   **ヒント**：`node_path`モジュールにはディレクトリとやりとりする上で便利な関数があります。

たとえば、次のような`root.txt`ファイルから始まるとします。
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

この章では非同期作用を押さえ、以下の方法を学びました。

- `aff`ライブラリを使って`Aff`モナド中で非同期コードを走らせる。
- `affjax`ライブラリを使って非同期にHTTPリクエストを行う。
- `parallel`ライブラリを使って並列に非同期コードを走らせる。

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