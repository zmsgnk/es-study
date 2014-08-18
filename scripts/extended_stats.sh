#!/usr/bin/sh

curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d '
{
	"query": {"match_all": {}},
	"aggs": {"rating_stats": {"extended_stats": {"field": "total"}}},
	"size": 0
}'