{{/*
Resource name for the webservice. Defaults to .Release.Name, overridable via .Values.nameOverride.
*/}}
{{- define "webservice.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Standard labels applied to all resources. Includes the user-supplied labels merged with
the Kubernetes recommended labels. `app.kubernetes.io/name` and `app.kubernetes.io/version`
are reserved and cannot be overridden.
*/}}
{{- define "webservice.labels" -}}
{{- $std := dict
  "app.kubernetes.io/name" (include "webservice.name" .)
  "app.kubernetes.io/version" (.Chart.AppVersion | toString)
  "app.kubernetes.io/managed-by" .Release.Service
  "app.kubernetes.io/instance" .Release.Name
-}}
{{- $merged := merge $std (.Values.labels | default dict) -}}
{{- toYaml $merged -}}
{{- end -}}

{{/*
Selector labels. Only the `app.kubernetes.io/name` label is selectable.
*/}}
{{- define "webservice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "webservice.name" . }}
{{- end -}}

{{/*
Container image. Mirrors the Timoni template, which uses
`#config.source.ociRepository` directly for both git and oci sources
(for git, the CLI writes the pushed image into ociRepository after build).
The tag is not appended here — it is expected to be part of ociRepository.
*/}}
{{- define "webservice.image" -}}
{{ .Values.source.ociRepository }}
{{- end -}}
