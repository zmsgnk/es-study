# es-study #

Elasticsearchの勉強用メモです。

## Livedoorグルメの研究用データセットを登録する ##

Livedoorグルメの研究用データセットをESに投入します。

https://github.com/livedoor/datasets

データセットの詳細については以下のブログを参照。

http://blog.livedoor.jp/techblog/archives/65836960.html

```Shell
git clone https://github.com/livedoor/datasets.git
cd datasets
tar xvf ldgourmet.tar.gz
```

## インデックスの登録 ##

```Shell
curl -XPOST 'localhost:9200/ldgourmet' -d @mapping.json
```

## データの登録 ##

## query と filter ##

Elasticsearchで検索する方法には、`query`と`filter`の2つがあります。
それぞれ、`query`には約40種類、`filter`には約30種類あります。

- [reference [1.x] » query dsl » queries](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-queries.html)
- [reference [1.x] » query dsl » filters](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-filters.html)

両者の特徴をそれぞれ公式ドキュメントより翻訳してみます。

`query`
- 全文検索用に使う
- 関連性スコア（relevance score）に依存する結果が欲しい時に使う

`filter`
- フィルターはキャッシュされ、メモリもあまり使わない
- 他のクエリが同じフィルターを使うとめっちゃ速い
- `term`、`terms`、`prefix`や`range`などのフィルターはデフォルトでキャッシュされるようになっており、同じフィルターが複数の異なるクエリで
利用されるような時におすすめ。例えば、"age higher than 10"のような`range`フィルター
- `geo`や`script`などのフィルターは、デフォルトではキャッシュされずメモリのロードされる。これらのフィルターは元々速いし、キャッシュするためには
単に実行するよりも余計に処理が増えるから。
- 残りの`and`、`not`や`or`などのフィルターは他のフィルターを操作するので、基本的にはキャッシュされない。
- すべてのフィルターは`_cache`要素と`_cache_key`要素を指定することで、明示的にキャッシュを操作することができる。
大きなフィルターを使うときに便利。

まとめると、`filter`は次のようなケースで使えばいいと思います。
- 同じ検索条件を複数の異なるクエリで使いまわすようなケース
- 値の大小などで単純な絞り込みをしたいとき
- スコアに関係のない検索をしたいとき

