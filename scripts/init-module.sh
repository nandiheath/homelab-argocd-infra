#!/bin/bash

usage() {
    cat <<EOM
  Usage:
    $(basename $0) init-module [module_name]

EOM
    exit 0
}

[[ $# < 1 ]] && { usage; }

module="$1"

# create base kustomize
mkdir -p "kustomize/bases/$module"

cat << EOF > "kustomize/bases/$module/kustomization.yaml"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources: []

EOF

# create overlay

mkdir -p "kustomize/overlay/homelab-rpi-cluster-1/$module"

cat << EOF > "kustomize/overlay/homelab-rpi-cluster-1/$module/kustomization.yaml"

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../../bases/$module

labels:
  - includeSelectors: false
    includeTemplates: true
    pairs:
      app.kubernetes.io/name: $module
      app.kubernetes.io/managed-by: argocd
      app.kubernetes.io/component: changeme
      app.kubernetes.io/version: changeme
EOF

echo "kustomize resources created."

# create argocd app
cat << EOF > "singularity/base/apps/$module.yaml"

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $module
spec:
  source:
    path: kustomize/overlay/homelab-rpi-cluster-1/$module
  destination:
    namespace: $module
  # Sync policy
  syncPolicy:
    # override the syncOptions
    syncOptions: # Sync options which modifies sync behavior
      - CreateNamespace=true # Namespace Auto-Creation ensures that namespace specified as the application destination exists in the destination cluster.

EOF

echo "argocd app created."

# modify the main kustomization

files=$(find singularity/base/apps -type f -name "*.yaml" |  awk -v q="\"" -F"/" '{print q$3"/"$4q}' | tr '\n' ',' )
files="[$files]" yq eval-all --inplace -P '.resources = env(files)' singularity/base/kustomization.yaml

echo "verifying kustomize resources .."
kustomize build singularity/base >/dev/null
echo "done."



