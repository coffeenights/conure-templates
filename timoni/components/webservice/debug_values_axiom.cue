@if(debug_axiom)

package main

"values": {
	"resources": {
		"replicas": "1",
		"cpu":      "200m",
		"memory":   "256Mi"
	},
	"network": {
		"exposed":     true
		"serviceType": "ClusterIP"
		"ports": [
			{"hostPort": "7090", "targetPort": "7090", "protocol": "TCP"},
			{"hostPort": "9099", "targetPort": "9099", "protocol": "TCP"}
		]
		"ingress": {
			"host":      "axiom-bot.example.com"
			"port":      "7090"
			"className": "nginx"
			"annotations": {
				"cert-manager.io/cluster-issuer": "letsencrypt-prod"
			}
			"tls": {
				"secretName": "axiom-bot-tls"
			}
		}
	},
	"source": {
		"sourceType":      "oci"
		"ociRepository":   "git.conure.dev/mredvard/axiombot"
		"tag":             "latest"
		"command":         ["uv", "run", "--no-sync", "python", "-m", "performance_agent.main"]
		"workingDir":      "/app"
		"imagePullPolicy": "Always"
	},
	"storage": [
		{"size": "1Gi", "name": "data", "mountPath": "/app/_data"}
	]
}