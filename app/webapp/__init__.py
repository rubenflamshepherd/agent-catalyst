# ABOUTME: Configures the Flask application for serving HTTP routes.
# ABOUTME: Declares the available endpoints for the web application.

from flask import Flask

app = Flask(__name__)


@app.route("/")
def hello_world():
    return "<p>Hello, World! I command you to re-deploy!</p>"
