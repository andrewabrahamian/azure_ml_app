# Dockerfile
###
## Build application and create virtual environment
###
FROM python:3.10.1-slim-buster AS venv
ARG /app

# Install build dependences
#RUN apt-get update && apt-get install -y curl
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# install poetry and add to path
ENV POETRY_VERSION=1.6.1
RUN curl -sSL https://install.python-poetry.org | python -
ENV PATH /root/.local/bin:$PATH

WORKDIR /app

# Copy the dependency files
COPY pyproject.toml poetry.lock ./
# only include this in statement to test docker build and run model_pipeline.pkl

# Install dependencies within a virtual environment
RUN python -m venv --copies /app/venv
RUN . /app/venv/bin/activate && poetry install

###
## Begin runtime image
###
FROM python:3.10.1-slim-buster AS prod

# Copy virtual environment from venv
COPY --from=venv /app/venv /app/venv/
ENV PATH /app/venv/bin:$PATH

WORKDIR /app

# Copy application code
COPY . ./

# Expose the port for app
#EXPOSE 8000

# Healthcheck for app
#HEALTHCHECK --start-period=30s CMD python -c "import requests; requests.get('http://localhost:8000/health', timeout=2)"
#HEALTHCHECK --interval=30s --timeout=10s --start-period=30s CMD curl --fail http://localhost:8000/health || exit 1

# Run the FastAPI app
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
