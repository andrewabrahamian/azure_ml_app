#!/bin/bash

#assign relevant variables
IMAGE_PREFIX=abrahaa
IMAGE_NAME=lab4
ACR_DOMAIN=w255mids.azurecr.io
COMMIT_HASH=$(git rev-parse --short HEAD)
#COMMIT_HASH=500e109

IMAGE_FQDN="${ACR_DOMAIN}/${IMAGE_PREFIX}/${IMAGE_NAME}:${COMMIT_HASH}"

#pull latest docker image
docker pull ${IMAGE_FQDN}

# First log in to Azure Container Registry
az acr login --name w255mids

# Shift to production deployment context
kubectl config use-context minikube

# Generate and apply kustomize files
kubectl kustomize .k8s/dev
kubectl apply -k .k8s/dev

# Review Output
kubectl logs deployment/lab4 -n ${IMAGE_PREFIX}

# Sleep to review the output
sleep 10