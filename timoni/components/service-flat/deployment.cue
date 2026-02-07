package service

import appsv1 "cue.dev/x/k8s.io/api/apps/v1"

deployment: appsv1.#Deployment & {
    apiVersion: "apps/v1"
    kind:       "Deployment"
    metadata: name: "myapp"
    spec: {
        replicas: values.replicas
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
