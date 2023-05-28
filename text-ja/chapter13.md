# テストの自動生成

## この章の目標

この章では、テスティングの問題に対する、型クラスの特に洗練された応用について示します。
*どのように*テストするのかをコンパイラに教えるのではなく、コードが*どのような*性質を持っているべきかを教えることでテストします。
型クラスを使って無作為データ生成のための紋切り型なコードを書かずして、テスト項目を仕様から無作為に生成できます。
これは*生成的テスティング*（generative testing、または*property-based
testing*）と呼ばれ、Haskellの[QuickCheck](http://wiki.haskell.org/Introduction_to_QuickCheck1)ライブラリによって普及した手法です。

`quickcheck`パッケージはHaskellのQuickCheckライブラリをPureScriptにポーティングしたもので、型や構文はもとのライブラリとほとんど同じようになっています。
`quickcheck`を使って簡単なライブラリをテストし、Spagoでテストスイートを自動化されたビルドに統合する方法を見ていきます。

## プロジェクトの準備

この章のプロジェクトには依存関係として `quickcheck`が追加されます。

Spagoプロジェクトでは、テストソースは `test`ディレクトリに置かれ、テストスイートのメインモジュールは
`Test.Main`と名づけられます。 テストスイートは、 `spago test`コマンドを使用して実行できます。

## 性質を書く

`Merge`モジュールでは簡単な関数 `merge`が実装されています。
これを`quickcheck`ライブラリの機能を実演するために使っていきます。

```haskell
merge :: Array Int -> Array Int -> Array Int
```

`merge`は2つの整列された整数の配列を取って、結果が整列されるように要素を統合します。
例えば次のようになります。

```text
> import Merge
> merge [1, 3, 5] [2, 4, 5]

[1, 2, 3, 4, 5, 5]
```

典型的なテストスイートでは、手作業でこのような小さなテスト項目を幾つも作成し、結果が正しい値と等しいことを確認することでテストを実施します。
しかし、 `merge`関数について知る必要があるものは全て、この性質に要約できます。

- `xs`と`ys`が整列済みなら、`merge xs ys`は両方の配列が一緒に結合されて整列された結果になります。

`quickcheck`では、無作為なテスト項目を生成することで、直接この性質をテストできます。
コードが持つべき性質を関数として述べるだけです。
この場合は1つの性質があります。

```haskell
main = do
  quickCheck \xs ys ->
    eq (merge (sort xs) (sort ys)) (sort $ xs <> ys)
```

このコードを実行すると、 `quickcheck`は無作為な入力 `xs`と
`ys`を生成してこの関数に渡すことで、主張しようとしている性質を反証しようとします。
何らかの入力に対して関数が `false`を返した場合、性質は正しくないことが示され、ライブラリはエラーを発生させます。
幸いなことに、次のように100個の無作為なテスト項目を生成しても、ライブラリはこの性質を反証できません。

```text
$ spago test

Installation complete.
Build succeeded.
100/100 test(s) passed.
...
Tests succeeded.
```

もし
`merge`関数に意図的にバグを混入した場合（例えば、大なりのチェックを小なりのチェックへと変更するなど）、最初に失敗したテスト項目の後で例外が実行時に投げられます。

```text
Error: Test 1 failed:
Test returned false
```

見ての通りこのエラーメッセージではあまり役に立ちませんが、少し工夫するだけで改良できます。

## エラーメッセージの改善

テスト項目が失敗した時に同時にエラーメッセージを提供する上で、`quickcheck`は`<?>`演算子を提供しています。
次のように性質の定義とエラー文言を`<?>`で区切って書くだけです。

```haskell
quickCheck \xs ys ->
  let
    result = merge (sort xs) (sort ys)
    expected = sort $ xs <> ys
  in
    eq result expected <?> "Result:\n" <> show result <> "\nnot equal to expected:\n" <> show expected
```

このとき、もしバグを混入するようにコードを変更すると、最初のテスト項目が失敗したときに改良されたエラーメッセージが表示されます。

```text
Error: Test 1 (seed 534161891) failed:
Result:
[-822215,-196136,-116841,618343,887447,-888285]
not equal to expected:
[-888285,-822215,-196136,-116841,618343,887447]
```

入力 `xs`が無作為に選ばれた数の配列として生成されていることに注目してください。

## 演習

 1. （簡単）配列に空の配列を統合しても元の配列は変更されないことを確かめる性質を書いてください。
    *補足*：この新しい性質は冗長です。
    というのもこの状況は既に既存の性質で押さえられているからです。
    ここでは読者がQuickCheckを使う練習のための簡単なやり方を示そうとしているだけです。
 1. （簡単）`merge`の残りの性質に対して、適切なエラーメッセージを追加してください。

## 多相的なコードのテスト

`Merge`モジュールでは、数の配列だけでなく、 `Ord`型クラスに属するどんな型の配列に対しても動作する、 `merge`関数を一般化した
`mergePoly`という関数が定義されています。

```haskell
mergePoly :: forall a. Ord a => Array a -> Array a -> Array a
```

`merge`の代わりに `mergePoly`を使うように元のテストを変更すると、次のようなエラーメッセージが表示されます。

```text
No type class instance was found for

  Test.QuickCheck.Arbitrary.Arbitrary t0

The instance head contains unknown type variables.
Consider adding a type annotation.
```

このエラーメッセージは、配列に持たせたい要素の型が何なのかわからないので、コンパイラが無作為なテスト項目を生成できなかったということを示しています。
このような場合、型註釈を使ってコンパイラが特定の型を推論するように強制できます。
例えば`Array Int`などです。

```haskell
quickCheck \xs ys ->
  eq (mergePoly (sort xs) (sort ys) :: Array Int) (sort $ xs <> ys)
```

代替案として型を指定する補助関数を使うこともできます。
こうするとより見通しのよいコードになることがあります。
例えば同値関数の同義な関数`ints`を定義したとしましょう。

```haskell
ints :: Array Int -> Array Int
ints = id
```

それから、コンパイラが引数の2つの配列の型 `Array Int`を推論するように、テストを変更します。

```haskell
quickCheck \xs ys ->
  eq (ints $ mergePoly (sort xs) (sort ys)) (sort $ xs <> ys)
```

ここで、 `ints`関数が不明な型を解消するために使われているため、 `xs`と `ys`はどちらも型 `Array Int`を持っています。

## 演習

 1. （簡単）`xs`と `ys`の型を `Array Boolean`に強制する関数 `bools`を書き、
    `mergePoly`をその型でテストする性質を追加してください。
 1. （普通）標準関数から（例えば`arrays`パッケージから）1つ関数を選び、適切なエラーメッセージを含めてQuickCheckの性質を書いてください。
    その性質は、補助関数を使って多相型引数を `Int`か `Boolean`のどちらかに固定しなければいけません。

## 任意のデータの生成

`quickcheck`ライブラリを使って性質に対するテスト項目を無作為に生成する方法について説明します。

無作為に値を生成できるような型は、次のような型クラス `Arbitary`のインスタンスを持っています。

```haskell
class Arbitrary t where
  arbitrary :: Gen t
```

`Gen`型構築子は*決定的無作為データ生成*の副作用を表しています。
決定的無作為データ生成は、擬似乱数生成器を使って、シード値から決定的無作為関数の引数を生成します。
`Test.QuickCheck.Gen`モジュールは、生成器を構築するための幾つかの有用なコンビネータを定義しています。

`Gen`はモナドでもアプリカティブ関手でもあるので、
`Arbitary`型クラスの新しいインスタンスを作成するのに、いつも使っているようなコンビネータを自由に使うことができます。

例えば、 `quickcheck`ライブラリで提供されている `Int`型用の
`Arbitrary`インスタンスを使い、256個のバイト値上の分布を作ることができます。
これには`Gen`用に`Functor`インスタンスを使って整数から任意の整数値のバイトまでマップします。

```haskell
newtype Byte = Byte Int

instance Arbitrary Byte where
  arbitrary = map intToByte arbitrary
    where
    intToByte n | n >= 0 = Byte (n `mod` 256)
                | otherwise = intToByte (-n)
```

ここでは、0から255までの間の整数値であるような型 `Byte`を定義しています。
`Arbitrary`インスタンスは `map`演算子を使って、 `intToByte`関数を `arbitrary`アクションまで持ち上げています。
`arbitrary`アクション内部の型は `Gen Int`と推論されます。

この考え方を `merge`用のテストに使うこともできます。

```haskell
quickCheck \xs ys ->
  eq (numbers $ mergePoly (sort xs) (sort ys)) (sort $ xs <> ys)
```

このテストでは、任意の配列 `xs`と `ys`を生成しますが、 `merge`は整列済みの入力を期待しているので、 `xs`と
`ys`を整列しておかなければなりません。
一方で、整列された配列を表すnewtypeを作成し、整列されたデータを生成する `Arbitrary`インスタンスを書くこともできます。

```haskell
newtype Sorted a = Sorted (Array a)

sorted :: forall a. Sorted a -> Array a
sorted (Sorted xs) = xs

instance (Arbitrary a, Ord a) => Arbitrary (Sorted a) where
  arbitrary = map (Sorted <<< sort) arbitrary
```

この型構築子を使うと、テストを次のように変更できます。

```haskell
quickCheck \xs ys ->
  eq (ints $ mergePoly (sorted xs) (sorted ys)) (sort $ sorted xs <> sorted ys)
```

これは些細な変更に見えるかもしれませんが、 `xs`と `ys`の型はただの `Array Int`から `Sorted Int`へと変更されています。
これにより、 `mergePoly`関数は整列済みの入力を取る、という*意図*を、わかりやすく示すことができます。
理想的には、 `mergePoly`関数自体の型が `Sorted`型構築子を使うようにするといいでしょう。

より興味深い例として、 `Tree`モジュールでは枝の値で整列された二分木の型が定義されています。

```haskell
data Tree a
  = Leaf
  | Branch (Tree a) a (Tree a)
```

`Tree`モジュールでは次のAPIが定義されています。

```haskell
insert    :: forall a. Ord a => a -> Tree a -> Tree a
member    :: forall a. Ord a => a -> Tree a -> Boolean
fromArray :: forall a. Ord a => Array a -> Tree a
toArray   :: forall a. Tree a -> Array a
```

`insert`関数は新しい要素を整列済みの二分木に挿入するのに使われ、 `member`関数は特定の値の有無を木に問い合わせるのに使われます。
例えば次のようになります。

```text
> import Tree

> member 2 $ insert 1 $ insert 2 Leaf
true

> member 1 Leaf
false
```

`toArray`関数と `fromArray`関数は、整列された木と整列された配列を相互に変換するために使われます。
`fromArray`を使うと、木についての `Arbitrary`インスタンスを書くことができます。

```haskell
instance (Arbitrary a, Ord a) => Arbitrary (Tree a) where
  arbitrary = map fromArray arbitrary
```

型 `a`についての`Arbitary`インスタンスが使えるなら、テストする性質の引数の型として `Tree a`を使うことができます。例えば、
`member`テストは値を挿入した後は常に `true`を返すことをテストできます。

```haskell
quickCheck \t a ->
  member a $ insert a $ treeOfInt t
```

ここでは、引数 `t`は `Tree Number`型の無作為に生成された木です。
型引数は、同値関数 `treeOfInt`によって明確にされています。

## 演習

 1. （普通）`a-z`の範囲から無作為に選ばれた文字の集まりを生成する
    `Arbitrary`インスタンスを持つ、`String`のnewtypeを作ってください。
    *手掛かり*：`Test.QuickCheck.Gen`モジュールから `elements`と `arrayOf`関数を使います。
 1. （難しい）木に挿入された値は、どれだけ挿入があった後でも、その木の構成要素であることを主張する性質を書いてください。

## 高階関数のテスト

`Merge`モジュールは `merge`関数の別の一般化も定義しています。
`mergeWith`関数は追加の関数を引数として取り、統合される要素の順序を決定するのに使われます。
つまり `mergeWith`は高階関数です。

例えば`length`関数を最初の引数として渡し、既に長さの昇順になっている2つの配列を統合できます。
このとき、結果も長さの昇順になっていなければなりません。

```haskell
> import Data.String

> mergeWith length
    ["", "ab", "abcd"]
    ["x", "xyz"]

["","x","ab","xyz","abcd"]
```

このような関数をテストするにはどうしたらいいでしょうか。
理想的には、関数である最初の引数を含めた、3つの引数全てについて、値を生成したいと思うでしょう。

関数を無作為に生成できるようにする、もう1つの型クラスがあります。
この型クラスは `Coarbitrary`と呼ばれており、次のように定義されています。

```haskell
class Coarbitrary t where
  coarbitrary :: forall r. t -> Gen r -> Gen r
```

`coarbitrary`関数は、型 `t`と、関数の結果の型 `r`についての乱数生成器を関数の引数としてとり、乱数生成器を _かき乱す_
のにこの引数を使います。つまり関数の引数を使って、乱数生成器の無作為な出力を変更しているのです。

また、もし関数の定義域が `Coarbitrary`で、値域が
`Arbitrary`なら、`Arbitrary`の関数を与える型クラスインスタンスが存在します。

```haskell
instance (Coarbitrary a, Arbitrary b) => Arbitrary (a -> b)
```

実は、これが意味しているのは、引数として関数を取るような性質を記述できるということです。
`mergeWith`関数の場合では、新しい引数を考慮するようにテストを修正すると、最初の引数を無作為に生成できます。

結果が整列されていることは保証できません。
必ずしも`Ord`インスタンスを持っているとさえ限らないのです。
しかし、引数として渡す関数 `f`に従って結果が整列されていることは期待されます。
更に、2つの入力配列が `f`に従って整列されている必要がありますので、`sortBy`関数を使って関数 `f`が適用されたあとの比較に基づいて
`xs`と`ys`を整列します。

```haskell
quickCheck \xs ys f ->
  let
    result =
      map f $
        mergeWith (intToBool f)
                  (sortBy (compare `on` f) xs)
                  (sortBy (compare `on` f) ys)
    expected =
      map f $
        sortBy (compare `on` f) $ xs <> ys
  in
    eq result expected
```

ここでは、関数 `f`の型を明確にするために、関数 `intToBool`を使用しています。

```haskell
intToBool :: (Int -> Boolean) -> Int -> Boolean
intToBool = id
```

関数は `Arbitrary`であるだけでなく `Coarbitrary`でもあります。

```haskell
instance (Arbitrary a, Coarbitrary b) => Coarbitrary (a -> b)
```

これは値の生成が単純な関数だけに限定されるものではないことを意味しています。
つまり*高階関数*や、引数が高階関数であるような関数もまた、無作為に生成できるのです。

## Coarbitraryのインスタンスを書く

`Gen`の `Monad`や `Applicative`インスタンスを使って独自のデータ型に対して
`Arbitrary`インスタンスを書くことができるのとちょうど同じように、独自の `Coarbitrary`インスタンスを書くこともできます。
これにより、無作為に生成される関数の定義域として、独自のデータ型を使うことができるようになります。

`Tree`型の `Coarbitrary`インスタンスを書いてみましょう。
枝に格納されている要素の型に `Coarbitrary`インスタンスが必要になります。

```haskell
instance Coarbitrary a => Coarbitrary (Tree a) where
```

型 `Tree a`の値が与えられたときに、乱数発生器をかき乱す関数を記述する必要があります。
入力値が `Leaf`であれば、そのままにしておく生成器を返します。

```haskell
  coarbitrary Leaf = id
```

もし木が `Branch`なら、左の部分木、値、右の部分木を使って生成器をかき乱します。
関数合成を使って独自のかき乱し関数を作ります。

```haskell
  coarbitrary (Branch l a r) =
    coarbitrary l <<<
    coarbitrary a <<<
    coarbitrary r
```

これで、木を引数にとるような関数を引数に含む性質を自由に書くことができるようになりました。
例えば`Tree`モジュールでは`anywhere`が定義されており、これは述語が引数のどんな部分木についても成り立っているかを調べる関数です。

```haskell
anywhere :: forall a. (Tree a -> Boolean) -> Tree a -> Boolean
```

これで、この述語関数`anywhere`を無作為に生成できるようになりました。
例えば、 `anywhere`関数は*ある命題のもとで不変*であることが期待されます。

```haskell
quickCheck \f g t ->
  anywhere (\s -> f s || g s) t ==
    anywhere f (treeOfInt t) || anywhere g t
```

ここで、 `treeOfInt`関数は木に含まれる値の型を型 `Int`に固定するために使われています。

```haskell
treeOfInt :: Tree Int -> Tree Int
treeOfInt = id
```

## 副作用のないテスト

通常、テストの目的ではテストスイートの `main`アクションに`quickCheck`関数の呼び出しが含まれています。
しかし、副作用を使わない`quickCheckPure`と呼ばれる `quickCheck`関数の亜種もあります。
`quickCheckPure`は、入力として乱数の種をとり、テスト結果の配列を返す純粋な関数です。

PSCiを使用して `quickCheckPure`を試せます。
ここでは `merge`操作が結合法則を満たすことをテストします。

```text
> import Prelude
> import Merge
> import Test.QuickCheck
> import Test.QuickCheck.LCG (mkSeed)

> :paste
… quickCheckPure (mkSeed 12345) 10 \xs ys zs ->
…   ((xs `merge` ys) `merge` zs) ==
…     (xs `merge` (ys `merge` zs))
… ^D

Success : Success : ...
```

`quickCheckPure`は乱数の種、生成するテスト項目数、テストする性質の3つの引数をとります。
もし全てのテスト項目が成功したら、`Success`データ構築子の配列がコンソールに出力されます。

`quickCheckPure`は、性能ベンチマークの入力データ生成や、webアプリケーションのフォームデータ例を無作為に生成するというような状況で便利かもしれません。

## 演習

 1. （簡単）`Byte`と `Sorted`型構築子についての `Coarbitrary`インスタンスを書いてください。
 1. （普通）任意の関数 `f`について、 `mergeWith f`関数の結合性を主張する（高階）性質を書いてください。
    `quickCheckPure`を使ってPSCiでその性質をテストしてください。
 1. （普通）次のデータ型の`Arbitrary`と`Coarbitrary`インスタンスを書いてください。

     ```haskell
     data OneTwoThree a = One a | Two a a | Three a a a
     ```

     *手掛かり*：`Test.QuickCheck.Gen`で定義された `oneOf`関数を使って `Arbitrary`インスタンスを定義してください。
 1. （普通）`all`を使って `quickCheckPure`関数の結果を単純化してください。
    この新しい関数は型`List Result -> Boolean`を持ち、全てのテストが通れば`true`を、そうでなければ`false`を返します。
 2. （普通）`quickCheckPure`の結果を単純にする別の手法として、関数`squashResults :: List Result -> Result`を書いてみてください。
    `Data.Maybe.First`の`First`モノイドと共に`foldMap`関数を使うことで、失敗した場合の最初のエラーを保存することを検討してください。

## まとめ

この章では`quickcheck`パッケージに出会いました。
これを使うと*生成的テスティング*のパラダイムを使って、宣言的な方法でテストを書くことができました。具体的には以下です。

- `spago test`を使ってQuickCheckのテストを自動化する方法を見ました。
- 性質を関数として書く方法とエラーメッセージを改良する `<?>`演算子の使い方を説明しました。
- `Arbitrary`と
  `Coarbitrary`型クラスによって、如何にして定型的なテストコードの自動生成を可能にし、またどうすれば高階な性質関数が可能になるかを見てきました。
- 独自のデータ型に対して `Arbitrary`と `Coarbitrary`インスタンスを実装する方法を見ました。
