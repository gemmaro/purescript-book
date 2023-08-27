# Canvasグラフィックス

## この章の目標

この章は`canvas`パッケージに焦点を当てる発展的な例となります。
このパッケージはPureScriptでHTML5のCanvas APIを使用して2Dグラフィックスを生成する手段を提供します。

## プロジェクトの準備

このモジュールのプロジェクトでは以下の新しい依存関係が導入されます。

- `canvas`はHTML5のCanvas APIメソッドの型を与えます。
- `refs`は _大域的な変更可能領域への参照_ を使うための副作用を提供します。

この章の各ソースコードは、`main`メソッドが定義されているモジュールの集合へと分割されています。
この章の各節の内容は個別のファイルで実装されており、各時点での適切なファイルの`main`メソッドを実行できるように、Spagoビルドコマンドを変更することで、`Main`モジュールを合わせられるようになっています。

HTMLファイル`html/index.html`には、各例で使用される単一の`canvas`要素、及びコンパイルされたPureScriptコードを読み込む`script`要素が含まれています。
各節のコードを試すにはブラウザでHTMLファイルを開きます。
ほとんどの演習はブラウザを対象にしているので、この章には単体試験はありません。

## 単純な図形

`Example/Rectangle.purs`ファイルには簡単な導入例が含まれています。
この例ではキャンバスの中心に青い四角形を1つ描画します。
このモジュールへは、`Effect`モジュールからの`Effect`型と、Canvas
APIを扱うための`Effect`モナドの動作を含む`Graphics.Canvas`モジュールをインポートします。

他のモジュールでも同様ですが、`main`動作は最初に`getCanvasElementById`動作を使ってキャンバスオブジェクトへの参照を取得し、`getContext2D`動作を使ってキャンバスの2D描画文脈にアクセスします。

`void`関数は関手を取り値を`Unit`で置き換えます。
例では`main`がシグネチャに沿うようにするために使われています。

```haskell
{{#include ../exercises/chapter12/src/Example/Rectangle.purs:main}}
```

*補足*：この`unsafePartial`の呼び出しは必須です。
これは`getCanvasElementById`の結果のパターン照合部分で、`Just`値構築子のみと照合するためです。
ここではこれで問題ありませんが、恐らく実際の製品のコードでは`Nothing`値構築子と照合させ、適切なエラー文言を提供したほうがよいでしょう。

これらの動作の型はPSCiを使うかドキュメントを見ると確認できます。

```haskell
getCanvasElementById :: String -> Effect (Maybe CanvasElement)

getContext2D :: CanvasElement -> Effect Context2D
```

`CanvasElement`と `Context2D`は `Graphics.Canvas`モジュールで定義されている型です。
このモジュールでは`Canvas`作用も定義されており、モジュール内の全てのアクションで使用されています。

グラフィックス文脈`ctx`はキャンバスの状態を管理し、原始的な図形を描画したり、スタイルや色を設定したり、座標変換を適用したりするための手段を提供します。

話を進めると、`setFillStyle`動作を使うことで塗り潰しスタイルを濃い青に設定できます。
より長い16進数記法の`#0000FF`も青には使えますが、単純な色については略記法がより簡単です。

```haskell
{{#include ../exercises/chapter12/src/Example/Rectangle.purs:setFillStyle}}
```

`setFillStyle`動作がグラフィックス文脈を引数として取っていることに注意してください。
これは`Graphics.Canvas`ではよくあるパターンです。

最後に、`fillPath`動作を使用して矩形を塗り潰しています。
`fillPath`は次のような型を持っています。

```haskell
fillPath :: forall a. Context2D -> Effect a -> Effect a
```

`fillPath`はグラフィックスの文脈と描画するパスを構築する他の動作を引数に取ります。
`rect`動作を使うとパスを構築できます。
`rect`はグラフィックスの文脈と矩形の位置及びサイズを格納するレコードを取ります。

```haskell
{{#include ../exercises/chapter12/src/Example/Rectangle.purs:fillPath}}
```

mainモジュールの名前として`Example.Rectangle`を与えてこの長方形のコード例をビルドしましょう。

```text
$ spago bundle-app --main Example.Rectangle --to dist/Main.js
```

それでは `html/index.html`ファイルを開き、このコードによってキャンバスの中央に青い四角形が描画されていることを確認してみましょう。

## 行多相を利用する

パスを描画する方法は他にもあります。
`arc`関数は円弧を描画します。
`moveTo`関数、`lineTo`関数、`closePath`関数は断片的な線分のパスを描画できます。

`Shapes.purs`ファイルでは長方形と円弧と三角形の、3つの図形を描画しています。

`rect`関数は引数としてレコードをとることを見てきました。
実際には、長方形のプロパティは型同義語で定義されています。

```haskell
type Rectangle =
  { x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  }
```

`x`と`y`プロパティは左上隅の位置を表しており、`width`と`height`のプロパティはそれぞれ幅と高さを表しています。

`arc`関数に以下のような型を持つレコードを渡して呼び出すと、円弧を描画できます。

```haskell
type Arc =
  { x      :: Number
  , y      :: Number
  , radius :: Number
  , start  :: Number
  , end    :: Number
  }
```

ここで、`x`と`y`プロパティは弧の中心、`radius`は半径、`start`と`end`は弧の両端の角度を弧度法で表しています。

例えばこのコードは中心が`(300, 300)`に中心があり半径`50`の円弧を塗り潰します。
弧は1回転のうち2/3ラジアン分あります。
単位円が上下逆様になっている点に注意してください。
これはy軸がキャンバスの下向きに伸びるためです。

```haskell
  fillPath ctx $ arc ctx
    { x      : 300.0
    , y      : 300.0
    , radius : 50.0
    , start  : 0.0
    , end    : Math.tau * 2.0 / 3.0
    }
```

`Rectangle`レコード型と`Arc`レコード型の両方共、`Number`型の`x`と`y`というプロパティを含んでいますね。
どちらの場合でもこの組は点を表しています。
つまり、何れのレコード型にも作用する行多相な関数を書けます。

例えば`Shapes`モジュールでは`x`と`y`のプロパティを変更し図形を並行移動する`translate`関数が定義されています。

```haskell
{{#include ../exercises/chapter12/src/Example/Shapes.purs:translate}}
```

この行多相型に注目してください。
`translate`が `x`と
`y`というプロパティと、*それに加えて他の任意のプロパティ*を持つどんなレコードでも受け入れ、同じ型のレコードを返すと書かれています。
`x`フィールドと `y`フィールドは更新されますが、残りのフィールドは変更されません。

これは*レコード更新構文*の例です。
`shape { ... }`という式は、`shape`を元にして、括弧の中で指定された値で更新されたフィールドを持つ新たなレコードを作ります。
なお、波括弧の中の式はレコード直値のようなコロンではなく、等号でラベルと式を区切って書きます。

`Shapes`の例からわかるように、`translate`関数は`Rectangle`レコードと`Arc`レコード双方に対して使えます。

`Shape`の例で描画される3つ目の型は線分の断片からなるパスです。
対応するコードは次のようになります。

```haskell
{{#include ../exercises/chapter12/src/Example/Shapes.purs:path}}
```

ここでは3つの関数が使われています。

- `moveTo`はパスの現在地を指定された座標に移動します。
- `lineTo`は現在地と指定された座標の間の線分を描画し、現在地を更新します。
- `closePath`は現在地と開始地点とを結ぶ線分を描画してパスを完結します。

このコード片の結果は二等辺三角形の塗り潰しになります。

mainモジュールとして`Example.Shapes`を指定して、この例をビルドしましょう。

```text
$ spago bundle-app --main Example.Shapes --to dist/Main.js
```

そしてもう一度`html/index.html`を開き、結果を確認してください。
キャンバスに3つの異なる図形が描画されるはずです。

## 演習

 1. （簡単）これまでの各例について、`strokePath`関数や`setStrokeStyle`関数を使ってみましょう。
 1. （簡単）関数の引数の内部でdo記法ブロックを使うと、`fillPath`関数と`strokePath`関数は共通のスタイルを持つ複雑なパスを描画できます。
    同じ`fillPath`呼び出しを使って隣り合う2つの矩形を描画するように、`Rectangle`の例を変更してみてください。
    線分と円弧の組み合わせを使って、扇形を描画してみてください。
 1. （普通）次のような2次元の点を表すレコードが与えられたとします。

     ```haskell
     type Point = { x :: Number, y :: Number }
     ```

     これは2次元の点を表現しています。
     多数の点からなる閉じたパスを線描きする関数 `renderPath`を書いてください。

     ```haskell
     renderPath
       :: Context2D
       -> Array Point
       -> Effect Unit
     ```

     次のような関数を考えます。

     ```haskell
     f :: Number -> Point
     ```

    この関数は引数として`1`から`0`の間の`Number`を取り、`Point`を返します。
    `renderPath`関数を使い、関数`f`のグラフを描く動作を書いてください。
    その動作では有限個の点で`f`を標本化することによって近似しなければなりません。

     関数 `f`を変更し、様々なパスが描画されることを確かめてください。

## 無作為に円を描く

`Example/Random.purs`ファイルには、`Effect`モナドを使って2種類の副作用を綴じ合わせる例が含まれています。
1つの副作用は乱数生成で、もう1つはキャンバスの操作です。
この例では無作為に生成された円をキャンバスに100個描画します。

`main`動作ではこれまでのようにグラフィックス文脈への参照を取得し、線描きと塗り潰しのスタイルを設定します。

```haskell
{{#include ../exercises/chapter12/src/Example/Random.purs:style}}
```

次のコードでは`for_`動作を使って`0`から`100`までの整数について反復しています。

```haskell
{{#include ../exercises/chapter12/src/Example/Random.purs:for}}
```

各繰り返しで、do記法ブロックは`0`と`1`の間に分布する3つの乱数を生成することから始まります。
これらの数はそれぞれ`x`座標、`y`座標、半径`r`を表しています。

```haskell
{{#include ../exercises/chapter12/src/Example/Random.purs:random}}
```

次のコードでは各円について、これらの変数に基づいて`Arc`を作成し、最後に現在のスタイルに従って円弧を塗り潰し、線描きします。

```haskell
{{#include ../exercises/chapter12/src/Example/Random.purs:path}}
```

mainモジュールとして`Example.Random`を指定して、この例をビルドしましょう。

```text
$ spago bundle-app --main Example.Random --to dist/Main.js
```

`html/index.html`を開いて、結果を確認してみましょう。

## 座標変換

キャンバスは簡単な図形を描画するだけのものではありません。
キャンバスは座標変換を管理しており、描画の前に図形を変形するのに使えます。
図形は平行移動、回転、拡大縮小、及び斜めに変形できます。

`canvas`ライブラリではこれらの変換を以下の関数で提供しています。

```haskell
translate :: Context2D
          -> TranslateTransform
          -> Effect Context2D

rotate    :: Context2D
          -> Number
          -> Effect Context2D

scale     :: Context2D
          -> ScaleTransform
          -> Effect Context2D

transform :: Context2D
          -> Transform
          -> Effect Context2D
```

`translate`動作は`TranslateTransform`レコードのプロパティで指定した大きさだけ平行移動します。

`rotate`動作は最初の引数で指定されたラジアンの数値に応じて、原点を中心として回転します。

`scale`動作は原点を中心として拡大縮小します。
`ScaleTransform`レコードは`x`軸と`y`軸に沿った拡大率を指定するのに使います。

最後の `transform`はこの4つのうちで最も一般化された動作です。
この動作では行列に従ってアフィン変換します。

これらの動作が呼び出された後に描画される図形は、自動的に適切な座標変換が適用されます。

実際には、これらの関数の各作用は、文脈の現在の変換行列に対して変換行列を*右から乗算*していきます。
つまり、もしある作用の変換をしていくと、その作用は実際には逆順に適用されていきます。

```haskell
transformations ctx = do
  translate ctx { translateX: 10.0, translateY: 10.0 }
  scale ctx { scaleX: 2.0, scaleY: 2.0 }
  rotate ctx (Math.tau / 4.0)

  renderScene
```

この一連の動作の作用では、まずシーンが回転され、それから拡大縮小され、最後に平行移動されます。

## 文脈の保存

座標変換を使ってシーンの一部を描画し、それからその変換を元に戻す、という使い方はよくあります。

Canvas APIにはキャンバスの状態の*スタック*を操作する`save`と`restore`メソッドが備わっています。
`canvas`ではこの機能を次のような関数で梱包しています。

```haskell
save
  :: Context2D
  -> Effect Context2D

restore
  :: Context2D
  -> Effect Context2D
```

`save`動作は現在の文脈の状態（現在の変換行列や描画スタイル）をスタックにプッシュし、`restore`動作はスタックの一番上の状態をポップし、文脈の状態を復元します。

これらの動作により、現在の状態を保存し、いろいろなスタイルや変換を適用してから原始的な図形を描画し、最後に元の変換と状態を復元できます。
例えば次の関数は幾つかのキャンバス動作を実行しますが、その前に回転を適用し、その後に変換を復元します。

```haskell
rotated ctx render = do
  save ctx
  rotate (Math.tau / 3.0) ctx
  render
  restore ctx
```

こういったよくある高階関数の使われ方の抽象化として、`canvas`ライブラリでは元の文脈状態を保存しつつ幾つかのキャンバス動作を実行する`withContext`関数が提供されています。

```haskell
withContext
  :: Context2D
  -> Effect a
  -> Effect a
```

`withContext`を使うと、先ほどの `rotated`関数を次のように書き換えることができます。

```haskell
rotated ctx render =
  withContext ctx do
    rotate (Math.tau / 3.0) ctx
    render
```

## 大域的な変更可能状態

この節では `refs`パッケージを使って `Effect`モナドの別の作用について実演してみます。

`Effect.Ref`モジュールでは、大域的に変更可能な参照のための型構築子、及びそれに紐付く作用を提供します。

```text
> import Effect.Ref

> :kind Ref
Type -> Type
```

型`Ref a`の値は型`a`の値を含む可変参照セルであり、大域的な変更を追跡するのに使われます。
そういったわけでこれは少しだけ使う分に留めておくべきです。

`Example/Refs.purs`ファイルには `canvas`要素上のマウスクリックを追跡するのに `Ref`を使う例が含まれます。

このコードでは最初に`new`動作を使って値`0`を含む新しい参照を作成しています。

```haskell
{{#include ../exercises/chapter12/src/Example/Refs.purs:clickCount}}
```

クリックイベント制御子の内部では、`modify`動作を使用してクリック数を更新し、更新された値が返されています。

```haskell
{{#include ../exercises/chapter12/src/Example/Refs.purs:count}}
```

`render`関数ではクリック数に応じた変換を矩形に適用しています。

```haskell
{{#include ../exercises/chapter12/src/Example/Refs.purs:withContext}}
```

この動作では元の変換を保存するために`withContext`を使用しており、それから一連の変換を適用しています（変換が下から上に適用されることを思い出してください）。

- 矩形が`(-100, -100)`だけ平行移動し、中心が原点に来ます。
- 矩形が原点を中心に拡大されます。
- 矩形が原点を中心に`10`の倍数分の角度で回転します。
- 矩形が`(300, 300)`だけ平行移動し、中心がキャンバスの中心に来ます。

このコード例をビルドしてみましょう。

```text
$ spago bundle-app --main Example.Refs --to dist/Main.js
```

`html/index.html`ファイルを開いてみましょう。
緑の四角形が表示され、何度かキャンバスをクリックするとキャンバスの中心の周りで回転するはずです。

## 演習

 1. （簡単）パスの線描と塗り潰しを同時に行う高階関数を書いてください。
    その関数を使用して`Random.purs`の例を書き直してください。
 1. （普通）`Random`作用と`Dom`作用を使用して、マウスがクリックされたときに、キャンバスに無作為な位置、色、半径の円を描画するアプリケーションを作成してください。
 1. （普通）指定された座標の点を中心として回転させることでシーンを変換する関数を書いてください。
    *手掛かり*：変換を使い、最初にシーンを原点まで平行移動しましょう。

## L-System

この章の最後の例として、 `canvas`パッケージを使用して*L-system*（またの名を*Lindenmayer
system*）を描画する関数を記述します。

1つのL-Systemは*アルファベット*、つまりアルファベット由来の文字の初期の並びと、*生成規則*の集合で定義されます。
各生成規則は、アルファベットの文字を取り、それを置き換える文字の並びを返します。
この処理は文字の初期の並びから始まり、複数回繰り返されます。

もしアルファベットの各文字がキャンバス上で実行される命令と対応付けられていれば、その指示に順番に従うことでL-Systemを描画できます。

例えばアルファベットが文字`L`（左回転）、`R`（右回転）、`F`（前進）で構成されているとします。
次のような生成規則を定義できます。

```text
L -> L
R -> R
F -> FLFRRFLF
```

配列 "FRRFRRFRR" から始めて処理を繰り返すと、次のような経過を辿ります。

```text
FRRFRRFRR
FLFRRFLFRRFLFRRFLFRRFLFRRFLFRR
FLFRRFLFLFLFRRFLFRRFLFRRFLFLFLFRRFLFRRFLFRRFLF...
```

というように続きます。
この命令群に対応する線分パスをプロットすると、*コッホ曲線*に近似されます。
反復回数を増やすと、曲線の解像度が増していきます。

それでは型と関数のある言語へとこれを翻訳してみましょう。

アルファベットの文字は以下のADTで表現できます。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:letter}}
```

このデータ型では、アルファベットの文字ごとに1つずつデータ構築子が定義されています。

文字の初期配列はどのように表したらいいでしょうか。
単なるアルファベットの配列でいいでしょう。
これを `Sentence`と呼ぶことにします。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:sentence}}

{{#include ../exercises/chapter12/src/Example/LSystem.purs:initial}}
```

生成規則は以下のように`Letter`から `Sentence`への関数として表すことができます。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:productions}}
```

これはまさに上記の仕様をそのまま書き写したものです。

これで、この形式の仕様を受け取ってキャンバスに描画する関数`lsystem`を実装できます。
`lsystem`はどのような型を持っているべきでしょうか。
`initial`や`productions`のような値だけでなく、アルファベットの文字をキャンバスに描画できる関数を引数に取る必要があります。

`lsystem`の型の最初の大まかな設計は以下です。

```haskell
Sentence
-> (Letter -> Sentence)
-> (Letter -> Effect Unit)
-> Int
-> Effect Unit
```

最初の2つの引数の型は、値 `initial`と `productions`に対応しています。

3番目の引数は、アルファベットの文字を取り、キャンバス上の幾つかの動作を実行することによって*解釈*する関数を表します。
この例では、文字`L`は左回転、文字`R`で右回転、文字`F`は前進を意味します。

最後の引数は、実行したい生成規則の繰り返し回数を表す数です。

最初に気付くことは、この`lsystem`関数は1つの型`Letter`に対してのみ動作するのですが、どんなアルファベットについても機能すべきですから、この型はもっと一般化されるべきです。
それでは、量子化された型変数 `a`について、`Letter`と `Sentence`を `a`と `Array a`で置き換えましょう。

```haskell
forall a. Array a
          -> (a -> Array a)
          -> (a -> Effect Unit)
          -> Int
          -> Effect Unit
```

次に気付くこととしては、「左回転」と「右回転」のような命令を実装するためには、幾つかの状態を管理する必要があります。
具体的に言えば、その時点でパスが動いている方向を状態として持たなければなりません。
計算を通じて状態を渡すように関数を変更する必要があります。
ここでも`lsystem`関数は状態がどんな型でも動作したほうがよいので、型変数`s`を使用してそれを表しています。

型 `s`を追加する必要があるのは3箇所で、次のようになります。

```haskell
forall a s. Array a
            -> (a -> Array a)
            -> (s -> a -> Effect s)
            -> Int
            -> s
            -> Effect s
```

まず追加の引数の型として `lsystem`に型 `s`が追加されています。
この引数はL-Systemの初期状態を表しています。

型
`s`は引数にも現れますが、解釈関数（`lsystem`の第3引数）の返り値の型としても現れます。解釈関数は今のところ、引数としてL-Systemの現在の状態を受け取り、返り値として更新された新しい状態を返します。

この例の場合では、次のような型を使って状態を表す型を定義できます。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:state}}
```

プロパティ `x`と `y`はパスの現在の位置を表しています。
プロパティ`theta`はパスの現在の向きを表しており、ラジアンで表された水平線に対するパスの角度として指定されています。

システムの初期状態は次のように指定されます。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:initialState}}
```

それでは、 `lsystem`関数を実装してみます。定義はとても単純であることがわかるでしょう。

`lsystem`は第4引数の値（型は`Int`）に応じて再帰するのが良さそうです。
再帰の各ステップでは、生成規則に従って状態が更新され、現在の文が変化していきます。
このことを念頭に置きつつ、まずは関数の引数の名前を導入して、補助関数に処理を移譲することから始めましょう。

```haskell
lsystem :: forall a s
         . Array a
        -> (a -> Array a)
        -> (s -> a -> Effect s)
        -> Int
        -> s
        -> Effect s
{{#include ../exercises/chapter12/src/Example/LSystem.purs:lsystem_impl}}
```

`go`関数は第2引数について再帰することで動作します。
場合分けは2つであり、`n`がゼロであるときと`n`がゼロでないときです。

1つ目の場合は再帰は完了し、解釈関数に応じて現在の文を解釈します。
型`Array a`の文、型`s`の状態、型`s -> a -> Effect s`の関数があります。
以前定義した`foldM`の出番のようです。
この関数は`control`パッケージで手に入ります。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:lsystem_go_s_0}}
```

ゼロでない場合ではどうでしょうか。
その場合は、単に生成規則を現在の文のそれぞれの文字に適用して、その結果を連結し、そして再帰的に`go`を呼び出すことによって繰り返します。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:lsystem_go_s_i}}
```

これだけです。
`foldM`や`concatMap`のような高階関数を使うと、アイデアを簡潔に表現できるのです。

しかし、話はこれで終わりではありません。
ここで与えた型は、実際はまだ特殊化されすぎています。
この定義ではキャンバスの操作が実装のどこにも使われていないことに注目してください。
それに、全く`Effecta`モナドの構造を利用していません。
実際には、この関数は*どんな*モナド`m`についても動作します。

この章に添付されたソースコードで指定されている`lsystem`の型はもっと一般的になっています。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:lsystem_anno}}
```

この型で書かれていることは、この解釈関数はモナド`m`が持つ任意の副作用を完全に自由に持つことができる、ということだと理解できます。
キャンバスに描画したり、またはコンソールに情報を出力したりするかもしれませんし、失敗や複数の戻り値に対応しているかもしれません。
こういった様々な型の副作用を使ったL-Systemを記述してみることを読者にお勧めします。

この関数は実装からデータを分離することの威力を示す良い例となっています。
この手法の利点は、複数の異なる方法でデータを解釈できることです。
さらに`lsystem`を2つの小さな関数へと分解できます。
1つ目は`concatMap`の適用の繰り返しを使って文を構築するもの、2つ目は`foldM`を使って文を解釈するものです。
これは読者の演習として残しておきます。

それでは解釈関数を実装して、この章の例を完成させましょう。
`lsystem`の型が教えてくれているのは、型シグネチャが、何らかの型 `a`と `s`、型構築子 `m`について、 `s -> a -> m s`でなければならないということです。
`a`を `Letter`、 `s`を `State`、モナド `m`を `Effect`というように選びたいということがわかっています。
これにより次のような型になります。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:interpret_anno}}
```

この関数を実装するには、 `Letter`型の3つのデータ構築子それぞれについて処理する必要があります。文字 `L`（左回転）と
`R`（右回転）の解釈では、`theta`を適切な角度へ変更するように状態を更新するだけです。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:interpretLR}}
```

文字`F`（前進）を解釈するには、次のようにパスの新しい位置を計算し、線分を描画し、状態を更新します。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:interpretF}}
```

なお、この章のソースコードでは、名前 `ctx`がスコープに入るように、`interpret`関数は `main`関数内で
`let`束縛を使用して定義されています。
`State`型が文脈を持つように変更できるでしょうが、それはこのシステムの状態の変化する部分ではないので不適切でしょう。

このL-Systemを描画するには、次のような`strokePath`動作を使用するだけです。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:strokePath}}
```

次のコマンドを使ってL-Systemをコンパイルします。

```text
$ spago bundle-app --main Example.LSystem --to dist/Main.js
```

`html/index.html`を開いてみましょう。
キャンバスにコッホ曲線が描画されるのがわかると思います。

## 演習

 1. （簡単）`strokePath`の代わりに `fillPath`を使用するように、上のL-Systemの例を変更してください。
    *手掛かり*：`closePath`の呼び出しを含め、 `moveTo`の呼び出しを `interpret`関数の外側に移動する必要があります。
 1. （簡単）描画システムへの影響を理解するために、コード中の様々な数値の定数を変更してみてください。
 1. （普通）`lsystem`関数を2つの小さな関数に分割してください。
    1つ目は`concatMap`の適用の繰り返しを使用して最終的な文を構築するもので、2つ目は
    `foldM`を使用して結果を解釈するものでなくてはなりません。
 1. （普通）`setShadowOffsetX`、`setShadowOffsetY`、`setShadowBlur`、`setShadowColor`動作を使い、塗りつぶされた図形にドロップシャドウを追加してください。
    *手掛かり*：PSCiを使って、これらの関数の型を調べてみましょう。
 1. （普通）向きを変えるときの角度の大きさは今のところ一定 (`tau/6`) です。
    これに代えて、`Letter`データ型の中に角度を移動させ、生成規則によって変更できるようにしてください。

     ```haskell
     type Angle = Number

     data Letter = L Angle | R Angle | F
     ```

     この新しい情報を生成規則でどう使うと、面白い図形を作ることができるでしょうか。
1. （難しい）4つの文字からなるアルファベットでL-Systemが与えられたとします。
   それぞれ`L`（60度左回転）、`R`（60度右回転）、`F`（前進）、`M`（これも前進）です。

     このシステムの文の初期状態は、単一の文字 `M`です。

     このシステムの生成規則は次のように指定されています。

     ```text
     L -> L
     R -> R
     F -> FLMLFRMRFRMRFLMLF
     M -> MRFRMLFLMLFLMRFRM
     ```

     このL-Systemを描画してください。
     *補足*：最後の文のサイズは反復回数に従って指数関数的に増大するので、生成規則の繰り返しの回数を削減する必要があります。

     ここで、生成規則における `L`と `M`の間の対称性に注目してください。2つの「前進」命令は、次のようなアルファベット型を使用すると、`Boolean`値を使って区別できます。

     ```haskell
     data Letter = L | R | F Boolean
     ```

    このアルファベットの表現を使用して、もう一度このL-Systemを実装してください。
1. （難しい）解釈関数で別のモナド `m`を使ってみましょう。`Effect.Console`作用を利用してコンソール上にL-Systemを出力したり、`Random`作用を利用して状態の型に無作為の「突然変異」を適用したりしてみてください。

## まとめ

この章では、`canvas`ライブラリを使用することにより、PureScriptからHTML5 Canvas APIを使う方法について学びました。
また、これまで学んできた多くの手法からなる実用的な実演を見ました。
マップや畳み込み、レコードと行多相、副作用を扱うための`Effect`モナドです。

この章の例では、高階関数の威力を示すとともに、 _実装からのデータの分離_
も実演してみせました。これは例えば、代数データ型を使用してこれらの概念を次のように拡張し、描画関数からシーンの表現を完全に分離できるようになります。

```haskell
data Scene
  = Rect Rectangle
  | Arc Arc
  | PiecewiseLinear (Array Point)
  | Transformed Transform Scene
  | Clipped Rectangle Scene
  | ...
```

この手法は`drawing`パッケージで採られており、描画前に様々な方法でシーンをデータとして操作できる柔軟性を齎しています。

キャンバスに描画されるゲームの例については[cookbook](https://github.com/JordanMartinez/purescript-cookbook/blob/master/README.md#recipes)の「Behavior」と「Signal」のレシピを見てください。
