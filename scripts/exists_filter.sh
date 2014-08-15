#!/usr/bin/sh

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
