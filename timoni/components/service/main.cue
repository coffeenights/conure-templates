package main

import "ghcr.io/coffeenights/conure-templates/service/templates"

values: templates.#Config

instance: templates.#Instance & {
    config: values
}

output: [for obj in instance.objects {obj}]
