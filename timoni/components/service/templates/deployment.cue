package templates

import appsv1 "cue.dev/x/k8s.io/api/apps/v1"

#Deployment: appsv1.#Deployment & {
    #config: #Config
    apiVersion: "apps/v1"
    kind:       "Deployment"
    metadata: name: "myapp"
    spec: {
        replicas: #config.replicas
        selector: matchLabels: app: "myapp"
        template: {
            metadata: labels: app: "myapp"
            spec: containers: [{
                name:  "myapp"
                image: "myapp:latest"
            }]
        }
    }
}
