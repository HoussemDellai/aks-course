# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/engine/reference/builder/

ARG PYTHON_VERSION=3.8.10
FROM python:${PYTHON_VERSION}-slim as base

# Set environment variables
ENV VIRTUAL_ENV=/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Copy the source code into the container.
COPY . .

# Install dependencies within the virtual environment.
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Run the application within the virtual environment.
CMD ["python", "app.py"]