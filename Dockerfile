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

# Verify installation
RUN python3 -c "import hermes; print('Hermes imported successfully')" || echo "Hermes import failed"

# Copy the rest of the application
COPY . .

# Set environment variables - using ENV directly
ENV HERMES_WEBUI_HOST=0.0.0.0
ENV HERMES_WEBUI_PORT=8787
ENV HERMES_WEBUI_AGENT_DIR=/hermes-agent
ENV PYTHONPATH=/hermes-agent:$PYTHONPATH

# Create a startup script that sets the variable
RUN echo '#!/bin/bash\n\
export HERMES_WEBUI_AGENT_DIR=/hermes-agent\n\
export PYTHONPATH=/hermes-agent:$PYTHONPATH\n\
python3 /app/server.py' > /start.sh && chmod +x /start.sh

# Expose the port
EXPOSE 8787

# Run the startup script
CMD ["/start.sh"]
