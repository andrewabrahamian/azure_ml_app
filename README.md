# Lab 4: Deploying FastAPI Machine Learning Application in Kubernetes to the Cloud

This project is a FastAPI application that interacts with a machine learning model, is containerized with Docker, orchestrated with Kubernetes, and deployed to Azure Kubernetes Service. 

## What does this Application do?
It exposes an API deployed to Azure Kubernetes Service with the following endpoints:
- `/hello`: Accepts a query parameter `{NAME}` and returns a JSON response with the greeting message, `hello {NAME}`.
- `/predict`: Accepts a single object composed of 8 float values, matching the shape of input features of the `California Housing dataset`
- `/bulk_predict`: Accepts a list of objects, each composed of 8 float values, matching the shape of input features of the `California Housing dataset`
- `/`: Returns a "Not Found" response with an HTTP Status Code of 404 (Not Found).
- `/docs`: Provides browsable API documentation while the API is running.
- `/openapi.json`: Provides the OpenAPI specification in JSON format.

## How to Access the Application

Be sure that `Azure CLI` is installed and running on your local machine.

Clone this repository to your local machine:

```git clone https://github.com/UCB-W255/fall23-andrewabrahamian``` 
```cd lab_4/lab4```

## How to Build and Run the Application

Run the following bash script in the root directory. This script builds the application, pushes it to Azure Container Registry (ACR), and runs it into your production environment in Azure Kubernetes Service (AKS). 

```poetry run buildpush.sh```

Be sure to assign the specific user name so the application runs in your personal namespace on AKS!

## Example curl request to test against /predict and /bulk_predict

### /bulk_predict
```
NAMESPACE=abrahaa
curl -X 'POST' 'https://${NAMESPACE}.mids255.com/bulk_predict' -L -H 'Content-Type: application/json' -d '{"houses": [{ "MedInc": 8.3252, "HouseAge": 42, "AveRooms": 6.98, "AveBedrms": 1.02, "Population": 322, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 }]}'
```
### /predict
```
NAMESPACE=abrahaa
curl -X 'POST' 'https://${NAMESPACE}.mids255.com/predict' -L -H 'Content-Type: application/json' -d '{ "MedInc": 8.3252, "HouseAge": 42, "AveRooms": 6.98, "AveBedrms": 1.02, "Population": 322, "AveOccup": 2.55, "Latitude": 37.88, "Longitude": -122.23 }'
```

# Short Answer Questions
## What are the downsides of using `latest` as your docker image tag?
The `latest` tag doesn't represent a specific version or commit of the application. Without version pinning, pulling the `latest` tag may result in unintended updates to the application. When issues come up, it can be challenging to identify which version of the code is causing the problem. Continuous updates without control may inadvertently introduce security vulnerabilities if the new image contains unverified code. In summary, version control, ease of debugging, and improved control over dependencies and security updates are the key reasons to __not__ use `latest` as our docker image tag.

## What does `kustomize` do for us?
`Kustomize` helps manage Kubernetes manifests by allowing us to customize, patch, and manage configurations across different environments without needing to modify our TAML files directly. It allows us to manage configuration files in a more organized, modular way. It also enables us to define environment specific configurations (like development and production) while sharing a common base configuration. Lastly, since these Kustomization configurations are declarative and stored as YAML files, they can be versioned in source control systems like Git. 