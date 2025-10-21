# ABOUTME: Provides shared pytest fixtures for exercising the Flask server.
# ABOUTME: Supplies the Flask app object and its HTTP client for tests.

import pytest

from webapp import app as flask_app


@pytest.fixture
def app():
    flask_app.testing = True
    return flask_app


@pytest.fixture
def client(app):
    return app.test_client()
