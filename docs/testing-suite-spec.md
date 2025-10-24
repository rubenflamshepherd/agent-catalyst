## Testing Suite Specification

### Scope and Goals
- Establish a `pytest`-based workflow that validates the Flask application routes and infrastructure entry points without overbuilding.
- Ensure tests run identically on developer machines and in continuous integration.
- Restrict coverage to HTTP behavior only; database, queue, and external service scenarios stay out of scope.
- Require every Python test module to open with two `ABOUTME:` comment lines describing the file.

### Repository Layout
- Create a top-level `tests/` package with `__init__.py` so discovery is explicit.
- Add `tests/conftest.py` housing reusable fixtures:
  - `app` fixture returns the Flask application instance (imported from `webapp` for now).
  - `client` fixture wraps `app.test_client()` to issue HTTP requests without starting a server.
- Implement `tests/test_routes.py` to exercise the root route and assert status code, body content, encoding, and key headers.
- Reserve `tests/test_cli.py` with `pytest.skip` explaining that CLI commands are pending once implemented.

### Configuration and Dependencies
- Extend `app/requirements.txt` with `pytest`, `pytest-cov`, and any supporting packages required for request testing.
- Introduce `pytest.ini` at the repository root with:
  - `minversion = 7.0`
  - `addopts = -ra -q --strict-markers`
  - `testpaths = tests`
- Confirm `PYTHONPATH` includes the `app` directory when running tests from the repository root; document setting `PYTHONPATH=app` if necessary.

### Local Workflow
- Document installation via `pip install -r app/requirements.txt`.
- Provide a single entry point such as `make test` (update existing automation if present) that runs `pytest --cov=webapp --cov-report=term-missing`.
- Add README instructions covering:
  - Environment setup steps.
  - Default test command.
  - How to target a specific test (`pytest tests/test_routes.py::test_homepage`).
- Expect quiet output under `-q` and advise developers to treat any warning or log noise as actionable failures.

### Continuous Integration
- Add `.github/workflows/test.yml` triggered on `push` and `pull_request`.
- Configure the workflow to:
  - Checkout the repository.
  - Set up Python 3.11 to align with the Docker base image.
  - Cache `pip` dependencies.
  - Install requirements.
  - Run `pytest --cov=webapp --cov-report=term-missing` with `PYTHONWARNINGS=error`.
- Capture coverage output in the job log; defer badges or uploads until there is a concrete need.

### Open Questions
- Should we migrate shared tool settings (pytest, future linters, formatters) into a single `setup.cfg` so every python tool pulls from the same source when we eventually add linting?
- When the Flask surface area broadens, should we add a smoke-test job that builds the Docker image and runs the container’s entrypoint to ensure it starts cleanly and serves a basic request?
