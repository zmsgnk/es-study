#!/usr/bin/sh

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