#!/usr/bin/sh

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