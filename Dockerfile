FROM python:3.11-slim

# Install system dependencies and ngrok
RUN apt-get update && \
    apt-get install -y curl gnupg2 ca-certificates && \
    curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
    tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
    tee /etc/apt/sources.list.d/ngrok.list && \
    apt-get update && \
    apt-get install -y ngrok && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY runtime_test_app_direct_api.py .
COPY start-docker.sh .
RUN chmod +x start-docker.sh

# Expose ports
# 5000: Flask app
# 4040: ngrok web interface
EXPOSE 5000 4040

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

CMD ["./start-docker.sh"]
