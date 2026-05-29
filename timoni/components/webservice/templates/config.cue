package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)


#Port: {
	hostPort: string
	targetPort: string
	protocol: corev1.#Protocol
}

#Storage: {
	size: string
	name: string
	mountPath: string
}

#IngressPath: {
	path:     *"/" | string
	pathType: *"Prefix" | "Exact" | "ImplementationSpecific"
	port:     string
}

#IngressConfig: {
	host:       string
	className?: string
	paths: [_, ...] & [...#IngressPath]
	tls?: {
		secretName: string
		hosts?: [...string]
	}
	annotations?: {[string]: string}
}

// Config defines the schema and defaults for the Instance values.
#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion!: string
	// Using the kubeVersion you can enforce a minimum Kubernetes minor version.
	// By default, the minimum Kubernetes version is set to 1.20.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	// instanceName!: timoniv1.#InstanceName
	// namespace!:    timoniv1.#Namespace

	// The moduleVersion is set from the user-supplied module version.
	// This field is used for the `app.kubernetes.io/version` label.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	// The `metadata.name` and `metadata.namespace` fields are
	// set from the user-supplied instance name and namespace.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// The labels allows adding `metadata.labels` to all resources.
	// The `app.kubernetes.io/name` and `app.kubernetes.io/version` labels
	// are automatically generated and can't be overwritten.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// Pod-level settings applied to the Deployment's pod template.
	pod?: {
		// Annotations added to the pod template.
		annotations?: {[string]: string}
		// Name of an existing ServiceAccount the pod runs as.
		serviceAccountName?: string
	}

	resources: {
		replicas: string //int & >=0
		cpu:      timoniv1.#CPUQuantity
		memory:   timoniv1.#MemoryQuantity
	}
	source: {
		sourceType: "git" | "oci"
		// ociRepository is the registry path the workload pulls from.
		// For sourceType=="git" it's also the push target the CLI writes
		// after a successful build. User-supplied; see
		// docs/container-registries.md for the per-provider format.
		ociRepository: string
		tag: string
		if sourceType == "git" {
			gitRepository: string
			gitBranch: string
			// buildTool selects which builder produces the image. The CLI
			// honors this on `conure deploy --image-ref ...`. Railpack is
			// supported only when buildLocation == "local" — the remote
			// BuildKit Job ships the dockerfile.v0 frontend.
			buildTool: "railpack" | *"dockerfile"
			if buildTool == "dockerfile" {
					dockerfilePath: string
			}
			// buildLocation tells the CLI where to run the build. "local"
			// builds on the developer's machine (or CI) and pushes the
			// image, then asks the API to record + deploy. "remote" hands
			// the git ref to the API, which runs a BuildKit Job inside
			// the cluster.
			buildLocation: "local" | *"remote"
    	}
		command: [...string]
		workingDir: string
		imagePullSecrets?: string
		imagePullPolicy: "Always" | *"IfNotPresent"
	}
	network: {
		exposed:     bool
		// Deprecated: kept for transition. Use `serviceType` to control Service type
		// and `exposed` (with `ingress`) to provision an Ingress.
		type?: "public" | "private"
		serviceType: *"ClusterIP" | "LoadBalancer" | "NodePort"
		ports: [...#Port]
		ingress?: #IngressConfig
	}
	storage?: [...#Storage]
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
			deploy: #Deployment & {#config: config}
			service: #Service & {#config: config}
			if config.network.exposed && config.network.ingress != _|_ {
				ingress: #Ingress & {#config: config}
			}
			if config.storage != _|_ {
				for index, value in config.storage {
					"\(config.metadata.name)-pvc-\(index)": #PVC & {#config: config, #index: index, #value: value}
				}
			}

	}
}
