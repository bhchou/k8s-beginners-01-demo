from flask import Flask, jsonify
import os
import socket

app = Flask(__name__)

APP_VERSION = os.getenv("APP_VERSION", "1.0")


@app.get("/")
def index():
    hostname = socket.gethostname()

    try:
        pod_ip = socket.gethostbyname(hostname)
    except socket.gaierror:
        pod_ip = "unknown"

    return jsonify(
        message="Hello Kubernetes",
        hostname=hostname,
        pod_ip=pod_ip,
        version=APP_VERSION,
    )


@app.get("/healthz")
def healthz():
    return jsonify(status="ok"), 200


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.getenv("PORT", "8080")),
    )
