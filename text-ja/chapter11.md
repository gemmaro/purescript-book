# モナドな冒険

## この章の目標

この章の目標は*モナド変換子*について学ぶことです。
モナド変換子は異なるモナドから提供された副作用を合成する方法を提供します。
動機付けとする例は、NodeJSのコンソール上で遊ぶことができるテキストアドベンチャーゲームです。
ゲームの様々な副作用（ロギング、状態、及び構成）が全てモナド変換子スタックによって提供されます。

## プロジェクトの準備

このモジュールのプロジェクトでは以下の新しい依存関係が導入されます。

- `ordered-collections` は不変のマップと集合のためのデータ型を提供します
- `transformers` は標準的なモナド変換子の実装を提供します
- `node-readline`はNodeJSが提供する[`readline`](http://nodejs.org/api/readline.html)インターフェイスへのFFIバインディングを提供します
- `optparse`はコマンドライン引数を処理するアプリカティブ構文解析器を提供します

## ゲームの遊びかた

プロジェクトを走らせるには`spago run`を使います。

既定では使い方の文言が表示されます。

```text
Monadic Adventures! A game to learn monad transformers

Usage: run.js (-p|--player <player name>) [-d|--debug]
  Play the game as <player name>

Available options:
  -p,--player <player name>
                           The player's name <String>
  -d,--debug               Use debug mode
  -h,--help                Show this help text
```

コマンドライン引数を与えるためには、追加の引数を直接アプリケーションに渡す`-a`オプション付きで`spago run`を呼び出すか、`spago
bundle-app`とすればよいです。
2つ目の方法では`node`で直接走らせられるindex.jsファイルが作られます。

例えば`-p`オプションを使ってプレイヤー名を与えるには次のようにします。

```text
$ spago run -a "-p Phil"
>
```

```text
$ spago bundle-app 
$ node index.js -p Phil
>
```

プロンプトからは、`look`、`inventory`、`take`、`use`、`north`、`south`、`east`、`west`などのコマンドを入力できます。
`debug`コマンドもあり、`--debug`コマンドラインオプションを与えられていた場合に、ゲームの状態を出力できます。

ゲームは2次元の碁盤の目の上が舞台で、コマンド`north`、`south`、`east`、`west`を発行することによってプレイヤーが移動します。
ゲームにはアイテムの集まりがあり、プレイヤーの所有物であったり、ゲームの盤上の特定の位置にあったりします。
`take`コマンドを使うと、プレイヤーはアイテムを拾い上げられます。

参考までに、このゲームのひと通りの流れは次のようになります。

```text
$ spago run -a "-p Phil"

> look
You are at (0, 0)
You are in a dark forest. You see a path to the north.
You can see the Matches.

> take Matches
You now have the Matches

> north
> look
You are at (0, 1)
You are in a clearing.
You can see the Candle.

> take Candle
You now have the Candle

> inventory
You have the Candle.
You have the Matches.

> use Matches
You light the candle.
Congratulations, Phil!
You win!
```

このゲームはとても単純ですが、この章の目的は`transformers`パッケージを使用してこのような種類のゲームを素早く開発できるようにするライブラリを構築することです。

## Stateモナド

`transformers`パッケージで提供されている幾つかのモナドを眺めることから始めましょう。

最初の例は`State`モナドです。
これは純粋なコードで*変更可能状態*をモデル化する手段を提供します。
既に`Effect`モナドによって提供される変更可能状態の手法について見てきました。
`State`はその代替を提供します。

`State`型構築子は、状態の型`s`、及び返り値の型`a`という2種類の引数を取ります。
「`State`モナド」というように説明はしていますが、実際には`Monad`型クラスのインスタンスが任意の型`s`についての`State
s`型構築子に対して提供されています。

`Control.Monad.State`モジュールは以下のAPIを提供しています。

```haskell
get     :: forall s.             State s s
gets    :: forall s. (s -> a) -> State s a
put     :: forall s. s        -> State s Unit
modify  :: forall s. (s -> s) -> State s s
modify_ :: forall s. (s -> s) -> State s Unit
```

なお、ここではこれらのAPIシグネチャは`State`型構築子を使った、単純化された形式で表されています。
実際のAPIは本章の後にある「型クラス」節で押さえる`MonadState`が関わってきます。
ですからIDEのツールチップやPursuitで違うシグネチャを見たとしても心配しないでください。

例を見てみましょう。
`State`モナドの使い方の1つとしては、整数の配列中の値を現在の状態に加えるものが考えられます。
状態の型`s`として`Int`を選択し、配列の走査に`traverse_`を使い、配列の各要素について`modify`を呼び出すと、これを実現できます。

```haskell
import Data.Foldable (traverse_)
import Control.Monad.State
import Control.Monad.State.Class

sumArray :: Array Int -> State Int Unit
sumArray = traverse_ \n -> modify \sum -> sum + n
```

`Control.Monad.State`モジュールは、`State`モナドで計算するための次の3つの関数を提供します。

```haskell
evalState :: forall s a. State s a -> s -> a
execState :: forall s a. State s a -> s -> s
runState  :: forall s a. State s a -> s -> Tuple a s
```

3つの各関数は型`s`の初期状態と型`State s a`の計算を引数に取ります。
`evalState`は返り値だけを返し、`execState`は最終的な状態だけを返し、`runState`は`Tuple a
s`型の値として表現された両方を返します。

先ほどの `sumArray`関数が与えられているとき、PSCiで `execState`を使うと次のように複数の配列内の数字を合計できます。

```text
> :paste
… execState (do
…   sumArray [1, 2, 3]
…   sumArray [4, 5]
…   sumArray [6]) 0
… ^D
21
```

## 演習

 1. （簡単）上の例で、`execState`を`runState`や`evalState`で置き換えると結果はどうなるでしょうか。
 1. （普通）括弧からなる文字列が*平衡している*のは、0個以上のより短い平衡した文字列を連結したものか、より短い平衡した文字列を一対の括弧で囲んだものかの何れかです。

    `State`モナドと `traverse_`関数を使用して、次のような関数を書いてください。

     ```haskell
     testParens :: String -> Boolean
     ```

     これは、まだ閉じられていない開括弧の数を把握することで、括弧の`String`が平衡しているかどうかを調べる関数です。
     この関数は次のように動作します。

     ```text
     > testParens ""
     true

     > testParens "(()(())())"
     true

     > testParens ")"
     false

     > testParens "(()()"
     false
     ```

     *手掛かり*：入力の文字列を文字の配列に変換するのに、`Data.String.CodeUnits`モジュールの `toCharArray`関数を使うと良いでしょう。

## Readerモナド

`transformers`パッケージでは `Reader`というモナドも提供されています。
このモナドは大域的な設定を読み取る機能を提供します。
`State`モナドが1つの可変状態を読み書きする機能を提供するのに対し、 `Reader`モナドは1つのデータの読み取り機能だけを提供します。

`Reader`型構築子は、設定の型を表す型 `r`、及び戻り値の型 `a`の2つの型引数を取ります。

`Control.Monad.Reader`モジュールは以下のAPIを提供します。

```haskell
ask   :: forall r. Reader r r
local :: forall r a. (r -> r) -> Reader r a -> Reader r a
```

`ask`動作は現在の設定を読み取るために使い、`local`動作は変更された設定で計算するために使います。

例えば、権限で制御するアプリケーションを開発しており、現在の利用者の権限オブジェクトを保持するのに `Reader`モナドを使いたいとしましょう。
型 `r`を次のようなAPIを備えた型 `Permission`として選択できます。

```haskell
hasPermission :: String -> Permissions -> Boolean
addPermission :: String -> Permissions -> Permissions
```

利用者が特定の権限を持っているかどうかを確認したいときは、 `ask`を使って現在の権限オブジェクトを取得すればいつでも調べることができます。
例えば管理者だけが新しい利用者の作成を許可されているとしましょう。

```haskell
createUser :: Reader Permissions (Maybe User)
createUser = do
  permissions <- ask
  if hasPermission "admin" permissions
    then map Just newUser
    else pure Nothing
```

`local`動作を使うと、計算の実行中に `Permissions`オブジェクトを変更し、ユーザーの権限を昇格させることもできます。

```haskell
runAsAdmin :: forall a. Reader Permissions a -> Reader Permissions a
runAsAdmin = local (addPermission "admin")
```

こうすると、利用者が `admin`権限を持っていなかった場合であっても新しい利用者を作成できるような関数を書くことができます。

```haskell
createUserAsAdmin :: Reader Permissions (Maybe User)
createUserAsAdmin = runAsAdmin createUser
```

`Reader`モナドを計算するには、大域的な設定を与える`runReader`関数を使います。

```haskell
runReader :: forall r a. Reader r a -> r -> a
```

## 演習

以下の演習では、 `Reader`モナドを使って、字下げのついた文書を出力するための小さなライブラリを作っていきます。
「大域的な設定」は、現在の字下げの深さを示す数になります。

```haskell
type Level = Int

type Doc = Reader Level String
```

 1. （簡単）現在の字下げの深さで関数を書き出す関数`line`を書いてください。
    関数は以下の型を持ちます。

     ```haskell
     line :: String -> Doc
     ```

     *手掛かり*：現在の字下げの深さを読み取るためには `ask`関数を使用します。
     `Data.Monoid`の`power`関数も役に立つかもしれません。
1. （普通）`local`関数を使用して次の関数を書いてください。

     ```haskell
     indent :: Doc -> Doc
     ```

     この関数はコードブロックの字下げを深くします。
1. （普通）`Data.Traversable`で定義された `sequence`関数を使用して、次の関数を書いてください。

     ```haskell
     cat :: Array Doc -> Doc
     ```

     この関数は文書の集まりを改行で区切って連結します。
1. （普通）`runReader`関数を使用して次の関数を書いてください。

     ```haskell
     render :: Doc -> String
     ```

     この関数は文書を文字列として出力します。

 これでライブラリを使って以下のような単純な文書を書けるようになりました。

 ```haskell
 render $ cat
   [ line "Here is some indented text:"
   , indent $ cat
       [ line "I am indented"
       , line "So am I"
       , indent $ line "I am even more indented"
       ]
   ]
 ```

## Writerモナド

`Writer`モナドでは、計算の返り値に加えてもう1つの値を累算できます。

よくある使い方としては型`String`もしくは`Array
String`でログを累算していくというものなどがありますが、`Writer`モナドはこれよりもっと一般的なものです。
累算するのに任意のモノイドの値を使うことができるので、`Additive Int`モノイドを使って整数の合計を追跡するのに使ったり、`Disj
Boolean`モノイドを使って途中の`Boolean`値の何れかが真であるかどうかを追跡するのに使えます。

`Writer`型構築子は2つの型引数を取ります。
`Monoid`型クラスのインスタンスである型`w`と返り値の型`a`です。

`Writer`のAPIで重要なのは `tell`関数です。

```haskell
tell :: forall w a. Monoid w => w -> Writer w Unit
```

`tell`動作は与えられた値を現在の累算結果に付け加えます。

例として、`Array String`モノイドを使用して、既存の関数にログを追加してみましょう。
*最大公約数*関数の以前の実装を考えてみます。

```haskell
gcd :: Int -> Int -> Int
gcd n 0 = n
gcd 0 m = m
gcd n m = if n > m
            then gcd (n - m) m
            else gcd n (m - n)
```

`Writer (Array String) Int`へと返り値の型を変更することで、この関数にログ機能を追加できます。

```haskell
import Control.Monad.Writer
import Control.Monad.Writer.Class

gcdLog :: Int -> Int -> Writer (Array String) Int
```

各手順での2つの入力を記録するためには、少し関数を変更する必要があります。

```haskell
    gcdLog n 0 = pure n
    gcdLog 0 m = pure m
    gcdLog n m = do
      tell ["gcdLog " <> show n <> " " <> show m]
      if n > m
        then gcdLog (n - m) m
        else gcdLog n (m - n)
```

`Writer`モナドを計算するには、`execWriter`関数または`runWriter`関数の何れかを使います。

```haskell
execWriter :: forall w a. Writer w a -> w
runWriter  :: forall w a. Writer w a -> Tuple a w
```

ちょうど `State`モナドの場合と同じように、 `execWriter`が累算されたログだけを返すのに対して、
`runWriter`は累算されたログと結果の両方を返します。

PSCiで改変した関数を試してみましょう。

```text
> import Control.Monad.Writer
> import Control.Monad.Writer.Class

> runWriter (gcdLog 21 15)
Tuple 3 ["gcdLog 21 15","gcdLog 6 15","gcdLog 6 9","gcdLog 6 3","gcdLog 3 3"]
```

## 演習

 1. （普通）`Writer`モナドと `monoid`パッケージの `Additive Int`モノイドを使うように、上の
    `sumArray`関数を書き換えてください。
 1. （普通）*コラッツ*関数は自然数 \\( n \\) 上で定義され、 \\( n \\) が偶数なら \\( n / 2 \\)、 \\( n
    \\) が奇数なら \\( 3 n + 1 \\)です。
    例えば \\( 10 \\) で始まるコラッツ数列は以下です。

     ```text
     10, 5, 16, 8, 4, 2, 1, ...
     ```

     コラッツ関数の有限回の適用を繰り返すと、コラッツ数列は必ず最終的に  \\( 1 \\) になるということが予想されています。

     再帰を使い、数列が \\( 1 \\) に到達するまでに何回のコラッツ関数の適用が必要かを計算する関数を書いてください。

     `Writer`モナドを使用してコラッツ関数の各適用の経過を記録するように、関数を変更してください。

## モナド変換子

上の3つのモナド、`State`、`Reader`、`Writer`は、何れもいわゆる*モナド変換子*の例となっています。
対応する各モナド変換子はそれぞれ`StateT`、`ReaderT`、`WriterT`という名前です。

モナド変換子とは何でしょうか。
さて、これまで見てきたように、モナドはPureScriptのコードを何らかの種類の副作用で拡張するものでした。
このモナドはPureScriptで適切な制御子（`runState`、 `runReader`、`runWriter`など）を使って解釈できます。
使用する必要がある副作用が*1つだけ*なら、これで問題ありません。
しかし、同時に複数の副作用を使用できると便利なことがよくあります。
例えば、 `Maybe`と`Reader`を一緒に使用すると、ある大域的な設定の文脈で*省略可能な結果*を表現できます。
もしくは、 `Either`モナドの純粋なエラー追跡機能と、 `State`モナドが提供する変更可能な状態が同時に欲しくなるかもしれません。
この問題を解決するのが*モナド変換子*です。

ただし`Effect`モナドがこの問題を部分的に解決することは既に見ました。
モナド変換子はまた違った解決策を提供しますが、これらの各手法には利点と制約があります。

モナド変換子は型と別の型構築子を引数に取る型構築子です。
モナドを1つ取り、独自の様々な副作用を追加した別のモナドへと変換します。

例を見てみましょう。`State`のモナド変換子版は`Control.Monad.State.Trans`モジュールで定義されている`StateT`です。
PSCiを使って `StateT`の種を見てみましょう。

```text
> import Control.Monad.State.Trans
> :kind StateT
Type -> (Type -> Type) -> Type -> Type
```

とても読みにくそうに見えるかもしれませんが、使い方を理解するために、`StateT`に1つ引数を与えてみましょう。

`State`の場合、最初の型引数は使いたい状態の型です。
それでは型`String`を与えてみましょう。

```text
> :kind StateT String
(Type -> Type) -> Type -> Type
```

次の引数は種 `Type -> Type`の型構築子です。
これは `StateT`の機能を追加したい元のモナドを表します。
例として、 `Either String`モナドを選んでみます。

```text
> :kind StateT String (Either String)
Type -> Type
```

型構築子が残りました。
最後の引数は戻り値の型を表しており、例えばそれを`Number`にできます。

```text
> :kind StateT String (Either String) Number
Type
```

最後に種`Type`の何かが残りました。
つまりこの型の値を探してみることができます。

構築したモナド`StateT String (Either String)`は、エラーで失敗する可能性があり、変更可能な状態を使える計算を表しています。

外側の`StateT String`モナドの動作（`get`、`put`、`modify`）は直接使えますが、梱包されているモナド (`Either
String`) の作用を使うためには、これらの関数をモナド変換子まで「持ち上げ」る必要があります。
`Control.Monad.Trans`モジュールは`MonadTrans`型クラスを定義しています。
これはモナド変換子であるそうした型構築子を捕捉します。

```haskell
class MonadTrans t where
  lift :: forall m a. Monad m => m a -> t m a
```

このクラスは単一のメンバー`lift`を含みます。
これは通底する任意のモナド`m`の計算を取り、梱包されたモナド`t m`へと持ち上げるものです。
今回の場合、型構築子`t`は`StateT String`で、`m`は`Either String`モナドとなるので、`lift`は型`Either
String a`の計算を、型`StateT String (Either String) a`の計算へと持ち上げる方法を提供することになります。
つまり、型`Either String a`の計算を使う場合に毎回`lift`を使うのであれば、`StateT String`と`Either
String`の作用を使えます。

例えば、次の計算は通底する状態を読み、状態が空文字列であればエラーを投げます。

```haskell
import Data.String (drop, take)

split :: StateT String (Either String) String
split = do
  s <- get
  case s of
    "" -> lift $ Left "Empty string"
    _ -> do
      put (drop 1 s)
      pure (take 1 s)
```

状態が空でなければ、この計算は`put`を使って状態を`drop 1 s`（つまり`s`から最初の文字を取り除いたもの）へと更新し、`take 1
s`（`s`の最初の文字）を返します。

それではPSCiでこれを試してみましょう。

```text
> runStateT split "test"
Right (Tuple "t" "est")

> runStateT split ""
Left "Empty string"
```

これは`StateT`を使わなくても実装できるので、さほど驚くようなことはありません。
しかし、モナドの中で扱っているので、do記法やアプリカティブコンビネータを使って、小さな計算から大きな計算を構築できます。
例えば、2回`split`を適用すると、文字列から最初の2文字を読めます。

```text
> runStateT ((<>) <$> split <*> split) "test"
(Right (Tuple "te" "st"))
```

`split`関数とその他沢山の動作を使えば基本的な構文解析ライブラリを構築できます。
実際、これは`parsing`ライブラリで採用されている手法です。
これがモナド変換子の力なのです。
必要な副作用を選択し、do記法とアプリカティブコンビネータで表現力を維持しながら、様々な問題のための特注のモナドを作成できるのです。

## ExceptTモナド変換子

`transformers`パッケージでは`ExceptT e`モナド変換子も定義されています。
これは`Either e`モナドに対応するもので、以下のAPIを提供します。

```haskell
class MonadError e m where
  throwError :: forall a. e -> m a
  catchError :: forall a. m a -> (e -> m a) -> m a

instance Monad m => MonadError e (ExceptT e m)

runExceptT :: forall e m a. ExceptT e m a -> m (Either e a)
```

`MonadError`クラスは`e`型のエラーを投げたり捕えたりに対応するモナドを捕捉し、`ExceptT
e`モナド変換子のインスタンスが提供されます。
`Either e`モナドの`Left`と同じように、`throwError`動作では失敗を示せます。
`catchError`動作では`throwError`を使ってエラーが投げられた後に処理を継続できます。

`runExceptT`制御子を使うと、型 `ExceptT e m a`を計算できます。

このAPIは `exceptions`パッケージの `Exception`作用によって提供されているものと似ています。
しかし、幾つかの重要な違いがあります。

- `Exception`が実際のJavaScriptの例外を使っているのに対して`ExceptT`モデルは代数的データ型を使っています。
- `Exception`作用がJavaScriptの`Error`型という1つの例外の型だけを扱うのに対して、`ExceptT`は`Error`型クラスのどんな型のエラーでも扱います。つまり、
  `ExceptT`では新たなエラー型を自由に定義できます。

試しに`ExceptT`を使って`Writer`モナドを包んでみましょう。
ここでもモナド変換子`ExceptT e`の動作を直接使うことも自由にできますが、`Writer`モナドの計算は`lift`を使って持ち上げるべきです。

```haskell
import Control.Monad.Except
import Control.Monad.Writer

writerAndExceptT :: ExceptT String (Writer (Array String)) String
writerAndExceptT = do
  lift $ tell ["Before the error"]
  _ <- throwError "Error!"
  lift $ tell ["After the error"]
  pure "Return value"
```

PSCiでこの関数を試すと、ログの蓄積とエラーの送出という2つの作用がどのように相互作用しているのかを見ることができます。
まず、 `runExceptT`を使って外側の`ExceptT`を計算し、型 `Writer (Array String) (Either String
String)`の結果を残します。
それから、 `runWriter`で内側の`Writer`を計算します。

```text
> runWriter $ runExceptT writerAndExceptT
Tuple (Left "Error!") ["Before the error"]
```

なお、エラーが投げられる前に書き出されるログ文言だけがログに追記されます。

## モナド変換子スタック

これまで見てきたように、モナド変換子を使って既存のモナドを土台に新しいモナドを構築できます。
何かのモナド変換子`t1`とモナド`m`について、その適用`t1 m`もまたモナドになります。
つまり、*2つめの*モナド変換子`t2`を結果`t1 m`に適用すると、3つ目のモナド`t2 (t1 m)`を作れます。
このようにしてモナド変換子の*スタック*を構築できます。
これは構成されるモナドによって提供される副作用を組み合わせるものです。

実際には、通底するモナド`m`は、ネイティブの副作用が必要なら`Effect`モナド、さもなくば`Data.Identity`モジュールで定義されている`Identity`モナドになります。
`Identity`モナドは何の新しい副作用も追加しませんから、`Identity`モナドの変換はモナド変換子の作用だけを提供します。
`State`、`Reader`、`Writer`モナドは、`Identity`モナドをそれぞれ`StateT`、`ReaderT`、`WriterT`で変換することによって実装されています。

3つの副作用が組み合わっている例を見てみましょう。
`Identity`モナドをスタックの底にして、`StateT`、`WriterT`、`ExceptT`作用を使います。
このモナド変換子スタックは、可変状態、ログの蓄積、そして純粋なエラーの副作用を提供します。

このモナド変換子スタックを使うと、ロギングの機能が追加された `split`アクションに作り変えられます。

```haskell
type Errors = Array String

type Log = Array String

type Parser = StateT String (WriterT Log (ExceptT Errors Identity))

split :: Parser String
split = do
  s <- get
  lift $ tell ["The state is " <> s]
  case s of
    "" -> lift $ lift $ throwError ["Empty string"]
    _ -> do
      put (drop 1 s)
      pure (take 1 s)
```

この計算をPSCiで試してみると、 `split`が実行されるたびに状態がログに追加されることがわかります。

なお、モナド変換子スタックに現れる順序で副作用を取り除いていかなければなりません。
最初に`StateT`型構築子を取り除くために`runStateT`を、それから`runtWriteT`、`runExceptT`を使います。
最後に`unwrap`を使用して`Identity`モナド中で計算します。

```text
> runParser p s = unwrap $ runExceptT $ runWriterT $ runStateT p s

> runParser split "test"
(Right (Tuple (Tuple "t" "est") ["The state is test"]))

> runParser ((<>) <$> split <*> split) "test"
(Right (Tuple (Tuple "te" "st") ["The state is test", "The state is est"]))
```

しかし、状態が空であることが理由で解析が失敗した場合、ログは全く出力されません。

```text
> runParser split ""
(Left ["Empty string"])
```

これは、`ExceptT`モナド変換子が提供する副作用と`WriterT`モナド変換子が提供する副作用との関係によるものです。
これはモナド変換子スタックが構成されている順序を変更することで対処できます。
スタックの最上部に`ExceptT`変換子を移動すると、先ほど`Writer`を`ExceptT`に変換したときに見たように、最初のエラーまでに書かれた全ての文言がログに含まれるようになります。

このコードの問題の1つは、複数のモナド変換子の上まで計算を持ち上げるために、`lift`関数を複数回使わなければならないということです。
例えば`throwError`の呼び出しは、1回目は`WriteT`へ、2回目は`StateT`へ、と2回持ちあげなければなりません。
小さなモナド変換子スタックならなんとかなりますが、そのうちすぐに不便になるでしょう。

幸いなことに、これから見るような型クラス推論によって提供されるコードの自動生成を使うと、ほとんどの「重労働」を任せられます。

## 演習

 1. （簡単）`Identity`関手を土台とする`ExceptT`モナド変換子を使って、2つの数の商を求める関数
    `safeDivide`を書いてください。
    この関数は分母がゼロの場合に（文字列「Divide by zero!」の）エラーを投げます。
 1. （普通）次のような構文解析関数を書いてください。

     ```haskell
     string :: String -> Parser String
     ```

     これは現在の状態が接頭辞に照合するか、もしくはエラー文言とともに失敗します。

     この構文解析器は次のように動作します。

     ```text
     > runParser (string "abc") "abcdef"
     (Right (Tuple (Tuple "abc" "def") ["The state is abcdef"]))
     ```

     *手掛かり*：出発点として`split`の実装が使えます。
     `stripPrefix`関数も役に立つかもしれません。
1. （難しい）文書表示ライブラリを、`ReaderT`と`WriterT`モナド変換子を使用して再実装してください。
   以前`Reader`モナドを使用して書いたものです。

     文字列を出力する `line`や文字列を連結する `cat`を使うのではなく、`WriteT`モナド変換子と一緒に `Array String`モノイドを使い、結果へ行を追加するのに `tell`を使ってください。
     アポストロフィ (`'`) を付ける以外は元の実装と同じ名前を使ってください。

## 型クラスが助けに来たぞっ

本章の最初で扱った `State`モナドを見てみると、 `State`モナドの動作には次のような型が与えられていました。

```haskell
get    :: forall s.             State s s
put    :: forall s. s        -> State s Unit
modify :: forall s. (s -> s) -> State s Unit
```

`Control.Monad.State.Class`モジュールで与えられている型は、実際にはこれよりもっと一般的です。

```haskell
get    :: forall m s. MonadState s m =>             m s
put    :: forall m s. MonadState s m => s        -> m Unit
modify :: forall m s. MonadState s m => (s -> s) -> m Unit
```

`Control.Monad.State.Class`モジュールには`MonadState`（多変数）型クラスが定義されています。
この型クラスは「変更可能な状態を提供する純粋なモナド」への抽象化を可能にします。
予想できると思いますが、 `State s`型構築子は `MonadState
s`型クラスのインスタンスになっており、このクラスには他にも興味深いインスタンスが数多くあります。

特に、`transformers`パッケージではモナド変換子`WriterT`、`ReaderT`、`ExceptT`についての`MonadState`のインスタンスがあります。
通底する`Monad`が`MonadState`インスタンスを持つなら常に、これらもインスタンスを持ちます。
つまり実際には、`StateT`がモナド変換子スタックの*どこか*に現れ、`StateT`より上の全てが`MonadState`のインスタンスであれば、`lift`を使う必要なく`get`や`put`や`modify`を直接自由に使用できます。

当然ですが、これまで扱ってきた`ReaderT`、`WriterT`、`ExceptT`変換子についても、同じことが言えます。
`transformers`では主な各変換子について型クラスが定義されています。
これによりそれらの操作に対応するモナドの上に抽象化できるのです。

上の`split`関数の場合、構築したモナドスタックは各型クラス`MonadState`、`MonadWriter`、`MonadError`のインスタンスです。
つまり`lift`は全く呼び出す必要がないのです。
まるでモナドスタック自体に定義されていたかのように、動作`get`、`put`、`tell`、`throwError`をそのまま使用できます。

```haskell
{{#include ../exercises/chapter11/src/Split.purs:split}}
```

この計算は、独自のプログラミング言語を拡張し、可変状態、ロギング、エラー処理という3つの新しい副作用に対応したように見えます。
しかし、内部的には全てはあくまで純粋な関数と不変のデータを使って実装されているのです。

## 代替

`control`パッケージでは失敗しうる計算を扱う抽象化が数多く定義されています。
その1つは`Alternative`型クラスです。

```haskell
class Functor f <= Alt f where
  alt :: forall a. f a -> f a -> f a

class Alt f <= Plus f where
  empty :: forall a. f a

class (Applicative f, Plus f) <= Alternative f
```

`Alternative`は2つの新しいコンビネータを提供しています。
1つは失敗しうる計算の雛形を提供する`empty`値で、もう1つはエラーが起きたときに*代替の*計算へ戻ってやり直す機能を提供する`alt`関数（そしてその別名`<|>`）です。

`Data.Array`モジュールでは `Alternative`型クラスで型構築子を操作する2
つの便利な関数を提供します。

```haskell
many :: forall f a. Alternative f => Lazy (f (Array a)) => f a -> f (Array a)
some :: forall f a. Alternative f => Lazy (f (Array a)) => f a -> f (Array a)
```

`Data.List`にも等価な`many`と`some`があります。

`many`コンビネータは計算を*ゼロ回以上*繰り返し実行するために`Alternative`型クラスを使います。
`some`コンビネータも似ていますが、最低1回は計算が成功する必要があります。

`Parser`モナド変換子スタックの場合は、`ExceptT`コンポーネントによる`Alternative`のインスタンスがあります。
このコンポーネントでは異なる分枝のエラーに`Monoid`インスタンスを使って組み合わせることによって対応しています（だから`Errors`型に`Array
String`を選ぶ必要があったんですね）。
これは、構文解析器を複数回実行するのに`many`関数と`some`関数を使うことができることを意味します。

```text
> import Data.Array (many)

> runParser (many split) "test"
(Right (Tuple (Tuple ["t", "e", "s", "t"] "")
              [ "The state is \"test\""
              , "The state is \"est\""
              , "The state is \"st\""
              , "The state is \"t\""
              ]))
```

ここでは入力文字列 `"test"`は、1文字からなる文字列4つの配列を返すように繰り返し分割されています。
残った状態は空で、ログは `split`コンビネータが4回適用されたことを示しています。

## モナド内包表記

`Control.MonadPlus`モジュールには `MonadPlus`と呼ばれる`Alternative`型クラスの副クラスが定義されています。
`MonadPlus`はモナドと`Alternative`両方のインスタンスである型構築子を取ります。

```haskell
class (Monad m, Alternative m) <= MonadPlus m
```

実際、`Parser`モナドは `MonadPlus`のインスタンスです。

以前本書中で配列内包表記を押さえたとき、`guard`関数を導入しました。
これは欲しくない結果を取り除けるのに使えました。
実際には`guard`関数はもっと一般的で、`MonadPlus`のインスタンスである任意のモナドに対して使えます。

```haskell
guard :: forall m. Alternative m => Boolean -> m Unit
```

`<|>`演算子は失敗時にバックトラッキングできるようにします。
これがどのように役立つかを見るために、大文字だけに照合する`split`コンビネータの亜種を定義してみましょう。

```haskell
{{#include ../exercises/chapter11/src/Split.purs:upper}}
```

ここで、文字列が大文字でない場合に失敗するよう、`guard`を使用しています。
なお、このコードは前に見た配列内包表記とよく似ています。
このように`MonadPlus`を使うことは、*モナド内包表記*の構築と呼ばれることがあります。

## バックトラッキング

`<|>`演算子を使うと、失敗したときに別の代替計算へとバックトラックできます。
これを確かめるために、小文字に一致するもう1つの構文解析器を定義してみましょう。

```haskell
{{#include ../exercises/chapter11/src/Split.purs:lower}}
```

これにより、まずもし最初の文字が大文字なら複数の大文字に照合し、さもなくばもし最初の文字が小文字なら複数の小文字に照合する、という構文解析器を定義できます。

```text
> upperOrLower = some upper <|> some lower
```

この構文解析器は、大文字と小文字が切り替わるまで、文字に照合し続けます。

```text
> runParser upperOrLower "abcDEF"
(Right (Tuple (Tuple ["a","b","c"] ("DEF"))
              [ "The state is \"abcDEF\""
              , "The state is \"bcDEF\""
              , "The state is \"cDEF\""
              ]))
```

また、`many`を使うと文字列を小文字と大文字の要素に完全に分割できます。

```text
> components = many upperOrLower

> runParser components "abCDeFgh"
(Right (Tuple (Tuple [["a","b"],["C","D"],["e"],["F"],["g","h"]] "")
              [ "The state is \"abCDeFgh\""
              , "The state is \"bCDeFgh\""
              , "The state is \"CDeFgh\""
              , "The state is \"DeFgh\""
              , "The state is \"eFgh\""
              , "The state is \"Fgh\""
              , "The state is \"gh\""
              , "The state is \"h\""
              ]))
```

繰り返しになりますが、これはモナド変換子が齎す再利用性の威力を示しています。
標準的な抽象化を再利用することで、宣言型スタイルのバックトラック構文解析器を、ほんの数行のコードで書くことができました。

## 演習

 1. （簡単）`string`構文解析器の実装から`lift`関数の呼び出しを取り除いてください。
    新しい実装の型検査が通ることを確認し、そうなることを納得するまで確かめましょう。
 1. （普通）`string`構文解析器と`some`コンビネータを使って構文解析器`asFollowedByBs`を書いてください。
    これは文字列`"a"`の連続と、それに続く文字列`"b"`の連続からなる文字列を認識するものです。
 1. （普通）`<|>`演算子を使って構文解析器`asOrBs`を書いてください。
    これは文字`a`と文字`b`が任意の順序で現れる文字列を認識します。
 1. （難しい）`Parser`モナドを次のようにも定義できます。

     ```haskell
     type Parser = ExceptT Errors (StateT String (WriterT Log Identity))
     ```

     このように変更すると、構文解析関数にどのような影響を与えるでしょうか。

## RWSモナド

モナド変換子のとある特定の組み合わせは頻出なので、`transformers`パッケージ内の単一のモナド変換子として提供されています。
`Reader`、`Writer`、`State`のモナドは、*Reader-Writer-State*モナドに組み合わさり、より単純に`RWS`モナドともされます。
このモナドは`RWST`モナド変換子という名前の、対応するモナド変換子を持ちます。

ここでは `RWS`モナドを使ってテキストアドベンチャーゲームの処理を設計していきます。

`RWS`モナドは（戻り値の型に加えて）3つの型変数を使って定義されています。

```haskell
type RWS r w s = RWST r w s Identity
```

なお、`RWS`モナドは基底のモナドを`Identity`に設定することで独自のモナド変換子として定義されています。
`Identity`は副作用を提供しないのでした。

最初の型引数`r`は大域的な構成の型を表します。
2つ目の`w`はログを蓄積するために使用するモノイドを表します。
3つ目の`s`は可変状態の型です。

このゲームの場合には、大域的な設定は
`Data.GameEnvironment`モジュールの`GameEnvironment`という名前の型で定義されています。

```haskell
{{#include ../exercises/chapter11/src/Data/GameEnvironment.purs:env}}
```

プレイヤー名と、ゲームがデバッグモードで動作しているか否かを示すフラグが定義されています。
モナド変換子を実行するとなると、これらのオプションがコマンドラインから設定されます。

可変状態は `Data.GameState`モジュールの `GameState`と呼ばれる型で定義されています。

```haskell
{{#include ../exercises/chapter11/src/Data/GameState.purs:imports}}

{{#include ../exercises/chapter11/src/Data/GameState.purs:GameState}}
```

`Coords`データ型は2次元平面の点を表し、 `GameItem`データ型はゲーム内のアイテムの列挙です。

```haskell
{{#include ../exercises/chapter11/src/Data/GameItem.purs:GameItem}}
```

`GameState`型は2つの新しいデータ構造を使っています。
`Map`と`Set`はそれぞれ整列されたマップと整列された集合を表します。
`items`属性は、ゲーム平面上の座標からその位置にあるゲームアイテムの集合への対応付けです。
`player`属性はプレイヤーの現在の座標を格納し、`inventory`属性は現在プレイヤーが保有するゲームアイテムの集合を格納します。

`Map`と`Set`のデータ構造はキーによって整列され、このキーには`Ord`型クラスの任意の型を使えます。
つまりデータ構造中のキーは完全に順序付けされます。

ゲームの動作を書く上で`Map`と`Set`構造をどのように使っていくのかを見ていきます。

ログとしては `List String`モノイドを使います。
`Game`モナド用の型同義語を定義し、`RWS`を使って実装できます。

```haskell
{{#include ../exercises/chapter11/src/Game.purs:Game}}
```

## ゲームロジックの実装

`Reader`、`Writer`、`State`モナドの動作を再利用することで、`Game`モナドで定義されている単純な動作を組み合わせてゲームを構築していきます。
このアプリケーションの最上位では`Game`モナドで純粋に計算しており、`Effect`モナドは結果からコンソールにテキストを出力するような観測可能な副作用へと変換するために使っています。

このゲームで最も簡単な動作の1つは `has`動作です。
この動作はプレイヤーの持ち物に特定のゲームアイテムが含まれているかどうかを調べます。
これは次のように定義されます。

```haskell
{{#include ../exercises/chapter11/src/Game.purs:has}}
```

この関数は、現在のゲームの状態を読み取るために`MonadState`型クラスで定義されている`get`動作を使っています。
それから指定した`GameItem`が持ち物のアイテムの`Set`に出現するかどうかを調べるために`Data.Set`で定義されている`member`関数を使っています。

他にも`pickUp`動作があります。
現在の位置にゲームアイテムがある場合、プレイヤーの持ち物にそのアイテムを追加します。
これには`MonadWriter`と`MonadState`型クラスの動作を使っています。
一番最初に現在のゲームの状態を読み取ります。

```haskell
{{#include ../exercises/chapter11/src/Game.purs:pickup_start}}
```

次に `pickUp`は現在の位置にあるアイテムの集合を検索します。
これは`Data.Map`で定義された `lookup`関数を使って行います。

```haskell
{{#include ../exercises/chapter11/src/Game.purs:pickup_case}}
```

`lookup`関数は`Maybe`型構築子で示される省略可能な結果を返します。
`lookup`関数は、キーがマップにない場合は`Nothing`を返します。
それ以外の場合は`Just`構築子で対応する値を返します。

関心があるのは、指定されたゲームアイテムが対応するアイテムの集合に含まれている場合です。
ここでも`member`関数を使うとこれを調べることができます。

```haskell
{{#include ../exercises/chapter11/src/Game.purs:pickup_Just}}
```

この場合、`put`を使ってゲームの状態を更新し、`tell`を使ってログに文言を追加できます。

```haskell
{{#include ../exercises/chapter11/src/Game.purs:pickup_body}}
```

ここで2つの計算のどちらも`lift`が必要ないことに注意してください。
なぜなら`MonadState`と`MonadWriter`の両方について`Game`モナド変換子スタック用の適切なインスタンスが存在するからです。

`put`への引数では、レコード更新を使ってゲームの状態の`items`及び`inventory`フィールドを変更しています。
また、特定のキーの値を変更する`Data.Map`の`update`関数を使っています。
今回の場合、プレイヤーの現在の位置にあるアイテムの集合を変更するのに、`delete`関数を使って指定したアイテムを集合から取り除いています。
`insert`を使って新しいアイテムをプレイヤーの持ち物の集合に加えるときにも、`inventory`は更新されます。

最後に、`pickUp`関数は`tell`を使ってユーザに通知することにより、残りの場合を処理します。

```haskell
{{#include ../exercises/chapter11/src/Game.purs:pickup_err}}
```

`Reader`モナドを使う例として、 `debug`コマンドのコードを見てみましょう。
ゲームがデバッグモードで実行されている場合、このコマンドを使うとユーザは実行時にゲームの状態を調べることができます。

```haskell
{{#include ../exercises/chapter11/src/Game.purs:debug}}
```

ここでは、ゲームの構成を読み込むために`ask`動作を使用しています。
繰り返しますが、どの計算でも`lift`する必要がなく、同じdo記法ブロック内で`MonadState`、`MonadReader`、`MonadWriter`型クラスで定義されている動作を使える点に注意してください。

`debugMode`フラグが設定されている場合、`tell`動作を使うとログに状態が書き込まれます。
そうでなければ、エラー文言が追加されます。

`Game`モジュールの残りの部分では同様の動作の集合が定義されています。
各動作は`MonadState`、`MonadReader`、`MonadWriter`型クラスにより定義された動作のみを使っています。

## 計算の実行

このゲームロジックは`RWS`モナドで動くため、ユーザのコマンドに応答するために計算する必要があります。

このゲームのフロントエンドは2つのパッケージで構成されています。
アプリカティブなコマンドライン構文解析を提供する`optparse`と、対話的なコンソールベースのアプリケーションを書くことを可能にする、NodeJSの
`readline`モジュールを梱包する `node-readline`パッケージです。

このゲームロジックへのインターフェースは `Game`モジュール内の関数`game`によって提供されます。

```haskell
{{#include ../exercises/chapter11/src/Game.purs:game_sig}}
```

これを計算するには、ユーザが入力した単語のリストを文字列の配列として渡してから、`runRWS`を使って結果の`RWS`を計算します。

```haskell
data RWSResult state result writer = RWSResult state result writer

runRWS :: forall r w s a. RWS r w s a -> r -> s -> RWSResult s a w
```

`runRWS`は`runReader`、`runWriter`、`runState`を組み合わせたように見えます。
引数として大域的な構成及び初期状態を取り、ログ、結果、最終的な状態を含むデータ構造を返します。

このアプリケーションのフロントエンドは、次の型シグネチャを持つ関数`runGame`によって定義されます。

```haskell
{{#include ../exercises/chapter11/src/Main.purs:runGame_sig}}
```

この関数は（`node-readline`と`console`パッケージを使って）コンソールを介してユーザとやり取りします。
`runGame`は関数の引数としてのゲームの設定を取ります。

`node-readline`パッケージでは`LineHandler`型が提供されています。
これは端末からのユーザ入力を扱う`Effect`モナドの動作を表します。
対応するAPIは次の通りです。

```haskell
type LineHandler a = String -> Effect a

foreign import setLineHandler
  :: forall a
   . Interface
  -> LineHandler a
  -> Effect Unit
```

`Interface`型はコンソールの制御子を表しており、コンソールとやり取りする関数への引数として渡されます。
`createConsoleInterface`関数を使用すると`Interface`を作成できます。

```haskell
{{#include ../exercises/chapter11/src/Main.purs:import_RL}}

{{#include ../exercises/chapter11/src/Main.purs:runGame_interface}}
```

最初の工程はコンソールにプロンプトを設定することです。
`interface`制御対象を渡し、プロンプト文字列と字下げレベルを与えます。

```haskell
{{#include ../exercises/chapter11/src/Main.purs:runGame_prompt}}
```

今回は行制御関数を実装することに関心があります。
ここでの行制御は`let`宣言内の補助関数を使って次のように定義されています。

```haskell
{{#include ../exercises/chapter11/src/Main.purs:runGame_lineHandler}}
```

`let`束縛が`env`という名前のゲーム構成や`interface`という名前のコンソール制御対象を包み込んでいます。

この制御子は追加の最初の引数としてゲームの状態を取ります。
ゲームのロジックを実行するために`runRWS`にゲームの状態を渡さなければならないので、これは必要となっています。

この動作が最初に行うことは、`Data.String`モジュールの `split`関数を使用して、ユーザーの入力を単語に分割することです。
それから、ゲームの環境と現在のゲームの状態を渡し、 `runRWS`を使用して（`RWS`モナドで）`game`動作を実行しています。

純粋な計算であるゲームロジックを実行するには、画面に全てのログ文言を出力して、ユーザに次のコマンドのためのプロンプトを表示する必要があります。
`for_`動作が（`List String`型の）ログを走査し、コンソールにその内容を出力するために使われています。
最後に`setLineHandler`を使って行制御関数を更新することでゲームの状態を更新し、`prompt`動作を使ってプロンプトを再び表示しています。

`runGame`関数は最終的にコンソールインターフェイスに最初の行制御子を取り付けて、初期プロンプトを表示します。

```haskell
{{#include ../exercises/chapter11/src/Main.purs:runGame_attach_handler}}
```

## 演習

 1. （普通）ゲームの格子上にある全てのゲームアイテムをユーザの持ちものに移動する新しいコマンド `cheat`を実装してください。
    関数`cheat :: Game Unit`を`Game`モジュールに作り、この関数を`game`から使ってください。
 1. （難しい）`RWS`モナドの ` Writer`コンポーネントは、エラー文言とお知らせ文言の2つの種類の文言のために使われています。
    このため、コードの幾つかの箇所では、エラーの場合を扱うためにcase式を使用しています。

     コードをリファクタリングしてください。
     エラー文言を扱うのに`ExceptT`モナド変換子を使い、お知らせ文言を扱うのに`RWS`を使います。
     *補足*：この演習にはテストがありません。

## コマンドラインオプションの扱い

このアプリケーションの最後の部品には、コマンドラインオプションの解析と`GameEnvironment`設定レコードを作成する役目があります。
このためには`optparse`パッケージを使用します。

`optparse`は*アプリカティブなコマンドラインオプション構文解析器*の一例です。
アプリカティブ関手を使うと、いろいろな副作用の型を表す型構築子まで任意個数の引数の関数を持ち上げられることを思い出してください。
`optparse`パッケージの場合には、コマンドラインオプションからの読み取りの副作用を追加する`Parser`関手（optparseのモジュール`Options.Applicative`からインポートされたもの。`Split`モジュールで定義した`Parser`と混同しないように）が興味深い関手になっています。
これは次のような制御子を提供しています。

```haskell
customExecParser :: forall a. ParserPrefs -> ParserInfo a -> Effect a
```

実例を見るのが一番です。
このアプリケーションの `main`関数は`customExecParser`を使って次のように定義されています。

```haskell
{{#include ../exercises/chapter11/src/Main.purs:main}}
```

最初の引数は`optparse`ライブラリを設定するために使用されます。
今回の場合、アプリケーションが引数なしで走らされたときは、（「missing argument」エラーを表示する代わりに）`OP.prefs
OP.showHelpOnEmpty`を使って使用方法の文言を表示するように設定していますが、`Options.Applicative.Builder`モジュールには他にも幾つかの選択肢を提供しています。

2つ目の引数は解析プログラムの完全な説明です。

```haskell
{{#include ../exercises/chapter11/src/Main.purs:argParser}}

{{#include ../exercises/chapter11/src/Main.purs:parserOptions}}
```

ここで`OP.info`は、`Parser`をヘルプ文言の書式方法のためのオプションの集合と組み合わせます。
`env <**> OP.helper`は`env`と名付けられた任意のコマンドライン引数`Parser`を取り、自動的に`--help`オプションを加えます。
ヘルプ文言用のオプションは型が`InfoMod`であり、これはモノイドなので、`fold`関数を使って複数のオプションを一緒に追加できます。

解析器の面白い部分は`GameEnvironment`の構築にあります。

```haskell
{{#include ../exercises/chapter11/src/Main.purs:env}}
```

`player`と`debug`は両方とも`Parser`なので、アプリカティブ演算子`<$>`と`<*>`を使って`gameEnvironment`関数を持ち上げられます。
この関数は`Parser`上で型`PlayerName -> Boolean -> GameEnvironment`を持ちます。
`OP.strOption`は文字列値を期待するコマンドラインオプションを構築し、一緒に畳み込まれた`Mod`の集まりを介して構成されています。
`OP.flag`は似たような動作をしますが、関連付けられた値は期待しません。
`optparse`は多様なコマンドライン解析器を構築するために使える様々な修飾子について、大部の[ドキュメント](https://pursuit.purescript.org/packages/purescript-optparse)を提供しています。

アプリカティブ演算子による記法を使うことで、コマンドラインインターフェイスの簡潔で宣言的な仕様を与えられた点に注目です。
加えて、新しいコマンドライン引数を追加するのは単純で、`runGame`に新しい関数引数を追加し、`env`の定義中で`<*>`を使って追加の引数まで`runGame`を持ち上げるだけでできます。

## 演習

 1. （普通）`GameEnvironment`レコードに新しい真偽値のプロパティ`cheatMode`を追加してください。
    また、`optparse`の構成に、チートモードを有効にする新しいコマンドラインフラグ`-c`を追加してください。
    チートモードが有効になっていない場合、前の演習の`cheat`コマンドは禁止されます。

## まとめ

この章ではこれまで学んできた技術を実践的に実演しました。
モナド変換子を使用したゲームの純粋な仕様の構築、コンソールを使用したフロントエンドを構築するための`Effect`モナドがそれです。

ユーザインターフェイスからの実装を分離したので、ゲームの別のフロントエンドも作成できるでしょう。
例えば、`Effect`モナドでCanvas APIやDOMを使用して、ブラウザでゲームを描画するようなことができるでしょう。

モナド変換子によって命令型のスタイルで安全なコードを書けることが分かりました。
このスタイルでは型システムによって作用が追跡されています。
加えて、型クラスはモナドが提供する動作へと抽象化する強力な方法を提供し、これによりコードの再利用が可能になりました。
標準的なモナド変換子を組み合わせることにより、`Alternative`や`MonadPlus`のような標準的な抽象化を使用して、役に立つモナドを構築できました。

モナド変換子は表現力の高いコードの優れた実演となっています。
これは高階多相や多変数型クラスなどの高度な型システムの機能を利用することによって記述できるものです。
