#!/usr/bin/sh

curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d'
{
  "query": {
    "filtered": {
    	"filter": {
    		"and": [{
    			"range": {
    				"total": {
    					"from": "4",
    					"to": "5"
    				}
    			}
    		},
    		{
    			"term": {"body": "カレー"}
    		},
    		{
    			"term": {"body": "渋谷"}
    		}]
    	}
    }
  },
  "size": 1
}'
