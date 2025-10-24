# ABOUTME: Starts the Flask development server for manual runs.
# ABOUTME: Provides a script entry point when executing Python directly.

from webapp import app

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=8080)
