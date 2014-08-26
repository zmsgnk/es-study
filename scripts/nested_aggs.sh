#!/usr/bin/sh

curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true&search_type=count' -d '
{
  "aggs": {
    "RATING_TOTAL": {
      "terms": {"field": "total"},
      "aggs": {
        "RATING_FOOD": {
          "terms": {"field": "food"}
        }
      }
    }
  }
}'
