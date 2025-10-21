# ABOUTME: Exercises the public HTTP endpoints exposed by the Flask app.
# ABOUTME: Validates expected response metadata for the homepage route.

EXPECTED_HTML = "<p>Hello, World! I command you to re-deploy!</p>"


def test_homepage(client):
    response = client.get("/")

    assert response.status_code == 200
    assert EXPECTED_HTML in response.get_data(as_text=True)
    assert response.headers.get("Content-Type") == "text/html; charset=utf-8"
    assert response.mimetype_params.get("charset", "").lower() == "utf-8"
    assert False
