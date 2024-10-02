#!/bin/bash

#assign relevant variables
IMAGE_PREFIX=abrahaa
IMAGE_NAME=lab4
ACR_DOMAIN=w255mids.azurecr.io
COMMIT_HASH=$(git rev-parse --short HEAD)

IMAGE_FQDN="${ACR_DOMAIN}/${IMAGE_PREFIX}/${IMAGE_NAME}:${COMMIT_HASH}"

#apply to both /base and /prod depoyment files
#/base
#cp .k8s/base/deployment-lab4.yaml .k8s/base/deployment-lab4_copy.yaml
sed "s/\[COMMIT_HASH\]/${COMMIT_HASH}/g" .k8s/base/deployment-lab4_copy.yaml > .k8s/base/deployment-lab4.yaml
#/prod
#cp .k8s/prod/patch-deployment-lab4.yaml .k8s/prod/patch-deployment-lab4_copy.yaml
sed "s/\[COMMIT_HASH\]/${COMMIT_HASH}/g" .k8s/prod/patch-deployment-lab4_copy.yaml > .k8s/prod/patch-deployment-lab4.yaml

#build docker container
docker build -t ${IMAGE_NAME} .

# Tag and push latest docker container into ACR
docker tag ${IMAGE_NAME} ${IMAGE_FQDN}
docker push ${IMAGE_FQDN}

# First log in to Azure Container Registry
az acr login --name w255mids

# Shift to production deployment context
kubectl config use-context w255-aks

# Generate and apply kustomize files
kubectl kustomize .k8s/prod
kubectl apply -k .k8s/prod

# Review Output
kubectl logs deployment/lab4 -n ${IMAGE_PREFIX}

# Sleep to review the output
sleep 10
