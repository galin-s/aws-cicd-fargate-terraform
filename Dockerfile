FROM python:3.11-slim
WORKDIR /app
RUN apt-get update && apt-get upgrade -y && apt-get clean
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

RUN useradd -m appuser
USER appuser

EXPOSE 5000

CMD ["python", "app/app.py"]
