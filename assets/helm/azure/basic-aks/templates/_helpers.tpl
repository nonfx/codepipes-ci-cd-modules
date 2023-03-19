{{- define "imageRegistryCredentials" }}
{{- with .Values.image.registryCredentials}}
  {{- printf "{\"auths\":{\"%s/\":{\"auth\":\"%s\"}}}" .registry  (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}
