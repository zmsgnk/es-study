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

### よく使いそうなクエリ ###

`simple_query_string`

渋谷にあるカレー屋さんを検索
```Shell
curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d '
{
	"query": {
	  "simple_query_string": {
	    "query": "渋谷 カレー",
	    "fields": ["name", "address"]
	  }
  }
}
```

実行結果
```JSON
{
  "took" : 18,
  "timed_out" : false,
  "_shards" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "hits" : {
    "total" : 7096,
    "max_score" : 2.2253304,
    "hits" : [ {
      "_index" : "ldgourmet",
      "_type" : "restaurant",
      "_id" : "xcWUZvDPSlG0sx-PJKBdlw",
      "_score" : 2.2253304,
      "_source":{"name":"カレーの王様","property":null,"alphabet":null,"name_kana":"かれーのおうさま","pref_id":"13","area_id":"5","station_id1":"2248","station_time1":"6","station_distance1":"476","station_id2":"3168","station_time2":"12","station_distance2":"974","station_id3":"2340","station_time3":"16","station_distance3":"1271","category_id1":"408","category_id2":"218","category_id3":"0","category_id4":"0","category_id5":"0","zip":null,"address":"渋谷区渋谷1-16-14渋谷地下鉄ビルディング1F","north_latitude":"35.39.29.956","east_longitude":"139.42.21.002","description":null,"purpose":null,"open_morning":"1","open_lunch":"1","open_late":"0","photo_count":"0","special_count":"0","menu_count":"0","fan_count":"0","access_count":"524","created_on":"2009-03-12 10:45:58","modified_on":"2011-04-20 18:30:20","closed":"0"}
    } ]
  }
}
```