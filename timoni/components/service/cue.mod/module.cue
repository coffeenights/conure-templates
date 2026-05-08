module: "ghcr.io/coffeenights/conure-templates/service@v0"
language: {
	version: "v0.15.1"
}
source: {
	kind: "self"
}
deps: {
	"cue.dev/x/k8s.io@v0": {
		v:       "v0.6.0"
		default: true
	}
}
