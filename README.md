# KRO (Kubernetes Resource Operator) Demo with GCP

## Setup Kind Cluster (with KCC)

We first create a Kind cluster and deploy KCC (k8s-config-connector) on the cluster to be able to manage resources on GCP:

> [!IMPORTANT]
> `setup_kind_cluster.sh` script assumes that a file called `key.json` exists in the `setup` directory with the service account key json file
>
> Make sure the create a service account with required roles before starting the script.

```bash
# check what script runs:
cat ./setup/setup_kind_cluster.sh

# export some env vars:
export GCP_PROJECT_ID="gitopscon-na"
export CREDENTIALS_SECRET_NAME=gcp-credentials

# run it
./setup/setup_kind_cluster.sh

# make sure all pods are running
kubectl get pods -A
```

## Deploy KRO

Deploy KRO using the Helm Chart:

```bash
export KRO_VERSION=0.7.0

helm install kro oci://registry.k8s.io/kro/charts/kro \
  --namespace kro \
  --create-namespace \
  --version=${KRO_VERSION}

kubectl wait -n kro --for=condition=Ready pod --all --timeout=600s
```

## GitOps (w/ ArgoCD)

Check the ArgoCD Apps and manifests:

### ResourceGraphDefinition:

This one will create our Webapp RGD:

```bash
cat clusters/kind/resourcegraphdefinitions/rgd-webapp.yaml
```

### Webapp Resource

Create the Webapp resource:

```bash
cat > clusters/kind/manifests/webapp.yaml <<EOF
apiVersion: kro.run/v1alpha1
kind: Webapp
metadata:
  name: demo-app
  namespace: kro-demo
spec:
  name: demo-$(openssl rand -hex 2)
  project: ${GCP_PROJECT_ID}
  region: europe-west1
  model: meta-llama/Llama-3.2-1B-Instruct
EOF
```

---

Commit changes and see ArgoCD deploys them:

```bash
git add .
git commit -sam "Add webapp app"
git push

# Create app-of-apps to enable GitOps:
kubectl apply -f clusters/kind/app-of-apps.yaml

kubectx argocd
argocd admin dashboard
```

When all synced, check current resources on Kubernetes and GCP:

```bash
kubectl api-resources --api-group=kro.run 

kubectl get deploy,svc -n kro-demo
kubectl get webapp -n kro-demo

gcloud auth activate-service-account --key-file=./setup/key.json
gcloud sql instances list
gcloud storage buckets list
```
