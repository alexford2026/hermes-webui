FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (for better caching)
COPY requirements.txt .
COPY requirements-dev.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Clone the hermes-agent repository into the container
RUN git clone https://github.com/NousResearch/hermes-agent.git /hermes-agent

# Install hermes-agent in editable mode
RUN cd /hermes-agent && pip install -e .

# Copy the rest of the application
COPY . .

# Set environment variables
ENV HERMES_WEBUI_HOST=0.0.0.0
ENV HERMES_WEBUI_PORT=8787
ENV HERMES_WEBUI_AGENT_DIR=/hermes-agent
ENV PYTHONPATH=/hermes-agent:$PYTHONPATH

# Expose the port
EXPOSE 8787

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8787/health || exit 1

# Run the application
CMD ["python3", "server.py"]
