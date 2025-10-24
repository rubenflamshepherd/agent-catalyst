# ABOUTME: Exercises the public HTTP endpoints exposed by the Flask app.
# ABOUTME: Validates expected response metadata for the homepage route.

import os


def test_homepage(client, monkeypatch):
    monkeypatch.setenv("ENVIRONMENT", "test")
    response = client.get("/")

    assert response.status_code == 200
    assert (
        "<p>Hello, World! I command you to re-deploy! (test)</p>"
        in response.get_data(as_text=True)
    )
    assert response.headers.get("Content-Type") == "text/html; charset=utf-8"
    assert response.mimetype_params.get("charset", "").lower() == "utf-8"
