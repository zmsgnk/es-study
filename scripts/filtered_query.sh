#!/usr/bin/sh

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
