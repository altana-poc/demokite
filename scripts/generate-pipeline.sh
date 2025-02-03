#!/bin/bash
set -euo pipefail

# Get and clean tenant list
TENANTS=$(buildkite-agent meta-data get tenants | tr -d '[:space:]' | tr ',' '\n')

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
