#!/bin/bash

IMAGE_NAME=lab4
APP_NAME=lab4
NAMESPACE=w255

#cd ${APP_NAME}

# if [[ ${MINIKUBE_TUNNEL_PID:-"unset"} != "unset" ]]; then
#     echo "Potentially existing Minikube Tunnel at PID: ${MINIKUBE_TUNNEL_PID}"
#     kill ${MINIKUBE_TUNNEL_PID}
# fi

#install poetry python pytest environment
poetry env remove python3.10
poetry install
poetry run pytest -vv -s

# stop and remove image in case this script was run before
docker stop ${APP_NAME}
docker rm ${APP_NAME}
docker image rm ${IMAGE_NAME}
minikube stop

#start minikube
echo "start minikube"
minikube start --kubernetes-version=v1.27.3

#config Docker environment to use minikube
#eval $(minikube -p minikube docker-env)

FILE=./src/model_pipeline.pkl
if [ -f ${FILE} ]; then
    echo "${FILE} exist."
else
    echo "${FILE} does not exist."
    poetry run python ./trainer/train.py
    cp ./model_pipeline.pkl src/
fi

# Build the Docker container
echo "Building the Docker container..."
eval $(minikube docker-env)
docker build -t ${IMAGE_NAME} .

# apply yamls for building environment
kubectl apply -f infra/namespace.yaml
kubectl wait --for=jsonpath='{.status.phase}'=Active namespace/${NAMESPACE}
kubectl apply -f infra/

kubectl wait deployment -n ${NAMESPACE} ${APP_NAME} --for condition=Available=True --timeout=90s
exit_status=$?
if [ $exit_status -ne 0 ]; then
    echo "Deployment failed to launch before timeout, please review"
    sleep 10
    exit
fi

# Start port-forward
echo "Starting port-forward for the API service..."
kubectl port-forward -n ${NAMESPACE} deployment/${APP_NAME} 8000:8000 &

sleep 5

finished=false
while ! $finished; do
    health_status=$(curl -o /dev/null -s -w "%{http_code}\n" -X GET "http://localhost:8000/health")
    if [ $health_status == "200" ]; then
        finished=true
        echo "API is ready"
    else
        echo "API not responding yet"
        sleep 5
    fi
done

curl -o /dev/null -s -w "%{http_code}\n" -X GET "http://localhost:8000/hello?name=Andrew"
curl -o /dev/null -s -w "%{http_code}\n" -X GET "http://localhost:8000/hello?nam=Andrew"
curl -o /dev/null -s -w "%{http_code}\n" -X GET "http://localhost:8000/"
curl -o /dev/null -s -w "%{http_code}\n" -X GET "http://localhost:8000/docs"
curl -X POST "http://localhost:8000/predict" -H 'Content-Type: application/json' -d '{
    "MedInc": 1,
    "HouseAge": 0,
    "AveRooms": 0,
    "AveBedrms": 0,
    "Population": 0,
    "AveOccup": 0,
    "Latitude": 0,
    "Longitude": 0
}'
curl -X POST "http://localhost:8000/bulk_predict" -H 'Content-Type: application/json' -d '{
  "houses": [
    {
      "MedInc": 1,
      "HouseAge": 0,
      "AveRooms": 0,
      "AveBedrms": 0,
      "Population": 0,
      "AveOccup": 0,
      "Latitude": 0,
      "Longitude": 0
    },
    {
      "MedInc": 1,
      "HouseAge": 0,
      "AveRooms": 0,
      "AveBedrms": 0,
      "Population": 0,
      "AveOccup": 0,
      "Latitude": 0,
      "Longitude": 0
    }
  ]
}'

sleep 5

# output and tail the logs for the api deployment
kubectl logs -n ${NAMESPACE} -l app=${APP_NAME}

sleep 10

# Stop port-forward
echo "Stopping port-forward..."
kill %1

# cleanup
kubectl delete -f infra
minikube stop

sleep 5