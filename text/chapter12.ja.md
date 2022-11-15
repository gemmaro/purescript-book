# Canvasグラフィックス

## この章の目標

この章は`canvas`パッケージに焦点を当てる発展的な例となります。このパッ
ケージはPureScriptでHTML5のCanvas APIを使用して2Dグラフィックスを生成
する手段を提供します。

## プロジェクトの準備

このモジュールのプロジェクトでは以下の新しい依存関係が導入されます。

- `canvas`はHTML5のCanvas APIのメソッドの型を与えます。
- `refs`は**大域的な変更可能領域への参照**を使うための副作用を提供します。

この章のソースコードは、それぞれに `main`メソッドが定義されているモジュー
ルの集合へと分割されています。この章のそれぞれの節の内容はそれぞれの異
なるファイルで実装されており、それぞれの時点での適切なファイルの
`main`メソッドを実行できるように、Spagoビルドコマンドを変更することで
`Main`モジュールが変更できるようになっています。

HTMLファイル `html/index.html`には、各例で使用される単一の `canvas`要
素、およびコンパイルされたPureScriptコードを読み込む `script`要素が含
まれています。ほとんどの演習はブラウザを対象にしているので、この章には
単体試験はありません。

## 単純な図形

`Example/Rectangle.purs`ファイルには簡単な導入例が含まれています。この
例ではcanvasの中心に青い四角形をひとつ描画します。このモジュールは、
`Effect`モジュールからの`Effect`型と、Canvas APIを扱うための`Effect`モ
ナドのアクションを含む`Graphics.Canvas`モジュールをインポートします。

他のモジュールでも同様ですが、 `main`アクションは最初に
`getCanvasElementById`アクションを使ってcanvasオブジェクトへの参照を取
得しています。また、 `getContext2D`アクションを使ってキャンバスの2D描
画コンテキストを参照しています。

`void`関数は関手を取り値を`Unit`で置き換えます。例では`main`がシグネチャ
に沿うようにするために使われています。

```haskell
{{#include ../exercises/chapter12/src/Example/Rectangle.purs:main}}
```

**注意**：この`unsafePartial`の呼び出しは必須です。これは
`getCanvasElementById`の結果のパターン照合部分的で、`Just`値構築子だけ
と照合するためです。ここではこれで問題ありませんが、実際の製品のコード
ではおそらく`Nothing`値構築子と照合させ、適切なエラーメッセージを提供
したほうがよいでしょう。

これらのアクションの型は、PSCiを使うかドキュメントを見ると確認できます。

```haskell
getCanvasElementById :: String -> Effect (Maybe CanvasElement)

getContext2D :: CanvasElement -> Effect Context2D
```

`CanvasElement`と `Context2D`は `Graphics.Canvas`モジュールで定義され
ている型です。このモジュールでは`Canvas`作用も定義されており、モジュー
ル内のすべてのアクションで使用されています。

グラフィックスコンテキスト `ctx`は、canvasの状態を管理し、原始的な図形
を描画したり、スタイルや色を設定したり、座標変換を適用するためのメソッ
ドを提供しています。

話を進めると、`setFillStyle`アクションを使うことで塗り潰しスタイルを濃
い青に設定できます。より長い16進数記法の`#0000FF`も青には使えますが、
略記法が単純な色についてはより簡単です。

```haskell
{{#include ../exercises/chapter12/src/Example/Rectangle.purs:setFillStyle}}
```

`setFillStyle`アクションがグラフィックスコンテキストを引数として取って
いることに注意してください。これは `Graphics.Canvas`ではよくあるパター
ンです。

最後に、 `fillPath`アクションを使用して矩形を塗りつぶしています。
`fillPath`は次のような型を持っています。

```haskell
fillPath :: forall a. Context2D -> Effect a -> Effect a
```

`fillPath`はグラフィックスコンテキストと描画するパスを構築する別のアク
ションを引数にとります。パスは `rect`アクションを使うと構築することが
できます。 `rect`はグラフィックスコンテキストと矩形の位置及びサイズを
格納するレコードを引数にとります。

```haskell
{{#include ../exercises/chapter12/src/Example/Rectangle.purs:fillPath}}
```

mainモジュールの名前として`Example.Rectangle`を与えてこの長方形のコー
ド例をビルドしましょう。

```text
$ spago bundle-app --main Example.Rectangle --to dist/Main.js
```

それでは `html/index.html`ファイルを開き、このコードによってcanvasの中
央に青い四角形が描画されていることを確認してみましょう。

## 行多相を利用する

パスを描画する方法は他にもあります。 `arc`関数は円弧を描画します。
`moveTo`関数、 `lineTo`関数、 `closePath`関数は断片的な線分のパスを描
画するのに使えます。

`Shapes.purs`ファイルでは長方形と円弧と三角形の、3つの図形を描画してい
ます。

`rect`関数は引数としてレコードをとることを見てきました。実際には、長方
形のプロパティは型同義語で定義されています。

```haskell
type Rectangle =
  { x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  }
```

`x`と `y`プロパティは左上隅の位置を表しており、 `w`と `h`のプロパティ
はそれぞれ幅と高さを表しています。

`arc`関数に以下のような型を持つレコードを渡して呼び出すと、円弧を描画
することができます。

```haskell
type Arc =
  { x      :: Number
  , y      :: Number
  , radius :: Number
  , start  :: Number
  , end    :: Number
  }
```

ここで、 `x`と `y`プロパティは弧の中心、 `r`は半径、 `start`と `end`は
弧の両端の角度を弧度法で表しています。

例えばこのコードは中心が`(300, 300)`に中心があり半径`50`の円弧を塗り潰
します。弧は1回転のうち2/3 rds分あります。単位円が鉛直方向に反転するこ
とに注意してください。これはy軸がcanvasの下向きに増加するためです。

```haskell
  fillPath ctx $ arc ctx
    { x      : 300.0
    , y      : 300.0
    , radius : 50.0
    , start  : 0.0
    , end    : Math.tau * 2.0 / 3.0
    }
```

`Number`型の `x`と `y`というプロパティが `Rectangle`レコード型と
`Arc`レコード型の両方に含まれていることに注意してください。どちらの場
合でもこの組は点を表しています。これは、いずれのレコード型にも適用でき
る、行多相な関数を書くことができることを意味します。

たとえば、 `Shapes`モジュールでは `x`と `y`のプロパティを変更し図形を
並行移動する `translate`関数を定義されています。

```haskell
{{#include ../exercises/chapter12/src/Example/Shapes.purs:translate}}
```

この行多相型に注目してください。これは `triangle`が `x`と `y`というプ
ロパティと、**それに加えて他の任意のプロパティ**を持ったどんなレコード
でも受け入れ、同じ型のレコードを返すということを言っています。 `x`フィー
ルドと `y`フィールドは更新されますが、残りのフィールドは変更されません。

これは**レコード更新構文**の例です。 `shape { ... }`という式は、
`shape`を元にして、括弧の中で指定された値で更新されたフィールドを持つ
新たなレコードを作ります。波括弧の中の式はレコードリテラルのようなコロ
ンではなく、等号でラベルと式を区切って書くことに注意してください。

`Shapes`の例からわかるように、 `translate`関数は `Rectangle`レコードと
`Arc`レコード双方に対して使うことができます。

`Shape`の例で描画される3つめの型は区分からなる線分のパスです。対応する
コードは次のようになります。

```haskell
{{#include ../exercises/chapter12/src/Example/Shapes.purs:path}}
```

ここでは3つの関数が使われています。

- `moveTo`はパスの現在地を指定された座標に移動します。
- `lineTo`は現在地と指定された座標の間の線分を描画し、現在地を更新します。
- `closePath`は現在地と開始地点とを結ぶ線分を描画してパスを完結します。

このコード片の結果は二等辺三角形の塗り潰しです。

mainモジュールとして`Example.Shapes`を指定して、この例をビルドしましょう。

```text
$ spago bundle-app --main Example.Shapes --to dist/Main.js
```

そしてもう一度 `html/index.html`を開き、結果を確認してください。canvas
に3つの異なる図形が描画されるはずです。

## 演習

 1. （簡単）これまでの例のそれぞれについて、 `strokePath`関数や
    `setStrokeStyle`関数を使ってみましょう。
 1. （簡単）関数の引数の内部のdo記法ブロックにより、`fillPath`関数と
    `strokePath`関数を使って共通のスタイルを持つ複雑なパスを描画することが
    できます。同じ `fillPath`呼び出しで隣り合った2つの矩形を描画するように、
    `Rectangle`のコード例を変更してみてください。線分と円弧を組み合わせて
    を、円の扇形を描画してみてください。
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

    この関数は引数として `1`から `0`の間の `Number`をとり、 `Point`を
    返します。 `renderPath`関数を利用して関数 `f`のグラフを描くアクショ
    ンを書いてください。そのアクションは有限個の点を `f`からサンプリン
    グすることによって近似しなければなりません。

     関数 `f`を変更し、様々なパスが描画されることを確かめてください。

## 無作為に円を描く

`Example/Random.purs`ファイルには2種類の異なる副作用が混在した
`Effect`モナドを使う例が含まれています。1つは乱数生成で、もう1つは
canvasの操作です。この例では無作為に生成された円をキャンバスに100個描
画します。

`main`アクションはこれまでのようにグラフィックスコンテキストへの参照を
取得し、ストロークと塗りつぶしスタイルを設定します。

```haskell
{{#include ../exercises/chapter12/src/Example/Random.purs:style}}
```

次のコードでは `for_`アクションを使って `0`から `100`までの整数につい
て繰り返しをしています。

```haskell
{{#include ../exercises/chapter12/src/Example/Random.purs:for}}
```

それぞれの繰り返しではdo記法ブロックは`0`と`1`の間に分布する3つの乱数
を生成することから始まります。これらの数は `0`から `1`の間に無作為に分
布しており、それぞれ `x`座標、 `y`座標、半径 `r`を表しています。

```haskell
{{#include ../exercises/chapter12/src/Example/Random.purs:random}}
```

次のコードではそれぞれの円について、これらの変数に基づいて `Arc`を作成
し、最後に現在のスタイルに従って円弧の塗りつぶしと線描が行われます。

```haskell
{{#include ../exercises/chapter12/src/Example/Random.purs:path}}
```

mainモジュールとして`Example.Random`を指定して、この例をビルドしましょ
う。

```text
$ spago bundle-app --main Example.Random --to dist/Main.js
```

`html/index.html`を開いて、結果を確認してみましょう。

## 座標変換

キャンバスは簡単な図形を描画するだけのものではありません。キャンバスは
変換行列を扱うことができ、図形は描画の前に形状を変形してから描画されま
す。図形は平行移動、回転、拡大縮小、および斜めに変形することができます。

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

`translate`アクションは `TranslateTransform`レコードのプロパティで指定
した大きさだけ平行移動を行います。

`rotate`アクションは最初の引数で指定されたラジアンの値に応じて原点を中
心とした回転を行います。

`scale`アクションは原点を中心として拡大縮小します。 `ScaleTransform`レ
コードは `X`軸と `y`軸に沿った拡大率を指定するのに使います。

最後の `transform`はこの４つのうちで最も一般的なアクションです。このア
クションは行列に従ってアフィン変換を行います。

これらのアクションが呼び出された後に描画される図形は、自動的に適切な座
標変換が適用されます。

実際には、これらの関数のそれぞれの作用は、コンテキストの現在の変換行列
に対して変換行列を**右から乗算**していきます。つまり、もしある作用の変
換をしていくと、その作用は実際には逆順に適用されていきます：

```haskell
transformations ctx = do
  translate ctx { translateX: 10.0, translateY: 10.0 }
  scale ctx { scaleX: 2.0, scaleY: 2.0 }
  rotate ctx (Math.tau / 4.0)

  renderScene
```

この一連のアクションの作用では、まずシーンが回転され、それから拡大縮小
され、最後に平行移動されます。

## コンテキストの保存

変換を適用してシーンの一部を描画し、それからその変換を元に戻す、という
使い方はよくあります。

Canvas APIにはキャンバスの状態の**スタック**を操作する `save`と
`restore`メソッドが備わっています。 `canvas`ではこの機能を次のような関
数でラップしています。

```haskell
save
  :: Context2D
  -> Effect Context2D

restore
  :: Context2D
  -> Effect Context2D
```

`save`アクションは現在のコンテキストの状態（現在の変換行列や描画スタイ
ル）をスタックにプッシュし、 `restore`アクションはスタックの一番上の状
態をポップし、コンテキストの状態を復元します。

これらのアクションにより、現在の状態を保存し、いろいろなスタイルや変換
を適用し、原始的な図形を描画し、最後に元の変換と状態を復元することが可
能になります。例えば、次の関数はいくつかのキャンバスアクションを実行し
ますが、その前に回転を適用し、そのあとに変換を復元します。

```haskell
rotated ctx render = do
  save ctx
  rotate (Math.tau / 3.0) ctx
  render
  restore ctx
```

こういったよくある使いかたの高階関数を利用した抽象化として、
`canvas`ライブラリでは元のコンテキスト状態を保存しつついくつかのキャン
バスアクションを実行する `withContext`関数が提供されています。

```haskell
withContext
  :: Context2D
  -> Effect a
  -> Effect a
```

`withContext`を使うと、先ほどの `rotated`関数を次のように書き換えるこ
とができます。

```haskell
rotated ctx render =
  withContext ctx do
    rotate (Math.tau / 3.0) ctx
    render
```

## 大域的な変更可能状態

この節では `refs`パッケージを使って `Effect`モナドの別の作用について実
演してみます。

`Effect.Ref`モジュールでは大域的に変更可能な参照のための型構築子、およ
び関連する作用を提供します。

```text
> import Effect.Ref

> :kind Ref
Type -> Type
```

型`Ref a`の値は型`a`の値を含む可変参照セルであり、大域的な変更を追跡す
るのに使われます。そういったわけでこれは少しだけ使う分に留めておくべき
です。

`Example/Refs.purs`ファイルには `canvas`要素上のマウスクリックを追跡す
るのに `Ref`作用を使用する例が含まれています。

このコー​​ドでは最初に `new`アクションを使って値 `0`を含む新しい参照を作
成しています。

```haskell
{{#include ../exercises/chapter12/src/Example/Refs.purs:clickCount}}
```

クリックイベントハンドラの内部では、 `modify`アクションを使用してクリッ
ク数を更新し、更新された値が返されています。

```haskell
{{#include ../exercises/chapter12/src/Example/Refs.purs:count}}
```

`render`関数では、クリック数に応じて変換を矩形に適用しています。

```haskell
{{#include ../exercises/chapter12/src/Example/Refs.purs:withContext}}
```

このアクションでは元の変換を保存するために `withContext`を使用しており、
それから一連の変換を適用しています（変換が下から上に適用されることを思
い出してください）。

- 矩形は`(-100, -100)`だけ平行移動し中心が原点に来ます。
- 矩形が原点を中心に拡大されます。
- 矩形が原点を中心に`10`の倍数分の角度で回転します。
- 矩形が`(300, 300)`だけ平行移動し中心がcanvasの中心に来ます。

このコード例をビルドしてみましょう。

```text
$ spago bundle-app --main Example.Refs --to dist/Main.js
```

`html/index.html`ファイルを開いてみましょう。何度かキャンバスをクリッ
クすると、キャンバスの中心の周りを回転する緑の四角形が表示されるはずで
す。

## 演習

 1. （簡単）パスの線描と塗り潰しを同時に行う高階関数を書いてください。その
    関数を使用して `Random.purs`例を書き直してください。
 1. （普通）`Random`作用と `Dom`作用を使用して、マウスがクリックされたとき
    に、キャンバスに無作為な位置、色、半径の円を描画するアプリケーションを
    作成してください。
 1. （普通）シーンを指定された座標を中心に回転する関数を書いてください。
    **ヒント**：最初にシーンを原点まで平行移動しましょう。

## L-System

この章の最後の例として、 `canvas`パッケージを使用して**L-system**
(Lindenmayer system) を描画する関数を記述します。

L-Systemは**アルファベット**、つまり初期状態となるアルファベットの文
字列と、**生成規則**の集合で定義されています。各生成規則は、アルファベッ
トの文字をとり、それを置き換える文字の配列を返します。この処理は文字の
初期配列から始まり、複数回繰り返されます。

もしアルファベットの各文字がcanvas上で実行される命令と対応付けられてい
れば、その指示に順番に従うことでL-Systemを描画することができます。

たとえば、アルファベットが文字 `L`（左回転）、 `R`（右回転）、 `F`（前
進）で構成されていたとします。また、次のような生成規則を定義します。

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

この命令群に対応する線分パスをプロットすると、**コッホ曲線**と呼ばれる
曲線に近似します。反復回数を増やすと、曲線の解像度が増加していきます。

それでは型と関数の言語へとこれを翻訳してみましょう。

アルファベットの文字は以下のADTで表現できます。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:letter}}
```

このデータ型では、アルファベットの文字ごとに１つずつデータ構築子が定義
されています。

文字の初期配列はどのように表したらいいでしょうか。単なるアルファベット
の配列でいいでしょう。これを `Sentence`と呼ぶことにします。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:sentence}}

{{#include ../exercises/chapter12/src/Example/LSystem.purs:initial}}
```

生成規則は以下のように`Letter`から `Sentence`への関数として表すことができます。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:productions}}
```

これはまさに上記の仕様をそのまま書き写したものです。

これで、この形式の仕様を受け取りcanvasに描画する関数 `lsystem`を実装す
ることができます。 `lsystem`はどのような型を持っているべきでしょうか。
この関数は初期状態 `initial`と生成規則 `productions`のような値だけでな
く、アルファベットの文字をcanvasに描画する関数を引数に取る必要があ
ります。

`lsystem`の型の最初の大まかな設計は以下です。

```haskell
Sentence
-> (Letter -> Sentence)
-> (Letter -> Effect Unit)
-> Int
-> Effect Unit
```

最初の2つの引数の型は、値 `initial`と `productions`に対応しています。

3番目の引数は、アルファベットの文字を取り、canvas上のいくつかのアクショ
ンを実行することによって**翻訳**する関数を表します。この例では、文字
`L`は左回転、文字 `R`で右回転、文字 `F`は前進を意味します。

最後の引数は、実行したい生成規則の繰り返し回数を表す数です。

最初に気付くことは、この`lsystem`関数は1つの型`Letter`に対してのみ動作
するのですが、どんなアルファベットについても機能すべきですから、この型
はもっと一般化されるべきです。それでは、量子化された型変数 `a`について、
`Letter`と `Sentence`を `a`と `Array a`で置き換えましょう。

```haskell
forall a. Array a
          -> (a -> Array a)
          -> (a -> Effect Unit)
          -> Int
          -> Effect Unit
```

次に気付くこととしては、「左回転」と「右回転」のような命令を実装するた
めには、いくつかの状態を管理する必要があります。具体的に言えば、その時
点でパスが向いている方向を状態として持たなければなりません。計算を通じ
て状態を関数に渡すように変更する必要があります。ここでも `lsystem`関数
は状態がどんな型でも動作したほうがよいので、型変数 `s`を使用してそれを
表しています。

型 `s`を追加する必要があるのは3箇所で、次のようになります。

```haskell
forall a s. Array a
            -> (a -> Array a)
            -> (s -> a -> Effect s)
            -> Int
            -> s
            -> Effect s
```

まず追加の引数の型として `lsystem`に型 `s`が追加されています。この引数
はL-Systemの初期状態を表しています。

型 `s`は引数にも現れますが、翻訳関数（`lsystem`の第3引数）の返り値の型と
しても現れます。翻訳関数は今のところ、引数としてL-Systemの現在の状態を
受け取り、返り値として更新された新しい状態を返します。

この例の場合では、次のような型を使って状態を表す型を定義することができ
ます。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:state}}
```

プロパティ `x`と `y`はパスの現在の位置を表しており、プロパティ
`theta`はパスの現在の向きを表しています。これはラジアンで表された水平
線に対するパスの角度として指定されています。

システムの初期状態としては次のように指定されます。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:initialState}}
```

それでは、 `lsystem`関数を実装してみます。定義はとても単純であることが
わかるでしょう。

`lsystem`は第４引数の値（型 `Int`）に応じて再帰するのが良さそうです。
再帰の各ステップでは、生成規則に従って状態が更新され、現在の文が変化し
ていきます。このことを念頭に置きつつ、まずは関数の引数の名前を導入して、
補助関数に処理を移譲することから始めましょう。

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

`go`関数は第2引数に応じて再帰することで動きます。場合分けは2つであり、
`n`がゼロであるときと `n`がゼロでないときです。

1つ目の場合は再帰は完了し、翻訳関数に応じて現在の文を翻訳します。型
`Array a`の文、型 `s`の状態、型 `s -> a -> Effect s`の関数があります。
以前定義した `foldM`でやったことのように聞こえます。この関数は
`control`パッケージで手に入ります。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:lsystem_go_s_0}}
```

ゼロでない場合ではどうでしょうか。その場合は、単に生成規則を現在の文の
それぞれの文字に適用して、その結果を連結し、そして再帰的に`go`を呼び出
すことによって繰り返します。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:lsystem_go_s_i}}
```

これだけです！`foldM`や `concatMap`のような高階関数を使うと、このよう
にアイデアを簡潔に表現することができるのです。

しかし、話はこれで終わりではありません。ここで与えた型は、実際はまだ特
殊化されすぎています。この定義ではcanvasの操作が実装のどこにも使われて
いないことに注目してください。それに、まったく `Effecta`モナドの構造を
利用していません。実際には、この関数は**どんな**モナド `m`についても動
作するのです！

この章に添付されたソースコードで指定されている、 `lsystem`のもっと一般
的な型は次のようになっています。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:lsystem_anno}}
```

この型が言っているのは、この翻訳関数はモナド `m`が持つ任意の副作用をまっ
たく自由に持つことができる、ということだと理解することができます。キャ
ンバスに描画したり、またはコンソールに情報を出力するかもしれませんし、
失敗や複数の戻り値に対応しているかもしれません。こういった様々な型の副
作用を使ったL-Systemを記述してみることを読者にお勧めします。

この関数は実装からデータを分離することの威力を示す良い例となっています。
この手法の利点は、複数の異なる方法でデータを解釈する自由が得られること
です。 `lsystem`は2つの小さな関数へと分解することさえできるかもしれま
せん。1つ目は `concatMap`の適用の繰り返しを使って文を構築するもので、2
つ目は `foldM`を使って文を翻訳するものです。これは読者の演習として残し
ておきます。

それでは翻訳関数を実装して、この章の例を完成させましょう​​。 `lsystem`の
型は型シグネチャが言っているのは、翻訳関数の型は、何らかの型 `a`と `s`、
型構築子 `m`について、 `s -> a -> m s`でなければならないということです。
`a`を `Letter`、 `s`を `State`、モナド `m`を `Effect`というように選び
たいということがわかっています。これにより次のような型になります。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:interpret_anno}}
```

この関数を実装するには、 `Letter`型の3つのデータ構築子それぞれについて
処理する必要があります。文字 `L`（左回転）と `R`（右回転）の翻訳では、
`theta`を適切な角度へ変更するように状態を更新するだけです。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:interpretLR}}
```

文字 `F`（前進）を翻訳するには、パスの新しい位置を計算し、線分を描画し、
状態を次のように更新します。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:interpretF}}
```

この章のソースコードでは、名前 `ctx`がスコープ内に来るように、
`interpret`関数は `main`関数内で `let`束縛を使用して定義されていること
に注意してください。 `State`型がコンテキストを持つように変更することは
可能でしょうが、それはこのシステムの状態の変化部分ではないので不適切で
しょう。

このL-Systemを描画するには、次のような `strokePath`アクションを使用するだけです。

```haskell
{{#include ../exercises/chapter12/src/Example/LSystem.purs:strokePath}}
```

次のコマンドを使ってL-Systemをコンパイルします。

```text
$ spago bundle-app --main Example.LSystem --to dist/Main.js
```

`html/index.html`を開いてみましょう。キャンバスにコッホ曲線が描画され
るのがわかると思います。

## 演習

 1. （簡単）`strokePath`の代わりに `fillPath`を使用するように、上の
    L-Systemの例を変更してください。**ヒント**：`closePath`の呼び出しを含
    め、 `moveTo`の呼び出しを `interpret`関数の外側に移動する必要がありま
    す。
 1. （簡単）描画システムへの影響を理解するために、コード中の様々な数値の定
    数を変更してみてください。
 1. （普通）`lsystem`関数を2つの小さな関数に分割してください。1つ目は
    `concatMap`の適用の繰り返しを使用して最終的な文を構築するもので、2つ目
    は `foldM`を使用して結果を解釈するものでなくてはなりません。
 1. （普通）`setShadowOffsetX`アクション、 `setShadowOffsetY`アクション、
    `setShadowBlur`アクション、 `setShadowColor`アクションを使い、塗りつぶ
    された図形にドロップシャドウを追加してください。**ヒント**：PSCiを使っ
    て、これらの関数の型を調べてみましょう。
 1. （普通）向きを変えるときの角度の大きさは今のところ一定 (`tau/6`) です。
    その代わりに、`Letter`データ型の中に角度を移動させることで、生成規則に
    よって変更するようにしてください。

     ```haskell
     type Angle = Number

     data Letter = L Angle | R Angle | F
     ```

     生成規則でこの新しい情報を使うと、どんな面白い図形を作ることがで
きるでしょうか。
1. （難しい）`L`（60度左回転）、 `R`（60度右回転）、
   `F`（前進）、 `M`（これも前進）という4つの文字からなるアルファベット
   でL-Systemが与えられたとします。

     このシステムの文の初期状態は、単一の文字 `M`です。

     このシステムの生成規則は次のように指定されています。

     ```text
     L -> L
     R -> R
     F -> FLMLFRMRFRMRFLMLF
     M -> MRFRMLFLMLFLMRFRM
     ```

     このL-Systemを描画してください。**注意**：最後の文のサイズは反復
     回数に従って指数関数的に増大するので、生成規則の繰り返しの回数を
     削減することが必要になります。

     ここで、生成規則における `L`と `M`の間の対称性に注目してください。
     ふたつの「前進」命令は、次のようなアルファベット型を使用すると、
     `Boolean`値を使って区別することができます。

     ```haskell
     data Letter = L | R | F Boolean
     ```

    このアルファベットの表現を使用して、もう一度このL-Systemを実装して
    ください。
1. （難しい）翻訳関数で別のモナド `m`を使ってみましょう。
   `Effect.Console`作用を利用してコンソール上にL-Systemを出力したり、
   `Random`作用を利用して状態の型に無作為の「突然変異」を適用したりしてみてください。

## まとめ

この章では、 `canvas`ライブラリを使用することにより、PureScriptから
HTML5 Canvas APIを使う方法について学びました。また、これまで学んできた
手法の多くを利用した実用的な例について見ました。マップや畳み込み、レコー
ドと行多相、副作用を扱うための `Effect`モナドなどです。

この章の例では、高階関数の威力を示すとともに、**実装からのデータの分離**
も実演してみせました。これは例えば、代数データ型を使用してこれらの概
念を次のように拡張し、描画関数からシーンの表現を完全に分離できるように
なります。

```haskell
data Scene
  = Rect Rectangle
  | Arc Arc
  | PiecewiseLinear (Array Point)
  | Transformed Transform Scene
  | Clipped Rectangle Scene
  | ...
```

この手法は `drawing`パッケージでも採用されており、描画前にさまざまな方
法でデータとしてシーンを操作することができるという柔軟性をもたらしてい
ます。

canvasに描画されるゲームの例については
[cookbook](https://github.com/JordanMartinez/purescript-cookbook/blob/master/README.md#recipes)
の「Behavior」と「Signal」のレシピを見てください。

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