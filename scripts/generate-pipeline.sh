#!/bin/bash
set -euo pipefail

tenants=$(buildkite-agent meta-data get tenants)
# Get and clean tenant list
TENANTS=$(echo "${tenants}" | tr -d '[:space:]' | tr ',' '\n')

buildkite-agent annotate --style 'info' <<EOF
## Client List

printf '```text\n%s\n```' "$tenants"

<details>
  <summary>Click to view all 100 clients</summary>
  
$(echo "$TENANTS" | sed 's/^/- /')

</details>
EOF

# Create temporary pipeline file
PIPELINE_FILE=$(mktemp)

cat << YAML > "$PIPELINE_FILE"
steps:
YAML

# Generate tenant-specific steps
while IFS= read -r tenant; do
  if [ -n "$tenant" ]; then
    cat << YAML >> "$PIPELINE_FILE"
  - group: ":aws: Deploy to ${tenant}"
    key: "deploy-${tenant}"
    steps:
      - label: ":rocket: Apply Spoke for ${tenant}"
        command: "echo ./apply-spoke.sh ${tenant}"
        key: "apply-${tenant}"
        retry:
          automatic: true
        plugins:
          - kubernetes:
              gitEnvFrom:
                - secretRef:
                    name: my-git-ssh-credentials
              podSpecPatch:
                containers:
                - name: container-0
                  resources:
                    requests:
                      cpu: 250m
                      memory: 50Mi
                    limits:
                      cpu: 250m
                      memory: 1Gi
      
      - label: ":test_tube: Run Integration Tests for ${tenant}"
        command: "echo ./run-tests.sh ${tenant}"
        depends_on: "apply-${tenant}"
        retry:
          automatic: true
        plugins:
          - kubernetes:
              gitEnvFrom:
                - secretRef:
                    name: my-git-ssh-credentials
              podSpecPatch:
                containers:
                - name: container-0
                  resources:
                    requests:
                      cpu: 250m
                      memory: 50Mi
                    limits:
                      cpu: 250m
                      memory: 1Gi
YAML
  fi
done <<< "$TENANTS"

# Upload generated pipeline
buildkite-agent pipeline upload "$PIPELINE_FILE"
