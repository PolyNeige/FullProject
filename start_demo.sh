#!/bin/bash

# --- CONFIGURATION ---
PLAYER_CONTAINER="player-app"
PLATFORM_CONTAINER="platform-app"
EDITOR_CONTAINER="editor-app"

# Clear screen for a clean start
clear
echo "======================================================"
echo "      STEAM SIMULATION LAUNCHER (3 MODULES)"
echo "======================================================"

# 1. Cleanup and Start
echo ""
echo "[1/3] Stopping old containers and rebuilding..."
docker compose down
docker compose up -d --build

if [ $? -ne 0 ]; then
    echo "[ERROR] Docker Compose failed to start."
    echo "Check if Docker is running."
    exit 1
fi

# 2. Wait Loop
echo ""
echo "[2/3] Waiting for containers to initialize..."
echo "      (Waiting for Kafka, DBs, and Apps to stabilize)"

# Wait specifically for the LAST container (Editor) to be ready
until [ "$(docker inspect -f {{.State.Running}} $EDITOR_CONTAINER 2>/dev/null)" == "true" ]; do
    echo -n "."
    sleep 1
done

echo ""
echo "Containers are up! Waiting 8 seconds for Java to warm up..."
sleep 8

# 3. Launch Terminals
echo ""
echo "[3/3] Launching Interface Terminals..."

# CHECK FOR GNOME-TERMINAL (Standard on Ubuntu/Debian/Fedora)
if command -v gnome-terminal &> /dev/null; then
    # Window 1: PLAYER (Left)
    gnome-terminal --title="PLAYER (CLIENT)" --geometry=90x40+0+0 -- bash -c "docker attach $PLAYER_CONTAINER; exec bash"

    # Window 2: PLATFORM (Middle)
    gnome-terminal --title="PLATFORM (ADMIN)" --geometry=90x40+650+0 -- bash -c "docker attach $PLATFORM_CONTAINER; exec bash"

    # Window 3: EDITOR (Right)
    gnome-terminal --title="EDITOR (PUBLISHER)" --geometry=90x40+1300+0 -- bash -c "docker attach $EDITOR_CONTAINER; exec bash"

# CHECK FOR KONSOLE (KDE)
elif command -v konsole &> /dev/null; then
    konsole -e "docker attach $PLAYER_CONTAINER" &
    konsole -e "docker attach $PLATFORM_CONTAINER" &
    konsole -e "docker attach $EDITOR_CONTAINER" &

# CHECK FOR XTERM (Fallback)
elif command -v xterm &> /dev/null; then
    xterm -T "PLAYER MODULE" -e "docker attach $PLAYER_CONTAINER" &
    xterm -T "PLATFORM MODULE" -e "docker attach $PLATFORM_CONTAINER" &
    xterm -T "EDITOR MODULE" -e "docker attach $EDITOR_CONTAINER" &

else
    echo "[ERROR] Could not detect a supported terminal emulator."
    echo "Please manually open three terminals and run:"
    echo "1. docker attach $PLAYER_CONTAINER"
    echo "2. docker attach $PLATFORM_CONTAINER"
    echo "3. docker attach $EDITOR_CONTAINER"
fi

echo ""
echo "Done! Three windows should have appeared."