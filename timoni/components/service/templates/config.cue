package templates

#Config: {
    replicas: int & >0
}

#Instance: {
    config: #Config

    objects: {
        deployment: #Deployment & {#config: config}
    }
}