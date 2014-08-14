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
curl -XPOST localhost:9200/ldgourmet -d @mapping.json
```

## データの登録 ##

## query と filter ##

Elasticsearchの検索には、`query`と`filter`を使います。
それぞれ、`query`には*約40種類*、`filter`には*約30種類*あります。

- [reference [1.x] » query dsl » queries](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-queries.html)
- [reference [1.x] » query dsl » filters](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-filters.html)