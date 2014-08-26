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

id:yteraokaさんのスクリプトを拝借しました。
今回は、livedoorグルメのデータセットのうち、レストラン情報と口コミ情報のデータを入れます。

```Shell
bulk_load_data.rb -t rating -f datasets/ratings.csv 
bulk_load_data.rb -t restaurant -f datasets/restaurants.csv 
```

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

[`simple_query_string`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html)クエリ

渋谷にあるカレー屋さんを検索
```Shell
curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d '
{
  "query": {
	  "simple_query_string": {
	    "query": "渋谷 カレー",
	    "fields": ["name", "address"],
	    "default_operator": "and"
	  }
  },
  "size": 1
}'
```

実行結果
```JSON
{
  "took" : 19,
  "timed_out" : false,
  "_shards" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "hits" : {
    "total" : 29,
    "max_score" : 2.2253304,
    "hits" : [ {
      "_index" : "ldgourmet",
      "_type" : "restaurant",
      "_id" : "xcWUZvDPSlG0sx-PJKBdlw",
      "_score" : 2.2253304,
      "_source":{
        "name":"カレーの王様","property":null,"alphabet":null,"name_kana":"かれーのおうさま","pref_id":"13","area_id":"5","station_id1":"2248","station_time1":"6","station_distance1":"476","station_id2":"3168","station_time2":"12","station_distance2":"974","station_id3":"2340","station_time3":"16","station_distance3":"1271","category_id1":"408","category_id2":"218","category_id3":"0","category_id4":"0","category_id5":"0","zip":null,"address":"渋谷区渋谷1-16-14渋谷地下鉄ビルディング1F","north_latitude":"35.39.29.956","east_longitude":"139.42.21.002","description":null,"purpose":null,"open_morning":"1","open_lunch":"1","open_late":"0","photo_count":"0","special_count":"0","menu_count":"0","fan_count":"0","access_count":"524","created_on":"2009-03-12 10:45:58","modified_on":"2011-04-20 18:30:20","closed":"0"}
    } ]
  }
}
```

渋谷にあるカレー屋さんを検索して、PVが多い順にソートしてみる
```Shell
curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d '
{
  "query": {
	  "simple_query_string": {
	    "query": "渋谷 カレー",
	    "fields": ["name", "address"],
	    "default_operator": "and"
	  }
  },
  "sort": [{"access_count": {"order": "desc", "missing": "_last"}}],
  "size": 1
}'
```

実行結果
```JSON
{
  "took" : 24,
  "timed_out" : false,
  "_shards" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "hits" : {
    "total" : 29,
    "max_score" : null,
    "hits" : [ {
      "_index" : "ldgourmet",
      "_type" : "restaurant",
      "_id" : "3X35dbGNQDO-9XIsxiu2lg",
      "_score" : null,
      "_source":{"name":"カレーハウス チリチリ","property":null,"alphabet":"Curry House TIRITIRI","name_kana":"かれーはうすちりちり","pref_id":"13","area_id":"5","station_id1":"2248","station_time1":"10","station_distance1":"829","station_id2":"1673","station_time2":"13","station_distance2":"1014","station_id3":"2511","station_time3":"14","station_distance3":"1089","category_id1":"408","category_id2":"0","category_id3":"0","category_id4":"0","category_id5":"0","zip":"150-0011","address":"渋谷区東1-27-9","north_latitude":"35.39.03.100","east_longitude":"139.42.38.552","description":"埼京線渋谷駅新南口から明治通り沿いに恵比寿方向へ。並木橋交差点を超え200mほど歩くと右手にあります。    ※営業時間と定休日を再度修正しました。2005/07/12 from 管理人    営業時間を修正しました(サポート 2006/09/08)    定休日を更新しました。  (from 東京グルメ 2006/07/08)","purpose":"1,4","open_morning":"1","open_lunch":"1","open_late":"0","photo_count":"21","special_count":"11","menu_count":"2","fan_count":"24","access_count":"25904","created_on":"2003-06-14 18:44:19","modified_on":"2011-04-22 16:50:33","closed":"0"},
      "sort" : [ 25904 ]
    } ]
  }
}
```

-------------------------------------

[`bool`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html)クエリ

`bool`クエリでは`must`、`should`、`must_not`の3つの条件を指定できます。

- `must`  
  - 指定したクエリを必ず含む
- `should` 
  - 含まれるべきクエリを指定することができる。`minimum_should_match`パラメターで
  最低限マッチしてほしいクエリの数を指定することができる。
- `must_not` 
  - 指定したクエリを必ず含まない

```Shell
curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d '
{
  "query": {
    "bool": {
      "must": [
        {"term": {"address": "渋谷"}},
        {"term": {"name": "カレー"}}
      ]
    }
  },
  "sort": [{"access_count": {"order": "desc", "missing": "_last"}}],
  "size": 1
}'
```

実行結果
```JSON
{
  "took" : 9,
  "timed_out" : false,
  "_shards" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "hits" : {
    "total" : 29,
    "max_score" : null,
    "hits" : [ {
      "_index" : "ldgourmet",
      "_type" : "restaurant",
      "_id" : "3X35dbGNQDO-9XIsxiu2lg",
      "_score" : null,
      "_source":{"name":"カレーハウス チリチリ","property":null,"alphabet":"Curry House TIRITIRI","name_kana":"かれーはうすちりちり","pref_id":"13","area_id":"5","station_id1":"2248","station_time1":"10","station_distance1":"829","station_id2":"1673","station_time2":"13","station_distance2":"1014","station_id3":"2511","station_time3":"14","station_distance3":"1089","category_id1":"408","category_id2":"0","category_id3":"0","category_id4":"0","category_id5":"0","zip":"150-0011","address":"渋谷区東1-27-9","north_latitude":"35.39.03.100","east_longitude":"139.42.38.552","description":"埼京線渋谷駅新南口から明治通り沿いに恵比寿方向へ。並木橋交差点を超え200mほど歩くと右手にあります。    ※営業時間と定休日を再度修正しました。2005/07/12 from 管理人    営業時間を修正しました(サポート 2006/09/08)    定休日を更新しました。  (from 東京グルメ 2006/07/08)","purpose":"1,4","open_morning":"1","open_lunch":"1","open_late":"0","photo_count":"21","special_count":"11","menu_count":"2","fan_count":"24","access_count":"25904","created_on":"2003-06-14 18:44:19","modified_on":"2011-04-22 16:50:33","closed":"0"},
      "sort" : [ 25904 ]
    } ]
  }
}
```

-------------------------------------

[`filtered`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-filtered-query.html)クエリ

クエリにフィルターを組み合わせる。下記の例では`range`フィルターと`simple_query_string`を
組み合わせています。

口コミ評価が5のやつで、タイトルと本文に"渋谷"と"カレー"を含む口コミを検索
```Shell
curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d '
{
	"query": {
	  "filtered": {
	    "query": {
	      "simple_query_string": {
	        "query": "渋谷 カレー",
	        "fields": ["title", "body"],
	        "default_operator": "and"
	      }
	    },
	    "filter": {
	      "range": {"total": {"gte": "5"}}
	    }
	  }
	},
	"size": 1
}'
```

実行結果
```JSON
{
  "took" : 21,
  "timed_out" : false,
  "_shards" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "hits" : {
    "total" : 48,
    "max_score" : 2.296202,
    "hits" : [ {
      "_index" : "ldgourmet",
      "_type" : "rating",
      "_id" : "D05jQRsORuSri_QrSGPBTA",
      "_score" : 2.296202,
      "_source":{"restaurant_id":"317436","user_id":"3633bf86","total":"5","food":"0","service":"0","atmosphere":"0","cost_performance":"0","title":"カレーは美味しいわよね　（＾−＾）　","body":"カレーは美味しいわよね　（＾−＾）　 渋谷駅から少し離れていますが そこがまた隠れ家的で素敵です。  知人に誘われて行ってきました。  Restaurant　TAKE（レストランタケ）   カレーはもちろん アラカルト料理もＧｏｏｄ♪  今回はデザートまで お腹に入れる事が出来ませんでしたが 次回は必ず頂きたいです！！  　　カレーを頂く前にアラカルト。 　　とっても綺麗なテリーヌをオーダーするも 　　あまりの綺麗さとおしゃべり＆食べるのに夢中で 　　写真を撮るのを忘れてしまった(ToT) 　　 　　生ハム、うまぁ〜〜〜♪  　　　イカも柔らかく、シュリンプも美味しい  　　アラカルトを食べたのに 　　カレーもちゃぁ〜〜〜んとお腹に入るのデス 　　それはやっぱり美味しいから♪ 　　辛さといいコクといいバッチリです。 　　近所で仕事をしていれば毎日通いたいくらいです  　今度はいつ誰と行こうかしら。 　と、ついつい次に行く予定を考えてしまいたくなるお店。 　 　あぁー美味しかった。ご馳走様でした（＾−＾）  ","purpose":"1","created_on":"2010-04-24 16:49:05"}
    } ]
  }
}
```

ちなみに、クエリを指定しないとフィルターだけ実行されます。

-------------------------------------

- [`fuzzy`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-fuzzy-query.html)
- [`template`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-template-query.html)
- [`function score`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html)
- [`common terms`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-common-terms-query.html)
- [`geoshape`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-geo-shape-query.html)

### よく使いそうなフィルター ###

[`and`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-and-filter.html)、
[`or`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-or-filter.html)、
[`not`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-not-filter.html) フィルター

```Shell
curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d'
{
  "query": {
    "filtered": {
      "filter": {
        "and": [{
          "range": {
            "total": {
              "from": "4",
              "to": "5"
            }
          }
        },
        {
          "term": {"body": "カレー"}
        },
        {
          "term": {"body": "渋谷"}
        }]
      }
    }
  },
  "size": 1
}'
```

実行結果
```JSON
{
  "took" : 5,
  "timed_out" : false,
  "_shards" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "hits" : {
    "total" : 185,
    "max_score" : 1.0,
    "hits" : [ {
      "_index" : "ldgourmet",
      "_type" : "rating",
      "_id" : "eKzC1jFkSlizF8c1_fxV8w",
      "_score" : 1.0,
      "_source":{"restaurant_id":"201","user_id":"7a407165","total":"4","food":"0","service":"0","atmosphere":"0","cost_performance":"0","title":null,"body":"本格系インド料理店としてはかなり老舗になるのではないでしょうか。  銀座の中心からは比較的離れた立地と、料理の特殊性を考慮すると  驚くべき長寿店という気がします。    ムルギランチも当然おいしいのですが、あの辛いトマトスープがかかせません。  カレーがさほど辛くない分を十分おぎなってくれます。  以前、家でトマトの水煮缶をミキサーにかけて、胡椒を中心にスパイスを  適当に入れて作ったらかなり近い味が再現できてしまいましたが、やはりお店にはかないません。  他の料理も食べようと思いつつ、どうしてもムルギとスープの組み合わせから  離れられないのは少し反省してます。    かなり前に恵比寿に出店していた時には、職場の渋谷からちょこちょこ食べに  出かけてましたが、あまり長続きしないでとても残念でした。    ★3.8","purpose":"0","created_on":"2005-04-25 14:48:34"}
    } ]
  }
}
```

`or`フィルターと`not`フィルターも使い方は同じです。

-------------------------------------

[`bool`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-bool-filter.html)フィルター

基本的に`bool`クエリと使い方は同じ。違いはスコアが関係するかどうかと、
デフォルトでキャッシュされるかどうか。

-------------------------------------

[`range`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-range-filter.html)フィルター

あるフィールドの値が特定の範囲に含まれているかどうかでフィルタリング

`range`フィルターで使えるパラメターは以下の4つ

- `gte`  Greater-than or equal to
- `gt`   Greater-than
- `lte`  Less-than or equal to 
- `lt`   Less-than

現時点では数値に対してのみ有効だが、バージョン1.4.0からは時間に対しても使えるようになるらしい。


-------------------------------------

[`exists`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-exists-filter.html)フィルターと
[`missing`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-missing-filter.html)フィルター

- `exists`
  - 特定のフィールドに値が入っているドキュメントを返す
- `missing`
  - 特定のフィールドに値が入っていないドキュメントを返す

口コミタイトルに値が入っている口コミを検索
```Shell
curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d'
{
  "query": {
    "filtered": {
      "filter": {
        "exists": {"field": "title"}
      }
    }
  },
  "size": 1
}'
```

実行結果
```JSON
{
  "took" : 4,
  "timed_out" : false,
  "_shards" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "hits" : {
    "total" : 31377,
    "max_score" : 1.0,
    "hits" : [ {
      "_index" : "ldgourmet",
      "_type" : "rating",
      "_id" : "3ArlHT4vSMu8ByvQTDD33A",
      "_score" : 1.0,
      "_source":{"restaurant_id":"4455","user_id":"31973618","total":"3","food":"4","service":"2","atmosphere":"3","cost_performance":"4","title":"黒いカツカレー","body":"午前中の仕事が終わった帰り道に、会社の人がどうしても食べたいカツカレーがあるとのことで行ってみました。  神保町のキッチン南海って言うところで、ご飯の山の上にキャベツの千切りが乗っていて、山に立掛けるように薄めの揚げたてカツが一枚、そして真っ黒なルーがなみなみと!!  味はと言うとめっちゃスパイシーでもなく、マイルド系でした。  昨日、ハラペーニョソースたんまりのピザを食べてのどをやられた自分にも安心して食べられました(^^ゞ  行った時は、お店の2/3ぐらいの人がカツカレーを食べてましたよ。 次は普通のランチセットもたべてみたいですね。  店員さんのムダのない動きが素晴らしい☆ミ ","purpose":"1","created_on":"2009-07-05 12:11:02"}
    } ]
  }
}
```

口コミタイトルに値が入っていない（null）の口コミを検索
```Shell
curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d'
{
  "query": {
    "filtered": {
      "filter": {
        "missing": {"field": "title"}
      }
    }
  },
  "size": 1
}'
```

実行結果
```JSON
{
  "took" : 80,
  "timed_out" : false,
  "_shards" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "hits" : {
    "total" : 388270,
    "max_score" : 1.0,
    "hits" : [ {
      "_index" : "ldgourmet",
      "_type" : "rating",
      "_id" : "fB2X1-qAShGRml5nIG7-Kw",
      "_score" : 1.0,
      "_source":{"restaurant_id":"310595","user_id":"ee02f26a","total":"5","food":"0","service":"0","atmosphere":"0","cost_performance":"0","title":null,"body":"名前は忘れましたが、札幌で食べたお店よりも、全然こっちの方が美味しかったので、載せました。お店も綺麗（新規オープン・・）でランチは結構混んでいます。個人的にはゆったりと食事できるので夜の方がオススメです。  辛さが０倍から５０倍まで選べるのもＧＯＯＤ！、スープも２種類みたいで、友達は黄色がオススメと言っていましたが、自分は赤の方を食べました。かなり美味しかったです。店長も好感のもてるお兄さんでした。  駅近くなので一度お試しあれです！","purpose":"0","created_on":"2006-10-07 05:06:09"}
    } ]
  }
}
```

[ここ](http://www.elasticsearch.org/guide/en/elasticsearch/guide/current/_dealing_with_null_values.html)に
わかりやすい解説が載っています。

-------------------------------------

地理情報（緯度経度）を使ってフィルタリング
- [`geo_bounding_box`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-geo-bounding-box-filter.html#query-dsl-geo-bounding-box-filter)
- [`geo_distance`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-geo-distance-filter.html)
- [`geo_distance_range`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-geo-distance-range-filter.html)
- [`geo_polygon`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-geo-polygon-filter.html)
- [`geo_shape`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-geo-shape-filter.html)
- [`geohash_cell`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-geohash-cell-filter.html)


## 集計 ##

ESで集計するには、[`facets`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-facets.html)モジュールと
[`aggregations`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations.html)モジュールが使えます。

`aggregations`は`facets`に比べより柔軟な集計ができる。将来的には`facets`モジュールはなくなり完全に`aggregations`の方へ移行
するらしい。

`aggregations`には大きく分けて`Bucketing`と`Metric`の2つがあるそうですが、まだよくわかっていません。
[このブログ](https://www.found.no/foundation/elasticsearch-aggregations/)が参考になりそう。

バージョン1.4.0からは重い集計処理をキャッシュできるようになるらしい。


[`range aggregation`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations-bucket-range-aggregation.html)
を使って口コミを総合評価別に集計してみる。
```Shell
curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d '
{
  "query": {
    "match_all": {}
  },
  "aggs": {
    "rating_range": {
      "range": {
        "field": "total",
        "ranges": [
          {"from": 1, "to": 2},
          {"from": 2, "to": 3},
          {"from": 3, "to": 4},
          {"from": 4, "to": 5},
          {"from": 5}
        ]
      }
    }
  }
}'
```

実行結果
```JSON
{
  "took" : 34,
  "timed_out" : false,
  "_shards" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "hits" : {
    "total" : 419647,
    "max_score" : 0.0,
    "hits" : [ ]
  },
  "aggregations" : {
    "rating_range" : {
      "buckets" : [ {
        "key" : "1.0-2.0",
        "from" : 1.0,
        "from_as_string" : "1.0",
        "to" : 2.0,
        "to_as_string" : "2.0",
        "doc_count" : 4971
      }, {
        "key" : "2.0-3.0",
        "from" : 2.0,
        "from_as_string" : "2.0",
        "to" : 3.0,
        "to_as_string" : "3.0",
        "doc_count" : 14552
      }, {
        "key" : "3.0-4.0",
        "from" : 3.0,
        "from_as_string" : "3.0",
        "to" : 4.0,
        "to_as_string" : "4.0",
        "doc_count" : 64681
      }, {
        "key" : "4.0-5.0",
        "from" : 4.0,
        "from_as_string" : "4.0",
        "to" : 5.0,
        "to_as_string" : "5.0",
        "doc_count" : 79530
      }, {
        "key" : "5.0-*",
        "from" : 5.0,
        "from_as_string" : "5.0",
        "doc_count" : 34744
      } ]
    }
  }
}
```

`range aggregations`では`from`は含むが、`to`は含まないことに注意が必要。

---------------------------------------------

[`min`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations-metrics-min-aggregation.html)、
[`max`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations-metrics-max-aggregation.html)、
[`sum`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations-metrics-sum-aggregation.html)、
[`avg`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations-metrics-avg-aggregation.html)、
[`stats`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations-metrics-stats-aggregation.html)、
[`extended_stats`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations-metrics-extendedstats-aggregation.html)

`extended_stats`を実行してみる
```Shell
curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d '
{
  "query": {"match_all": {}},
  "aggs": {"rating_stats": {"extended_stats": {"field": "total"}}},
  "size": 0
}'
```

実行結果
```JSON
{
  "took" : 134,
  "timed_out" : false,
  "_shards" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "hits" : {
    "total" : 419647,
    "max_score" : 0.0,
    "hits" : [ ]
  },
  "aggregations" : {
    "rating_stats" : {
      "count" : 205626,
      "min" : 0.0,
      "max" : 5.0,
      "avg" : 3.501298473928394,
      "sum" : 719958.0,
      "sum_of_squares" : 2786388.0,
      "variance" : 1.2916661964316827,
      "std_deviation" : 1.136514934539658
    }
  }
}
```

------------------------------------------------

['percentiles'](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations-metrics-percentile-aggregation.html)、

`percentiles`は分位点ごとに集計してくれる。デフォルトでは、[1%, 5%, 25%, 50%, 75%, 95%, 99%]の分位点で集計される。
自分で、[95, 99, 99.9]のように指定することもできる。
```Shell
curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d '
{
  "query": {"match_all": {}},
  "aggs": {
    "pct_photo_count": {
      "percentiles": {
        "field": "photo_count"
      }
    }
  },
  "size": 0
}'
```

実行結果
```JSON 
{
  "took" : 610,
  "timed_out" : false,
  "_shards" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "hits" : {
    "total" : 419647,
    "max_score" : 0.0,
    "hits" : [ ]
  },
  "aggregations" : {
    "pct_photo_count" : {
      "values" : {
        "95.0" : 8.0,
        "96.0" : 9.0,
        "97.0" : 11.0,
        "98.0" : 15.0,
        "99.0" : 21.0
      }
    }
  }
}
```

-------------------------------------------------

[`percentile_ranks`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations-metrics-percentile-rank-aggregation.html)

`percentile_ranks`は`percentiles`とは逆の動きをする。つまり、与えた数値が属する分位点を返す。
```Shell
curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d '
{
  "query": {"match_all": {}},
  "aggs": {
    "pct_photo_count": {
      "percentile_ranks": {
        "field": "photo_count",
        "values": [11.0, 15.0]
      }
    }
  },
  "size": 0
}'
```

実行結果
```JSON
{
  "took" : 679,
  "timed_out" : false,
  "_shards" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "hits" : {
    "total" : 419647,
    "max_score" : 0.0,
    "hits" : [ ]
  },
  "aggregations" : {
    "pct_photo_count" : {
      "values" : {
        "11.0" : 97.02225482546105,
        "15.0" : 98.15532120679747
      }
    }
  }
}
```

-------------------------------------------------

[`cardinality aggregation`](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations-metrics-cardinality-aggregation.html)

任意のフィールドについて、ユニークな値の数を集計したいときは、`cardinality aggregation`を使えばできます。

ユニークなユーザーが何人いるかどうかを調べます。
```Shell
curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true&search_type=count' -d '
{
  "aggs": {
    "unique_user": {
      "cardinality": {
        "field": "user_id"
      }
    }
  }
}'
```

実行結果
```JSON
{
  "took" : 684,
  "timed_out" : false,
  "_shards" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "hits" : {
    "total" : 419647,
    "max_score" : 0.0,
    "hits" : [ ]
  },
  "aggregations" : {
    "unique_user" : {
      "value" : 17875
    }
  }
}
```

ユニークユーザは17875人であることがわかりました。

-------------------------------------------------

`aggregations`と`facets`の大きな違いが、集計を入れ子にできるかどうかです。
例えば、口コミ情報の総合評価（total）ごとに料理の評価（food）を集計するというようなことが
`aggregations`では可能です。

```Shell
curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true&search_type=count' -d '
{
  "aggs": {
    "RATING_TOTAL": {
      "terms": {"field": "total"},
      "aggs": {
        "RATING_FOOD": {
          "terms": {"field": "food"}
        }
      }
    }
  }
}'
```

実行結果 (長くなるので一部だけ表示)
```JSON
{
  "took" : 567,
  "timed_out" : false,
  "_shards" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "hits" : {
    "total" : 419647,
    "max_score" : 0.0,
    "hits" : [ ]
  },
  "aggregations" : {
    "RATING_TOTAL" : {
      "buckets" : [ {
        "key" : 4,
        "key_as_string" : "4",
        "doc_count" : 79530,
        "RATING_FOOD" : {
          "buckets" : [ {
            "key" : 0,
            "key_as_string" : "0",
            "doc_count" : 45960
          }, {
            "key" : 4,
            "key_as_string" : "4",
            "doc_count" : 26050
          }, {
            "key" : 5,
            "key_as_string" : "5",
            "doc_count" : 4556
          }, {
            "key" : 3,
            "key_as_string" : "3",
            "doc_count" : 2892
          }, {
            "key" : 2,
            "key_as_string" : "2",
            "doc_count" : 64
          }, {
            "key" : 1,
            "key_as_string" : "1",
            "doc_count" : 8
          } ]
        }
      }, {
        "key" : 3,
        "key_as_string" : "3",
        "doc_count" : 64681,
        "RATING_FOOD" : {
          "buckets" : [ {
            "key" : 0,
            "key_as_string" : "0",
            "doc_count" : 41631
          }, {
            "key" : 3,
            "key_as_string" : "3",
            "doc_count" : 17489
          }, {
            "key" : 4,
            "key_as_string" : "4",
            "doc_count" : 4145
          }, {
            "key" : 2,
            "key_as_string" : "2",
            "doc_count" : 1213
          }, {
            "key" : 5,
            "key_as_string" : "5",
            "doc_count" : 171
          }, {
            "key" : 1,
            "key_as_string" : "1",
            "doc_count" : 32
          } ]
        }
      }, {
        "key" : 5,
        "key_as_string" : "5",
        "doc_count" : 34744,
        "RATING_FOOD" : {
          "buckets" : [ {
            "key" : 0,
            "key_as_string" : "0",
            "doc_count" : 21702
          }, {
            "key" : 5,
            "key_as_string" : "5",
            "doc_count" : 11438
          }, {
            "key" : 4,
            "key_as_string" : "4",
            "doc_count" : 1488
          }, {
            "key" : 3,
            "key_as_string" : "3",
            "doc_count" : 106
          }, {
            "key" : 2,
            "key_as_string" : "2",
            "doc_count" : 9
          }, {
            "key" : 1,
            "key_as_string" : "1",
            "doc_count" : 1
          } ]
        }
      }, {
        "key" : 2,
        "key_as_string" : "2",
        "doc_count" : 14552,
        "RATING_FOOD" : {
          "buckets" : [ {
            "key" : 0,
            "key_as_string" : "0",
            "doc_count" : 11747
          }, {
            "key" : 2,
            "key_as_string" : "2",
            "doc_count" : 1845
          }, {
            "key" : 3,
            "key_as_string" : "3",
            "doc_count" : 568
          }, {
            "key" : 1,
            "key_as_string" : "1",
            "doc_count" : 254
          }, {
            "key" : 4,
            "key_as_string" : "4",
            "doc_count" : 126
          }, {
            "key" : 5,
            "key_as_string" : "5",
            "doc_count" : 12
          } ]
        }
      }, {
        "key" : 0,
        "key_as_string" : "0",
        "doc_count" : 7148,
        "RATING_FOOD" : {
          "buckets" : [ {
            "key" : 0,
            "key_as_string" : "0",
            "doc_count" : 6970
          }, {
            "key" : 4,
            "key_as_string" : "4",
            "doc_count" : 61
          }, {
            "key" : 3,
            "key_as_string" : "3",
            "doc_count" : 51
          }, {
            "key" : 5,
            "key_as_string" : "5",
            "doc_count" : 37
          }, {
            "key" : 2,
            "key_as_string" : "2",
            "doc_count" : 15
          }, {
            "key" : 1,
            "key_as_string" : "1",
            "doc_count" : 14
          } ]
        }
      }, {
        "key" : 1,
        "key_as_string" : "1",
        "doc_count" : 4971,
        "RATING_FOOD" : {
          "buckets" : [ {
            "key" : 0,
            "key_as_string" : "0",
            "doc_count" : 4217
          }, {
            "key" : 1,
            "key_as_string" : "1",
            "doc_count" : 474
          }, {
            "key" : 2,
            "key_as_string" : "2",
            "doc_count" : 158
          }, {
            "key" : 3,
            "key_as_string" : "3",
            "doc_count" : 87
          }, {
            "key" : 4,
            "key_as_string" : "4",
            "doc_count" : 26
          }, {
            "key" : 5,
            "key_as_string" : "5",
            "doc_count" : 9
          } ]
        }
      } ]
    }
  }
}
```

