# es-study #

Elasticsearchの勉強用メモです。

## Livedoorグルメの研究用データセットを登録する ##

Livedoorグルメの研究用データセットをESに投入します。
https://github.com/livedoor/datasets  

データセットの詳細については以下のブログを参照。

http://blog.livedoor.jp/techblog/archives/65836960.html


```
git clone https://github.com/livedoor/datasets.git
cd datasets
tar xvf ldgourmet.tar.gz
```

## インデックスの登録 ##

```
curl -XPOST localhost:9200/ldgourmet -d @mapping.json
```

## データの登録 ##



