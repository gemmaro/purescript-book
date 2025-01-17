# 導入

## 関数型JavaScript

関数型プログラミングの手法がJavaScriptに姿を現しはじめてからしばらく経ちます。

- [UnderscoreJS](https://underscorejs.org)などのライブラリがあれば、開発者は`map`や
  `filter`、`reduce`といった実績のある関数を活用して、小さいプログラムを組み合わせることで大きなプログラムを作ることができます。

    ```javascript
    var sumOfPrimes =
        _.chain(_.range(1000))
         .filter(isPrime)
         .reduce(function(x, y) {
             return x + y;
         })
         .value();
    ```

- NodeJSにおける非同期プログラミングでは、第一級の値としての関数をコールバックを定義するために多用しています。

    ```javascript
    import { readFile, writeFile } from 'fs'

    readFile(sourceFile, function (error, data) {
      if (!error) {
        writeFile(destFile, data, function (error) {
          if (!error) {
            console.log("File copied");
          }
        });
      }
    });
    ```

- [React](https://reactjs.org)や[virtual-dom](https://github.com/Matt-Esch/virtual-dom)などのライブラリは、アプリケーションの状態についての純粋な関数としてその外観をモデル化しています

関数は大幅な生産性の向上を齎しうる単純な抽象化を可能にします。
しかし、JavaScriptでの関数型プログラミングには欠点があります。
JavaScriptは冗長で、型付けされず、強力な抽象化の形式を欠いているのです。
また、野放図なJavaScriptコードは等式推論がとても困難です。

PureScriptはこうした課題への対処を目指すプログラミング言語です。
PureScriptは軽量な構文を備えていますが、この構文によりとても表現力豊かでありながら分かりやすく読みやすいコードが書けるのです。
強力な抽象化を支援する豊かな型システムも採用しています。
また、JavaScriptやJavaScriptへとコンパイルされる他の言語と相互運用するときに重要な、高速で理解しやすいコードを生成します。
概してPureScriptとは、純粋関数型プログラミングの理論的な強力さと、JavaScriptのお手軽で緩いプログラミングスタイルとの、とても現実的なバランスを狙った言語だということを理解して頂けたらと思います。

> なお、PureScriptはJavaScriptのみならず他のバックエンドを対象にできますが、本書ではwebブラウザとnode環境に焦点を絞ります。

## 型と型推論

動的型付けの言語と静的型付けの言語をめぐる議論については充分に文書化されています。
PureScriptは*静的型付け*の言語、つまり正しいプログラムはコンパイラによって*型*を与えられる言語です。
またこの型は、その動作を示すものです。
逆に言えば、型を与えることができないプログラムは*誤ったプログラム*であり、コンパイラによって拒否されます。
動的型付けの言語とは異なり、PureScriptでは型は*コンパイル時*にのみ存在し、実行時には一切その表現がありません。

多くの点で、PureScriptの型とこれまでJavaやC#のような他の言語で見てきたであろう型が異なっていることにも、注意することが大切です。
大まかに言えばPureScriptの型はJavaやC#と同じ目的を持っているものの、PureScriptの型はMLやHaskellのような言語に影響を受けています。
PureScriptの型は表現力豊かであり、開発者はプログラムについての強い主張を表明できます。
最も重要なのはPureScriptの型システムが*型推論*に対応していることです。
型推論があれば他の言語より明示的な型注釈が遥かに少なく済み、型システムを厄介者ではなく*道具*にしてくれます。
単純な一例として、次のコードは*数*を定義していますが、`Number`型への言及はコードのどこにもありません。

```haskell
iAmANumber =
  let square x = x * x
  in square 42.0
```

より込み入った次の例では、*コンパイラにとって未知*の型が存在します。
それでも、型注釈なく型の正しさを確かめられていることを示しています。

```haskell
iterate f 0 x = x
iterate f n x = iterate f (n - 1) (f x)
```

ここで
`x`の型は不明ですが、`x`がどんな型を持っているかにかかわらず、`iterate`が型システムの規則に従っていることをコンパイラは検証できます。

本書で納得していただきたい（または既にお持ちの信条に寄り添って改めて断言したい）ことは、静的型が単にプログラムの正しさに自信を持つためだけのものではなく、それ自体の正しさによって開発の手助けになるものでもあるということです。JavaScriptではごく単純な抽象化を施すのでも大規模なコードのリファクタリングをすることは難しいですが、型検証器のある表現力豊かな型システムは、リファクタリングさえ楽しく対話的な体験にしてくれます。

加えて、型システムによって提供されるこの安全網は、より高度な抽象化を可能にします。
実際に、根本的に型駆動な抽象化の強力な形式である型クラスをPureScriptは提供しています。
この型クラスとは、関数型プログラミング言語Haskellによって有名になりました。

## 多言語webプログラミング

関数型プログラミングは成功を収めてきました。
特に成功している応用例を挙げると、データ解析、構文解析、コンパイラの実装、ジェネリックプログラミング、並列処理といった具合に、枚挙に暇がありません。

PureScriptのような関数型言語でアプリケーション開発の最初から最後までを実施できるでしょう。
値や関数の型を提供することで既存のJavaScriptコードをインポートし、通常のPureScriptコードからこれらの関数を使用する機能をPureScriptは提供しています。
この手法については本書の後半で見ていくことになります。

しかし、PureScriptの強みの1つは、JavaScriptを対象とする他の言語との相互運用性にあります。
アプリケーションの開発の一部にだけPureScriptを使用し、JavaScriptの残りの部分を記述するのに1つ以上の他の言語を使用するという方法もあります。

幾つかの例を示します。

- 中核となる処理はPureScriptで記述し、ユーザーインターフェイスはJavaScriptで記述する
- JavaScriptや、他のJavaScriptにコンパイルする言語でアプリケーションを書き、PureScriptでそのテストを書く
- 既存のアプリケーションのユーザインターフェースのテストを自動化するためにPureScriptを使用する

本書では小規模な課題をPureScriptで解決することに焦点を当てます。
ここで学ぶ手法は大規模なアプリケーションに組み込むこともできますが、JavaScriptからPureScriptコードを呼び出す方法、及びその逆についても見ていきます。

## ソフトウェア要件

本書のソフトウェア要件は最小限です。
第1章では開発環境の構築を一から案内します。
これから使用するツールは、ほとんどの現代のオペレーティングシステムの標準リポジトリで使用できるものです。

PureScriptコンパイラ自体はバイナリの配布物としてもダウンロードできますし、最新のGHC
Haskellコンパイラが動く任意のシステム上でソースからのビルドもできます。
次の章ではこの手順を進めていきます。

本書のこのバージョンのコードは`0.15.*`バージョンのPureScriptコンパイラと互換性があります。

## 読者について

読者はJavaScriptの基本を既に理解しているものと仮定します。
既にNPMやBowerのようなJavaScriptのエコシステムでの経験があれば、自身の好みに応じて標準設定をカスタマイズしたい場合などに役に立ちます。
ですがそのような知識は必要ありません。

関数型プログラミングの事前知識は必要ありませんが、あっても決して害にはならないでしょう。
新しい考えかたは実例と共に登場するため、これから使っていく関数型プログラミングからこうした概念に対する直感が形成されることでしょう。

PureScriptはプログラミング言語Haskellに強く影響を受けているため、Haskellに通じている読者は本書で提示された概念や構文の多くに見覚えがあるでしょう。
しかし、PureScriptとHaskellの間には数多くの重要な違いがあることも理解しておくと良いでしょう。
ここで紹介する概念の多くはHaskellでも同じように解釈できるとはいえ、どちらかの言語での考え方を他方の言語でそのまま応用しようとすることは、必ずしも適切ではありません。

## 本書の読み進めかた

本書のほとんどの章が各章毎に完結しています。
しかし、関数型プログラミングの経験がほとんどない初心者の方は、各章を順番に進めていくのが賢明です。
最初の数章は本書の後半の内容を理解するのに必要な下地作りです。
関数型プログラミングの考え方に充分通じた読者（特にMLやHaskellのような強く型付けされた言語での経験を持つ読者）なら、本書の前半の章を読まなくても、後半の章のコードの大まかな理解を得ることが恐らく可能でしょう。

各章では1つの実用的な例に焦点を当て、新しい考え方を導入するための動機を与えます。
各章のコードは本書の[GitHubのリポジトリ](https://github.com/purescript-contrib/purescript-book)から入手できます。
該当の章のソースコードから抜粋したコード片が含まれる章もありますが、本書の内容に沿ってリポジトリのソースコードを読まれると良いでしょう。
長めの節には、理解を確かめられるように対話式モードのPSCiで実行できる短めのコード片が含まれます。

コード例は次のように等幅フォントで示されます。

```haskell
module Example where

import Effect.Console (log)

main = log "Hello, World!"
```

先頭にドル記号がついた行は、コマンドラインに入力されたコマンドです。

```text
$ spago build
```

通常、これらのコマンドはLinuxやMac OSの利用者に合わせたものになっています。
そのためWindowsの利用者は小さな変更を加える必要があるかもしれません。
ファイル区切り文字を変更したり、シェルの組み込み機能をWindowsの相当するものに置き換えるなどです。

PSCi対話式モードプロンプトに入力するコマンドは、行の先頭に山括弧が付けられています。

```text
> 1 + 2
3
```

各章には演習が含まれており、難易度も示されています。
内容を完全に理解するために、各章の演習に取り組むことを強くお勧めします。

本書は初心者にPureScriptへの導入を提供することを目的としており、課題に対するお決まりの解決策の一覧を提供するような類の本ではありません。
初心者にとっては楽しい挑戦になるはずです。
内容を読んで演習に挑戦すれば得るものがあることでしょう。
そして何よりも大切なのは、自分自身でコードを書いてみることです。

## 困ったときには

もしどこかでつまずいたときには、PureScriptを学べるオンラインで利用可能な資料が沢山あります。

- [PureScriptのDiscordサーバ](https://discord.gg/vKn9up84bp)は抱えている問題についてチャットするのに良い場所です。
  こちらのサーバはPureScriptについてのチャット専用です。
- [PureScriptのDiscourseフォーラム](https://discourse.purescript.org/)もよくある問題への解決策を探すのに良い場所です。
- [PureScript: Jordan's
  Reference](https://github.com/jordanmartinez/purescript-jordans-reference)は別のかなり深く踏み込んだ学習資料です。
  本書中の概念で理解しにくいものがあったら、そちらの参考書の対応する節を読むとよいでしょう。
- [Pursuit](https://pursuit.purescript.org)はPureScriptの型と関数を検索できるデータベースです。
  Pursuitのヘルプページを読むと[どのような種類の検索ができるのかがわかります](https://pursuit.purescript.org/help/users)。
- 非公式の[PureScript
  Cookbook](https://github.com/JordanMartinez/purescript-cookbook)は「Xするにはどうするの」といった類の質問にコードを混じえて答えを提供します。
- [PureScriptドキュメントリポジトリ](https://github.com/purescript/documentation)には、PureScriptの開発者や利用者が書いた幅広い話題の記事と例が集まっています。
- [PureScriptのwebサイト](https://www.purescript.org)には幾つかの学習資料へのリンクがあります。
  コード例、映像、他の初心者向け資料などです。
- [Try
  PureScript!](https://try.purescript.org)は利用者がwebブラウザでPureScriptのコードをコンパイルできるwebサイトです。
  幾つかの簡単なコードの例もあります。

もし例を読んで学ぶ方が好きでしたら、GitHubの[purescript](https://github.com/purescript)、[purescript-node](https://github.com/purescript-node)、[purescript-contrib](https://github.com/purescript-contrib)組織にはPureScriptコードの例が沢山あります。

## 著者について

私はPureScriptコンパイラの最初の開発者です。
カリフォルニア州ロサンゼルスを拠点にしており、8ビットパーソナルコンピュータであるAmstrad
CPC上のBASICでまだ幼い時にプログラミングを始めました。
それ以来、私は幾つものプログラミング言語（JavaやScala、C#、F#、Haskell、そしてPureScript）で専門的に業務に携わってきました。

プロとしての経歴が始まって間もなく、私は関数型プログラミングと数学の関係を理解するようになり、そしてプログラミング言語Haskellを使って関数型の概念の学習を楽しみました。

JavaScriptでの経験をもとに、私はPureScriptコンパイラの開発を始めることにしました。
気が付くとHaskellのような言語から取り上げた関数型プログラミングの手法を使っていましたが、それを応用するためのもっと理に適った環境を求めていました。
そのとき検討した案のなかには、Haskellからその意味論を維持しながらJavaScriptへとコンパイルするいろいろな試み（Fay、Haste、GHCJS）もありました。
しかし私が興味を持っていたのは、この問題へ別の切り口からアプローチすると、どの程度うまくいくのかということでした。
そのアプローチとは、JavaScriptの意味論を維持しつつ、Haskellのような言語の構文と型システムを楽しむことなのです。

私は[ブログ](http://blog.functorial.com)を運営しており、[Twitterで連絡をとる](http://twitter.com/paf31)こともできます。

## 謝辞

現在に至るまでPureScriptに手を貸してくださった多くの協力者に感謝したいと思います。
コンパイラ、ツール、ライブラリ、ドキュメント、テストでの、巨大で組織的な尽力なくしては、プロジェクトは間違いなく失敗していたことでしょう。

本書の表紙に示されたPureScriptのロゴはGareth Hughesによって作成されたもので、[Creative Commons
Attribution 4.0
license](https://creativecommons.org/licenses/by/4.0/)の条件の下で再利用させて頂いています 。

最後に、本書の内容に関する反応や訂正をくださった全ての方に、心より感謝したいと思います。
