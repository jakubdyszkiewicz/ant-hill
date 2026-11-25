FROM python:3.13-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY refresh.py /app/refresh.py
CMD ["python", "-u", "/app/refresh.py"]
