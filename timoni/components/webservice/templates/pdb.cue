package templates

import (
	"strconv"
)

// PodDisruptionBudget guarding voluntary disruptions (node drains,
// cluster upgrades). Rendered only when `pdb` is set in the values; keep
// minAvailable below the replica count or drains block outright.
#PodDisruptionBudget: {
	#config:    #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata:   #config.metadata
	spec: {
		minAvailable: strconv.Atoi(#config.pdb.minAvailable)
		selector: matchLabels: #config.selector.labels
	}
}
