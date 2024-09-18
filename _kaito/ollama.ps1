# https://ollama.com/blog/ollama-is-now-available-as-an-official-docker-image

# CPU only
docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama

# Now you can run a model like Llama 2 inside the container.
docker exec -it ollama ollama run llama2