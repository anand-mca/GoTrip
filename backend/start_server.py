#!/usr/bin/env python
"""
Simple server startup script that handles the working directory properly.
"""
import os
import sys
import subprocess

# Get the directory where this script is located
script_dir = os.path.dirname(os.path.abspath(__file__))

# Change to the script directory
os.chdir(script_dir)

# Add current directory to Python path
sys.path.insert(0, script_dir)

# Now run uvicorn
if __name__ == "__main__":
    # Run uvicorn with the app
    subprocess.run([
        sys.executable, "-m", "uvicorn",
        "app.main:app",
        "--reload",
        "--host", "127.0.0.1",
        "--port", "8000"
    ])
