curl -XGET 'localhost:9200/ldgourmet/_search?pretty=true' -d '
{
  "query": {
    "bool": {
      "must": [
        {"term": {"address": "渋谷"}},
        {"term": {"name": "カレー"}}
      ]
    }
  },
  "sort": [{"access_count": {"order": "desc", "missing": "_last"}}],
  "size": 1
}'
