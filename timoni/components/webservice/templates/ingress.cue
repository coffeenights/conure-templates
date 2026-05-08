package templates

import (
	"strconv"
)

#Ingress: {
	#config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata:   #config.metadata
	if #config.network.ingress.annotations != _|_ {
		metadata: annotations: #config.network.ingress.annotations
	}
	spec: {
		if #config.network.ingress.className != _|_ {
			ingressClassName: #config.network.ingress.className
		}
		if #config.network.ingress.tls != _|_ {
			tls: [{
				secretName: #config.network.ingress.tls.secretName
				if #config.network.ingress.tls.hosts != _|_ {
					hosts: #config.network.ingress.tls.hosts
				}
				if #config.network.ingress.tls.hosts == _|_ {
					hosts: [#config.network.ingress.host]
				}
			}]
		}
		rules: [{
			host: #config.network.ingress.host
			http: paths: [ for p in #config.network.ingress.paths {
				path:     p.path
				pathType: p.pathType
				backend: service: {
					name: #config.metadata.name
					port: number: strconv.Atoi(p.port)
				}
			}]
		}]
	}
}