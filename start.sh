#!/bin/bash

# Function to pause at the end (for Windows users)
# This ensures the terminal doesn't close immediately after the script finishes.
pause_at_end() {
    if [[ "$OS" == "Windows_NT" ]]; then
        echo -e "\nPress any key to exit..."
        read -n 1 -s
    fi
}

# Variable to store missing dependencies
MISSING_DEPENDENCIES=""

# Detect Python 3
# First, it tries to find the `python3` command. If not found, it checks for `python` and ensures it's Python 3.
PYTHON_COMMAND=$(command -v python3 || { command -v python &>/dev/null && python --version 2>&1 | grep -q "Python 3" && echo python; })

# Check if Python 3 is available; if not, add it to the missing dependencies
if [ -z "$PYTHON_COMMAND" ]; then
    MISSING_DEPENDENCIES="${MISSING_DEPENDENCIES} Python 3 (https://www.python.org/downloads/)\n"
fi

# Check if Poetry (Python dependency manager) is installed
command -v poetry >/dev/null 2>&1 || MISSING_DEPENDENCIES="${MISSING_DEPENDENCIES} Poetry (https://python-poetry.org/docs/#installation)\n"

# Check if Yarn (JavaScript package manager) is installed
command -v yarn >/dev/null 2>&1 || MISSING_DEPENDENCIES="${MISSING_DEPENDENCIES} Yarn (https://yarnpkg.com/getting-started/install)\n"

# If any dependencies are missing, list them and exit the script
if [ ! -z "$MISSING_DEPENDENCIES" ]; then
    echo -e "Missing dependencies:\n$MISSING_DEPENDENCIES"
    pause_at_end
    exit 1
fi

# Step 1: Install Python dependencies using Poetry
echo "Installing Python dependencies with Poetry..."
poetry install || { echo "Error: Failed to install dependencies with Poetry."; pause_at_end; exit 1; }

# Step 2: Build the user interface using Yarn
echo "Building the UI with Yarn..."
./scripts/build-ui.sh || { echo "Error: Failed to build the UI with Yarn."; pause_at_end; exit 1; }

# Step 3: Enable hardware acceleration with cuBLAS for llama-cpp-python
echo "Enabling hardware acceleration with cuBLAS..."
./scripts/llama-cpp-python-cublas.sh || { echo "Error: Failed to configure llama-cpp-python with cuBLAS."; pause_at_end; exit 1; }

# Step 4: Start the Selfie application
echo "Starting Selfie..."

# If the system architecture is ARM64 (e.g., Apple M1/M2 chips), set specific environment variables
if [ "$(uname -m)" = "arm64" ]; then
    export OMP_NUM_THREADS=1  # Limit OpenMP to a single thread
    export KMP_DUPLICATE_LIB_OK=TRUE  # Allow duplicate libraries to load without errors
fi

# Run the Python module 'selfie' using Poetry
poetry run python -m selfie || { echo "Error: Failed to run the Selfie module."; pause_at_end; exit 1; }

# Final success message
echo "Execution completed successfully!"
pause_at_end
