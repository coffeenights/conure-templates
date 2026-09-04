package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"strconv"
)

// Renders a #Probe as a Kubernetes tcpSocket probe spec.
#probeSpec: {
	#probe: #Probe
	tcpSocket: port: strconv.Atoi(#probe.port)
	if #probe.initialDelaySeconds != _|_ {
		initialDelaySeconds: #probe.initialDelaySeconds
	}
	if #probe.periodSeconds != _|_ {
		periodSeconds: #probe.periodSeconds
	}
	if #probe.failureThreshold != _|_ {
		failureThreshold: #probe.failureThreshold
	}
	if #probe.timeoutSeconds != _|_ {
		timeoutSeconds: #probe.timeoutSeconds
	}
}

#Deployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata 
	spec: appsv1.#DeploymentSpec & {
		replicas: strconv.Atoi(#config.resources.replicas)
		selector: matchLabels: #config.selector.labels
		if #config.strategy != _|_ {
			strategy: {
				type: "RollingUpdate"
				rollingUpdate: {
					if #config.strategy.maxUnavailable != _|_ {
						maxUnavailable: #config.strategy.maxUnavailable
					}
					if #config.strategy.maxSurge != _|_ {
						maxSurge: #config.strategy.maxSurge
					}
				}
			}
		}
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
				if #config.pod.terminationGracePeriodSeconds != _|_ {
					terminationGracePeriodSeconds: #config.pod.terminationGracePeriodSeconds
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
						if #config.pod.preStopSleepSeconds != _|_ {
							lifecycle: preStop: exec: command: [
								"sleep", "\(#config.pod.preStopSleepSeconds)",
							]
						}
						if #config.probes.readiness != _|_ {
							readinessProbe: #probeSpec & {#probe: #config.probes.readiness}
						}
						if #config.probes.startup != _|_ {
							startupProbe: #probeSpec & {#probe: #config.probes.startup}
						}
						if #config.probes.liveness != _|_ {
							livenessProbe: #probeSpec & {#probe: #config.probes.liveness}
						}
						resources: {
							requests: {
								cpu: #config.resources.requests.cpu
								memory: #config.resources.requests.memory
							}
							if #config.resources.limits != _|_ {
								limits: #config.resources.limits
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
