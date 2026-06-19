{{- define "openclaw.fullname" -}}
{{ .Values.botName }}-openclaw
{{- end }}

{{- define "openclaw.configMapName" -}}
{{- if .Values.configMapName -}}{{ .Values.configMapName }}
{{- else -}}{{ include "openclaw.fullname" . }}-config{{- end }}
{{- end }}

{{- define "openclaw.secretName" -}}
{{- if .Values.secretName -}}{{ .Values.secretName }}
{{- else -}}{{ include "openclaw.fullname" . }}-secrets{{- end }}
{{- end }}

{{- define "openclaw.sshKeySecretName" -}}
{{- if .Values.sshKeySecretName -}}{{ .Values.sshKeySecretName }}
{{- else -}}{{ include "openclaw.fullname" . }}-ssh-key{{- end }}
{{- end }}
