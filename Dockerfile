FROM python:3.12-slim

ENV POETRY_HOME="/opt/poetry"
ENV VENV_PATH="/opt/venv"
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

WORKDIR /app

RUN apt-get update \
  && apt-get install -y curl build-essential \
  && curl -sSL https://install.python-poetry.org | python3 -

COPY pyproject.toml poetry.lock ./

RUN poetry lock --no-update && poetry install --no-root --no-dev -vvv --sync

COPY . .

EXPOSE 3000

#CMD ["poetry", "run", "fastapi", "dev", "--host", "0.0.0.0", "--port", "3000", "src/sample_api/main.py"]
CMD poetry run start
