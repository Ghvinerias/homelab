#curl -u qbit:qbit -H "Content-Type: application/json"   -X POST http://10.10.40.19:15672/api/exchanges/media-automation/amq.default/publish   -d '{"properties": {},"routing_key": "mkvmerge","payload": "{\"torrentName\":\"$1\",\"category\":\"$2\"}","payload_encoding": "string"}'
#!/bin/bash
set +x
curl -u qbit:qbit -H "Content-Type: application/json" \
  -X POST http://10.10.40.19:15672/api/exchanges/media-automation/amq.default/publish \
  -d "{\"properties\": {}, \"routing_key\": \"mkvmerge.tasks\", \"payload\": \"{\\\"torrentName\\\":\\\"$1\\\",\\\"category\\\":\\\"$2\\\"}\", \"payload_encoding\": \"string\"}"

