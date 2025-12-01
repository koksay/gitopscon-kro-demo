#!/bin/bash

cd $(dirname "$0")

kind create cluster --config kind-config.yaml

# install ArgoCD
kubectl apply -k argocd

# install KCC: https://docs.cloud.google.com/config-connector/docs/how-to/install-other-kubernetes
kubectl apply -f configconnector-operator.yaml

kubectl create namespace cnrm-system

kubectl create secret generic ${CREDENTIALS_SECRET_NAME} \
    --from-file key.json \
    --namespace cnrm-system

kubectl apply -f - <<EOF
apiVersion: core.cnrm.cloud.google.com/v1beta1
kind: ConfigConnector
metadata:
  # the name is restricted to ensure that there is only ConfigConnector
  # instance installed in your cluster
  name: configconnector.core.cnrm.cloud.google.com
spec:
  mode: cluster
  credentialSecretName: ${CREDENTIALS_SECRET_NAME}
  stateIntoSpec: Absent
EOF

kubectl apply -f - <<EOF
apiVersion: customize.core.cnrm.cloud.google.com/v1beta1
kind: ControllerResource
metadata:
  name: cnrm-webhook-manager
spec:
  replicas: 2
  containers:
    - name: webhook
      resources:
        limits:
          memory: 512Mi
        requests:
          memory: 256Mi
EOF

kubectl create ns kro-demo

kubectl annotate namespace kro-demo "cnrm.cloud.google.com/project-id=${GCP_PROJECT_ID}"
