#!/usr/bin/sh

curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d '
{
	"query": {
	  "simple_query_string": {
	    "query": "渋谷 カレー",
	    "fields": ["name", "address"],
	    "default_operator": "and"
	  }
  },
  "size": 1
}'
