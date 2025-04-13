# Use the official Python image from the Docker Hub
FROM python:3.13.3-slim

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
ENTRYPOINT ["streamlit", "run", "app.py", "--server.port=8501"]

# Health check to ensure the application is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl --fail http://localhost:8501/_stcore/health || exit 1