# es-study #

Elasticsearchの勉強のメモです。

## Livedoorグルメの研究用データセットを登録する ##

Livedoorグルメの研究用データセットをESに投入します。
https://github.com/livedoor/datasets

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



