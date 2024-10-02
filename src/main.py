import logging
import os
from contextlib import asynccontextmanager

import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi_cache import FastAPICache
from fastapi_cache.backends.redis import RedisBackend
from fastapi_cache.decorator import cache
from joblib import load
from pydantic import BaseModel, ConfigDict, Field
from redis import asyncio
import datetime


logger = logging.getLogger(__name__)


model = load("./src/model_pipeline.pkl")

LOCAL_REDIS_URL = "redis://localhost:6379/"


@asynccontextmanager
async def lifespan(app: FastAPI):
    HOST_URL = os.environ.get("REDIS_URL", LOCAL_REDIS_URL)
    logger.debug(HOST_URL)
    redis = asyncio.from_url(HOST_URL, encoding="utf8", decode_responses=True)
    FastAPICache.init(RedisBackend(redis), prefix="fastapi-cache")

    yield


app = FastAPI(lifespan=lifespan)


# to run locally
#@app.on_event('startup')
#async def startup():
#   redis = aioredis.from_url('redis://localhost')
#   FastAPICache.init(RedisBackend(redis), prefix='fastapi-cache')

# to connect to Kubernetes service
# @app.on_event('startup')
# async def startup():
#     redis = aioredis.from_url('redis://redis-service:6379')  # Use the service name
#     FastAPICache.init(RedisBackend(redis), prefix='fastapi-cache')

class House(BaseModel):
    model_config = ConfigDict(extra="forbid")

    MedInc: float = Field(gt=0)
    HouseAge: float
    AveRooms: float
    AveBedrms: float
    Population: float
    AveOccup: float
    Latitude: float
    Longitude: float

    def to_np(self):
        return np.array(list(vars(self).values())).reshape(1, 8)


class ListHouses(BaseModel):
    model_config = ConfigDict(extra="forbid")

    houses: list[House]

    def to_np(self):
        return np.vstack([x.to_np() for x in self.houses])


class HousePrediction(BaseModel):
    predictions: float


class ListHousePrediction(BaseModel):
    predictions: list[float]

@app.post("/predict", response_model=HousePrediction)
@cache(expire=60)
async def predict(house: House):
    predictions = model.predict(house.to_np())
    return {"predictions": predictions[0]}

@app.post("/bulk_predict", response_model=ListHousePrediction)
@cache(expire=60)
async def bulk_predict(houses: ListHouses):
    predictions = model.predict(houses.to_np())
    return {"predictions": list(predictions)}

#define the /health endpoint
@app.get("/health", response_model=dict)
async def health():
    current_time = datetime.datetime.now().isoformat()
    return {"time": current_time}

# Raises 422 if bad parameter automatically by FastAPI
@app.get("/hello")
async def hello(name: str):
    return {"message": f"Hello {name}"}

# Define the / endpoint
@app.get("/")
async def root():
    raise HTTPException(status_code=404, detail="Not Found")

# /docs endpoint is defined by FastAPI automatically
# /openapi.json returns a json object automatically by FastAPI