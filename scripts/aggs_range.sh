#!/usr/bin/sh

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
	},
	"size": 0
}'
