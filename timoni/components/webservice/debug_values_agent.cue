@if(debug_agent)

package main

"values": {
  "resources": {
    "replicas": "1",
    "cpu": "200m",
    "memory": "256Mi"
  },
  "network": {
    "exposed": true,
    "type": "public",
    "ports": [
      {
        "hostPort": "10090",
        "targetPort": "8000",
        "protocol": "TCP"
      }
    ]
  },
  "source": {
    "sourceType": "oci",
    "ociRepository": "dev.conure.local:30050/services/simple-agent",
    "tag": "latest",
    "command": ["/opt/env/bin/python", "runner/main.py"],
    "workingDir": "/app"
  },
  "variables": {
    "LOCAL_LLM_URL": "https://api.openai.com/v1/",
    "OPENAI_API_KEY": "<key>"
  }
}