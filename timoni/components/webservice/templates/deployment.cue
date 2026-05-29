package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"strconv"
)

#Deployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata 
	spec: appsv1.#DeploymentSpec & {
		replicas: strconv.Atoi(#config.resources.replicas)
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if #config.pod.annotations != _|_ {
					annotations: #config.pod.annotations
				}
			}
			spec: corev1.#PodSpec & {
				if #config.pod.serviceAccountName != _|_ {
					serviceAccountName: #config.pod.serviceAccountName
				}
				containers: [
					{
						name: #config.metadata.name
						image: #config.source.ociRepository
						if #config.source.command != _|_ {
							command: #config.source.command
						}
						workingDir: #config.source.workingDir
						imagePullPolicy: #config.source.imagePullPolicy
						resources: {
							requests: {
								cpu: #config.resources.cpu
								memory: #config.resources.memory
							},
							limits: {
								cpu: #config.resources.cpu
								memory: #config.resources.memory
							}
						}
						if #config.storage != _|_ {
							volumeMounts: [for item in #config.storage {
								mountPath: item.mountPath
								name: item.name
							}]
						}
						envFrom: [
							{
								configMapRef: {
									name: #config.metadata.name + "-variables"
								}
							},
							{
								secretRef: {
									name: #config.metadata.name + "-secrets"
								}
							},
						]
					}
				]
				if #config.storage != _|_ {
					volumes: [for item in #config.storage {
						name: item.name
						persistentVolumeClaim: {
							claimName: #config.metadata.name + "-" + item.name
						}
					}]
				}
				if #config.source.imagePullSecrets != _|_ {
					imagePullSecrets: [{name: #config.source.imagePullSecrets}]
				}
			}
		}
	}
}
