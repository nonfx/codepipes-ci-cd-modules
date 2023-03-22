{{- define "imageRegistryCredentials" }}
  {{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.image.registryCredentials.registry (printf "%s:%s" .Values.image.registryCredentials.username .Values.image.registryCredentials.password | b64enc) | b64enc }}
{{- end }}
