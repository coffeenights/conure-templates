@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=test -t namespace=test -t mv=1.0.0 -t kv=1.28.0 build'.

"values": {
  "network": {
      "exposed": true,
      "ports": [
          {
              "hostPort": "8030",
              "targetPort": "8000",
              "protocol": "TCP"
          }
      ],
      "type": "public"
  },
  "resources": {
      "cpu": "200m",
      "memory": "256Mi",
      "replicas": "1"
  },
  "source": {
      "command": ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"],
      "ociRepository": "ghcr.io/mredvard/fastapi_demo",
      "tag": "latest",
      "sourceType": "oci",
      "workingDir": "/app",
      "imagePullPolicy": "Always"
  },
  "storage": []
}
