#!/usr/bin/sh

curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d '
{
	"query": {"match_all": {}},
	"aggs": {
		"pct_photo_count": {
			"percentiles": {
				"field": "photo_count",
				"percents": [95.0, 96.0, 97.0, 98.0, 99.0]
			}
		}
	},
	"size": 0
}'