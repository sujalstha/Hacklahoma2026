#!/bin/bash
# whatsForDinner Automated Backend Launcher

# 1. Figure out the project root (assumes script is in backend/ folder)
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

# 2. Check if port 8000 is already in use
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
    echo "Backend is already running on port 8000. Skipping launch."
else
    echo "Starting What's For Dinner Backend..."
    
    # 3. Check for virtual environment or system python
    if [ -d ".venv" ]; then
        source .venv/bin/activate
    fi
    
    # 4. Launch uvicorn in the background
    # We use nohup and redirect output so it doesn't block the Xcode build process
    nohup python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 > backend.log 2>&1 &
    
    echo "Backend launched in background. Check backend.log for details."
fi
