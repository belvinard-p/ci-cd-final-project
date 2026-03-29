# Setting Up a Local CD Pipeline with OpenShift & Kubernetes on Windows

## Overview

This guide walks you through setting up a local Kubernetes/OpenShift environment on your Windows machine so you can practice CI/CD pipelines without relying on Coursera labs or cloud environments.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Option A: Minikube + Tekton (Lightweight)](#2-option-a-minikube--tekton-lightweight)
3. [Option B: OpenShift Local (Full OpenShift Experience)](#3-option-b-openshift-local-full-openshift-experience)
4. [Install Tekton on Your Cluster](#4-install-tekton-on-your-cluster)
5. [Install Tekton CLI (tkn)](#5-install-tekton-cli-tkn)
6. [Set Up Your Pipeline](#6-set-up-your-pipeline)
7. [Run and Monitor Your Pipeline](#7-run-and-monitor-your-pipeline)
8. [Access Your Deployed Application](#8-access-your-deployed-application)
9. [Useful Commands Cheat Sheet](#9-useful-commands-cheat-sheet)
10. [Troubleshooting](#10-troubleshooting)
11. [Comparison: Minikube vs OpenShift Local](#11-comparison-minikube-vs-openshift-local)

---

## 1. Prerequisites

### Hardware Requirements
- **RAM**: Minimum 8GB (16GB recommended)
- **Disk**: At least 40GB free space
- **CPU**: 4+ cores recommended

### Software to Install

| Tool | Purpose | Install Command / Link |
|------|---------|----------------------|
| Docker Desktop | Container runtime | https://www.docker.com/products/docker-desktop/ |
| kubectl | Kubernetes CLI | https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/ |
| Git | Version control | Already installed |
| Node.js | App runtime | Already installed |

### Install kubectl

Download and add to PATH:
```powershell
curl.exe -LO "https://dl.k8s.io/release/v1.30.0/bin/windows/amd64/kubectl.exe"
```
Move `kubectl.exe` to a folder in your PATH (e.g., `C:\tools\`) and add that folder to your system PATH.

Verify:
```powershell
kubectl version --client
```

---

## 2. Option A: Minikube + Tekton (Lightweight)

Best for: Learning Kubernetes and Tekton without heavy resource usage.

### Step 1: Install Minikube

Download from https://minikube.sigs.k8s.io/docs/start/ or:
```powershell
curl.exe -LO https://storage.googleapis.com/minikube/releases/latest/minikube-windows-amd64.exe
rename minikube-windows-amd64.exe minikube.exe
```
Move `minikube.exe` to a folder in your PATH.

### Step 2: Start Minikube

```powershell
minikube start --cpus=4 --memory=8192 --driver=docker
```

This creates a single-node Kubernetes cluster inside Docker.

### Step 3: Verify

```powershell
kubectl cluster-info
kubectl get nodes
```

You should see one node in `Ready` status.

### Step 4: Enable the Registry Add-on

To store Docker images locally:
```powershell
minikube addons enable registry
```

### Step 5: Access the Dashboard (Optional)

```powershell
minikube dashboard
```

This opens a web UI similar to the OpenShift console.

---

## 3. Option B: OpenShift Local (Full OpenShift Experience)

Best for: Replicating the exact Coursera lab experience locally.

### Step 1: Download OpenShift Local (formerly CodeReady Containers)

1. Go to https://console.redhat.com/openshift/create/local
2. Create a free Red Hat account if you don't have one
3. Download the installer for Windows
4. Download the **pull secret** (you'll need it during setup)

### Step 2: Install and Setup

```powershell
crc setup
```

This takes 10-20 minutes. It configures a local VM with OpenShift.

### Step 3: Start OpenShift Local

```powershell
crc start
```

It will ask for the pull secret — paste the one you downloaded.

First start takes 10-15 minutes. It will output:
- Console URL
- Username/password (usually `developer`/`developer` or `kubeadmin`/`<generated>`)

### Step 4: Login

```powershell
eval $(crc oc-env)
oc login -u developer https://api.crc.testing:6443
```

### Step 5: Access the Console

```powershell
crc console
```

Opens the OpenShift web console in your browser — same UI as the Coursera lab.

### Managing OpenShift Local

```powershell
crc stop      # Stop the cluster (preserves data)
crc start     # Start it again
crc delete    # Delete everything and start fresh
crc status    # Check if it's running
```

---

## 4. Install Tekton on Your Cluster

### For Minikube

```powershell
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

Wait for Tekton to be ready:
```powershell
kubectl get pods -n tekton-pipelines --watch
```

All pods should show `Running` status.

### For OpenShift Local

Tekton (OpenShift Pipelines) can be installed via the OperatorHub:

```powershell
# Create the subscription for OpenShift Pipelines operator
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator
  namespace: openshift-operators
spec:
  channel: latest
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
```

Or install it from the OpenShift console: **Operators → OperatorHub → search "OpenShift Pipelines" → Install**.

---

## 5. Install Tekton CLI (tkn)

Download from https://github.com/tektoncd/cli/releases

For Windows, download the `.zip` file, extract `tkn.exe`, and add it to your PATH.

Verify:
```powershell
tkn version
```

---

## 6. Set Up Your Pipeline

### Step 1: Create a Namespace/Project

```powershell
# Minikube
kubectl create namespace ci-cd-project
kubectl config set-context --current --namespace=ci-cd-project

# OpenShift Local
oc new-project ci-cd-project
```

### Step 2: Install Your Custom Tasks

```powershell
kubectl apply -f .tekton/tasks.yml
```

Verify:
```powershell
kubectl get tasks
```

### Step 3: Install Cluster Tasks (git-clone, buildah)

For Minikube (these come pre-installed on OpenShift):
```powershell
# Install git-clone task
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.9/git-clone.yaml

# Install buildah task
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/buildah/0.6/buildah.yaml
```

### Step 4: Create PVC

```powershell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pipeline-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
EOF
```

### Step 5: Create the Pipeline

Save this as `pipeline.yml`:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: cd-pipeline
spec:
  params:
    - name: repo-url
      type: string
      default: "https://github.com/<your-username>/ci-cd-final-project.git"
    - name: branch
      type: string
      default: "main"
    - name: app-name
      type: string
      default: "counter-service"
    - name: build-image
      type: string
  workspaces:
    - name: output
  tasks:
    - name: cleanup
      taskRef:
        name: cleanup
      workspaces:
        - name: source
          workspace: output
    - name: git-clone
      taskRef:
        name: git-clone
      runAfter:
        - cleanup
      params:
        - name: url
          value: $(params.repo-url)
        - name: revision
          value: $(params.branch)
      workspaces:
        - name: output
          workspace: output
    - name: eslint
      taskRef:
        name: eslint
      runAfter:
        - git-clone
      workspaces:
        - name: source
          workspace: output
    - name: jest-test
      taskRef:
        name: jest-test
      runAfter:
        - git-clone
      workspaces:
        - name: source
          workspace: output
    - name: buildah
      taskRef:
        name: buildah
      runAfter:
        - eslint
        - jest-test
      params:
        - name: IMAGE
          value: $(params.build-image)
      workspaces:
        - name: source
          workspace: output
```

Apply it:
```powershell
kubectl apply -f pipeline.yml
```

---

## 7. Run and Monitor Your Pipeline

### Start the Pipeline

```powershell
# For Minikube (using local registry)
tkn pipeline start cd-pipeline \
  -p repo-url="https://github.com/<your-username>/ci-cd-final-project.git" \
  -p branch="main" \
  -p app-name="counter-service" \
  -p build-image="localhost:5000/counter-service:latest" \
  -w name=output,claimName=pipeline-pvc

# For OpenShift Local
tkn pipeline start cd-pipeline \
  -p repo-url="https://github.com/<your-username>/ci-cd-final-project.git" \
  -p branch="main" \
  -p app-name="counter-service" \
  -p build-image="image-registry.openshift-image-registry.svc:5000/ci-cd-project/counter-service:latest" \
  -w name=output,claimName=pipeline-pvc
```

### Watch Logs

```powershell
tkn pipelinerun logs -f --last
```

### Check Status

```powershell
tkn pipelinerun describe --last
```

### List All Runs

```powershell
tkn pipelinerun list
```

---

## 8. Access Your Deployed Application

### On Minikube

```powershell
# Create the deployment
kubectl create deployment counter-service --image=localhost:5000/counter-service:latest

# Expose it
kubectl expose deployment counter-service --type=NodePort --port=8000

# Get the URL
minikube service counter-service --url
```

Open the URL in your browser — you should see the Counter Service response.

### On OpenShift Local

```powershell
# Create a route to expose the app
oc expose deployment counter-service --port=8000
oc expose svc counter-service

# Get the URL
oc get route counter-service -o jsonpath='{.spec.host}'
```

### Test the API

```powershell
# Replace <URL> with the URL from above
curl <URL>/health
curl <URL>/counters
curl -X POST <URL>/counters/mycount
curl <URL>/counters/mycount
curl -X PUT <URL>/counters/mycount
curl -X DELETE <URL>/counters/mycount
```

---

## 9. Useful Commands Cheat Sheet

### Kubernetes / kubectl

| Command | Description |
|---------|-------------|
| `kubectl get pods` | List all pods |
| `kubectl get deployments` | List deployments |
| `kubectl get svc` | List services |
| `kubectl logs <pod-name>` | View pod logs |
| `kubectl describe pod <pod-name>` | Pod details |
| `kubectl delete deployment <name>` | Delete a deployment |
| `kubectl get all` | List everything |
| `kubectl get events --sort-by=.metadata.creationTimestamp` | Recent events |

### Tekton / tkn

| Command | Description |
|---------|-------------|
| `tkn task list` | List all tasks |
| `tkn pipeline list` | List all pipelines |
| `tkn pipelinerun list` | List all pipeline runs |
| `tkn pipelinerun logs -f --last` | Stream latest run logs |
| `tkn pipelinerun describe --last` | Describe latest run |
| `tkn pipeline describe <name>` | Describe a pipeline |
| `tkn task describe <name>` | Describe a task |

### OpenShift / oc (additional to kubectl)

| Command | Description |
|---------|-------------|
| `oc new-project <name>` | Create a project |
| `oc project` | Show current project |
| `oc get routes` | List exposed routes |
| `oc expose svc <name>` | Create a route |
| `oc whoami` | Current user |
| `oc status` | Project overview |

### Minikube

| Command | Description |
|---------|-------------|
| `minikube start` | Start cluster |
| `minikube stop` | Stop cluster |
| `minikube delete` | Delete cluster |
| `minikube status` | Check status |
| `minikube dashboard` | Open web UI |
| `minikube service <name> --url` | Get service URL |

---

## 10. Troubleshooting

### Pod stuck in `Pending`

```powershell
kubectl describe pod <pod-name>
```
Common causes:
- Not enough CPU/memory → increase Minikube resources: `minikube start --cpus=4 --memory=8192`
- PVC not bound → check `kubectl get pvc`

### Pod in `CrashLoopBackOff`

```powershell
kubectl logs <pod-name> --previous
```
Common causes:
- Application error → check the logs
- Wrong image name → verify the image exists

### Pipeline task fails

```powershell
tkn pipelinerun logs --last
tkn taskrun describe <taskrun-name>
```

### Minikube won't start

```powershell
minikube delete
minikube start --cpus=4 --memory=8192 --driver=docker
```

### OpenShift Local won't start

```powershell
crc delete
crc setup
crc start
```

### Image pull errors

For Minikube, make sure the registry addon is enabled:
```powershell
minikube addons enable registry
```

For OpenShift Local, the internal registry is enabled by default.

### Permission denied errors in Tekton tasks

Add security context to the task step:
```yaml
securityContext:
  runAsNonRoot: false
  runAsUser: 0
```

---

## 11. Comparison: Minikube vs OpenShift Local

| Feature | Minikube | OpenShift Local |
|---------|----------|-----------------|
| **RAM needed** | 4-8 GB | 9-14 GB |
| **Disk needed** | 20 GB | 35 GB |
| **Setup time** | 5 min | 20-30 min |
| **Web console** | Basic dashboard | Full OpenShift console |
| **Tekton** | Manual install | Install via Operator |
| **Built-in tasks** | Must install from catalog | Pre-installed (git-clone, buildah, etc.) |
| **Routes/Ingress** | NodePort / Ingress addon | Built-in Routes |
| **Closest to production** | Generic Kubernetes | OpenShift (enterprise) |
| **Best for** | Learning Kubernetes basics | Replicating Coursera lab |
| **Cost** | Free | Free (Red Hat account needed) |

### Recommendation

- **Start with Minikube** if you have limited resources (< 16GB RAM) or just want to learn Kubernetes + Tekton basics
- **Use OpenShift Local** if you have 16GB+ RAM and want the exact same experience as the Coursera lab

---

## Quick Start Summary

```powershell
# 1. Start your cluster
minikube start --cpus=4 --memory=8192 --driver=docker

# 2. Install Tekton
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

# 3. Wait for Tekton to be ready
kubectl get pods -n tekton-pipelines --watch

# 4. Create namespace
kubectl create namespace ci-cd-project
kubectl config set-context --current --namespace=ci-cd-project

# 5. Install tasks
kubectl apply -f .tekton/tasks.yml

# 6. Install catalog tasks
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.9/git-clone.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/buildah/0.6/buildah.yaml

# 7. Create PVC
kubectl apply -f pipeline-pvc.yml

# 8. Create and run pipeline
kubectl apply -f pipeline.yml
tkn pipeline start cd-pipeline -w name=output,claimName=pipeline-pvc

# 9. Watch it run
tkn pipelinerun logs -f --last
```

You're now running your own CD pipeline locally! 🚀
