# Use the official Python image from the Docker Hub
FROM python:3.12.7-slim

# Set environment variable for the port
ENV PORT=8501

# Expose the port that the application will run on
EXPOSE 8501

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy the requirements file into the container
COPY requirements.txt ./

# Install the dependencies specified in the requirements file
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container
COPY . .

# Create a non-root user and switch to it
RUN useradd -m appuser && chown -R appuser /usr/src/app
USER appuser

# Define the command to run the Streamlit application
ENTRYPOINT ["streamlit", "run", "streamlit-app.py", "--server.port=8501"]

# Health check to ensure the application is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl --fail http://localhost:8501/_stcore/health || exit 1

# FROM python:3.9-slim

# RUN groupadd --gid 1000 appuser \
#     && useradd --uid 1000 --gid 1000 -ms /bin/bash appuser

# RUN pip3 install --no-cache-dir --upgrade \
#     pip \
#     virtualenv

# RUN apt-get update && apt-get install -y \
#     build-essential \
#     software-properties-common \
#     git

# # Copy and set permissions for run.sh before changing user
# COPY run.sh /home/appuser/
# RUN chmod +x /home/appuser/run.sh && chown appuser:appuser /home/appuser/run.sh

# USER appuser
# WORKDIR /home/appuser

# RUN git clone https://github.com/streamlit/streamlit-example.git app

# ENV VIRTUAL_ENV=/home/appuser/venv
# RUN virtualenv ${VIRTUAL_ENV}
# RUN . ${VIRTUAL_ENV}/bin/activate && pip install -r app/requirements.txt

# EXPOSE 8501

# ENTRYPOINT ["./run.sh"]