{{/*
Resource name for the stackgres cluster. Defaults to .Release.Name, overridable via .Values.nameOverride.
*/}}
{{- define "stackgres.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Standard labels applied to all resources. Includes the user-supplied labels merged with
the Kubernetes recommended labels. `app.kubernetes.io/name` and `app.kubernetes.io/version`
are reserved and cannot be overridden.
*/}}
{{- define "stackgres.labels" -}}
{{- $std := dict
  "app.kubernetes.io/name" (include "stackgres.name" .)
  "app.kubernetes.io/version" (.Chart.AppVersion | toString)
  "app.kubernetes.io/managed-by" .Release.Service
  "app.kubernetes.io/instance" .Release.Name
-}}
{{- $merged := merge $std (.Values.labels | default dict) -}}
{{- toYaml $merged -}}
{{- end -}}

{{/*
Names of the dependent StackGres resources, derived from the cluster name.
*/}}
{{- define "stackgres.profileName" -}}
{{ include "stackgres.name" . }}-profile
{{- end -}}

{{- define "stackgres.configName" -}}
{{ include "stackgres.name" . }}-config
{{- end -}}

{{- define "stackgres.scriptName" -}}
{{ include "stackgres.name" . }}-init-script
{{- end -}}
