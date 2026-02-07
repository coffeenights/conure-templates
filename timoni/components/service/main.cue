package main

import "conure.io/service/templates"

instance: templates.#Instance & {
    config: values
}

output: [for obj in instance.objects {obj}]
