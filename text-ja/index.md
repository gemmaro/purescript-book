# 実例によるPureScript

このリポジトリには、Phil Freemanによる*PureScript by
Example*の[コミュニティフォーク](https://github.com/purescript-contrib/purescript-book/)が含まれます。
同書は "The PureScript book" としても知られています。
このバージョンはコードと演習が最近のバージョンのコンパイラ、ライブラリ、ツールで動くように更新されています。
PureScriptのエコシステムの最新の機能を紹介すべく書き直された章もあります。

本書をお楽しみいただき、お役立ちいただけましたら、[Leanpubの原書](https://leanpub.com/purescript)の購入をご検討ください。

## 現状

本書は言語の進化に伴って継続的に更新されているため、内容に関して発見したどんな[問題](https://github.com/purescript-contrib/purescript-book/issues)でもご報告ください。
より初心者にやさしくできそうな分かりづらい節を指摘するような単純なものであれ、共有いただいたどんなフィードバックにも感謝します。

各章には単体テストも加えられているので、演習への自分の回答が正しいかどうか確かめることができます。
テストの最新の状態については[#79](https://github.com/purescript-contrib/purescript-book/issues/79)を見てください。

## 本書について

PureScriptは、表現力のある型を持つ、小さくて強力で静的に型付けされたプログラミング言語です。
Haskellで書かれ、またこの言語から着想を得ています。
そしてJavaScriptにコンパイルされます。

JavaScriptでの関数型プログラミングは最近かなりの人気を誇るようになりましたが、コードを書く上で統制された環境が欠けていることが大規模なアプリケーション開発の妨げとなっています。
PureScriptは、強力に型付けされた関数型プログラミングの力をJavaScriptでの開発の世界に持ち込むことにより、この問題の解決を目指しています。

本書は、基礎（開発環境の立ち上げ）から応用に至るまでの、PureScriptプログラミング言語の始め方を示します。

各章は特定の課題により動機付けられており、その問題を解いていく過程において、新しい関数型プログラミングの道具と技法が導入されていきます。
以下は本書で解いていく課題の幾つかの例です。

- マップと畳み込みを使ったデータ構造の変換
- アプリカティブ関手を使ったフォームフィールドの検証
- QuickCheckによるコードの検査
- Canvasの使用
- 領域特化言語の実装
- DOMの取り回し
- JavaScriptの相互運用性
- 並列非同期実行

## 使用許諾

Copyright (c) 2014-2017 Phil Freeman.

The text of this book is licensed under the Creative Commons
Attribution-NonCommercial-ShareAlike 3.0 Unported License:
<https://creativecommons.org/licenses/by-nc-sa/3.0/deed.en_US>.

<small>※以降の原文の使用許諾に関する和訳は法的効力を持ちません。<br>
本書のテキストは<a
href="https://creativecommons.org/licenses/by-nc-sa/3.0/deed.ja">表示 - 非営利 -
継承3.0非移植 (CC BY-NC-SA 3.0)</a>のもとに使用が許諾される。</small>

Some text is derived from the [PureScript Documentation
Repo](https://github.com/purescript/documentation), which uses the same
license, and is copyright [various
contributors](https://github.com/purescript/documentation/blob/master/CONTRIBUTORS.md).

<small>幾つかのテキストは[PureScriptのドキュメントリポジトリ](https://github.com/purescript/documentation)から派生している。
派生元も同じ使用許諾であり、[様々な形で貢献された方々](https://github.com/purescript/documentation/blob/master/CONTRIBUTORS.md)の著作権が含まれる。</small>

The exercises are licensed under the MIT license.

<small>演習はMITライセンスの下に使用が許諾される。</small>

- - -

<small>

Copyright (C) 2015-2018 aratama.<br>
Copyright (C) 2022, 2023 gemmaro.

この翻訳は[aratama](https://github.com/aratama)氏による翻訳を元に改変を加えています。
同氏の翻訳リポジトリは[`aratama/purescript-book-ja`](https://github.com/aratama/purescript-book-ja)に、Webサイトは[実例によるPureScript](http://aratama.github.io/purescript/)にあります。
[aratama氏訳の使用許諾](http://aratama.github.io/purescript/)は以下の通りです。

> This book is licensed under the [Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-nc-sa/3.0/deed.en_US).
>
> 本書は[クリエイティブコモンズ 表示 - 非営利 - 継承 3.0 非移植ライセンス](http://creativecommons.org/licenses/by-nc-sa/3.0/deed.ja)でライセンスされています。

本翻訳も原文と原翻訳にしたがい、
[Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License](https://creativecommons.org/licenses/by-nc-sa/3.0/deed.en_US)の下に使用が許諾されます。

</small>