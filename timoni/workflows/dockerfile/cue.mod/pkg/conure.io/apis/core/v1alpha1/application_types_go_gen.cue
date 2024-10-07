// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/coffeenights/conure/apis/core/v1alpha1

package v1alpha1

import metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

// ApplicationSpec defines the desired state of Application
#ApplicationSpec: {
	components: [...#Component] @go(Components,[]Component)
}

// ApplicationStatus defines the observed state of Application
#ApplicationStatus: {
}

// Application is the Schema for the applications API
#Application: {
	metav1.#TypeMeta
	metadata?: metav1.#ObjectMeta @go(ObjectMeta)
	spec?:     #ApplicationSpec   @go(Spec)
	status?:   #ApplicationStatus @go(Status)
}

// ApplicationList contains a list of Application
#ApplicationList: {
	metav1.#TypeMeta
	metadata?: metav1.#ListMeta @go(ListMeta)
	items: [...#Application] @go(Items,[]Application)
}
