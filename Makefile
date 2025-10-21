# ABOUTME: Provides shorthand commands for running the Flask test suite.
# ABOUTME: Normalizes pytest execution with warnings escalated to errors.

APP_DIR := app
PYTHONWARNINGS ?= error
PYTEST ?= pytest

.PHONY: test test-coverage test-target

test:
	@cd $(APP_DIR) && PYTHONWARNINGS=$(PYTHONWARNINGS) $(PYTEST)

test-coverage:
	@cd $(APP_DIR) && PYTHONWARNINGS=$(PYTHONWARNINGS) $(PYTEST) --cov=webapp --cov-report=term-missing

test-target:
ifndef TARGET
	$(error TARGET is required, e.g., make test-target TARGET=tests/test_routes.py::test_homepage)
endif
	@cd $(APP_DIR) && PYTHONWARNINGS=$(PYTHONWARNINGS) $(PYTEST) $(TARGET)
