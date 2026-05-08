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
        "hostPort": "8030",
        "targetPort": "8000",
        "protocol": "TCP"
      }
    ]
  },
  "source": {
    "sourceType": "oci",
    "ociRepository": "ghcr.io/mredvard/fastapi_demo",
    "tag": "latest",
    "command": ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
    "workingDir": "/app"
  }
}