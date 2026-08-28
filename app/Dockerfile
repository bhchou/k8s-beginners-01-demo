FROM python:3.14-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

ENV PORT=8080
ENV APP_VERSION=1.0

EXPOSE 8080

CMD ["python", "app.py"]
