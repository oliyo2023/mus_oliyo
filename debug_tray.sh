#!/bin/bash

# Script to run the Flutter app and filter for tray-related debug output

echo "Running Flutter app with tray debugging..."
echo "=========================================="
echo ""
echo "When the app starts:"
echo "1. Try clicking the tray icon"
echo "2. Try right-clicking and selecting menu items"
echo "3. Watch for debug output below"
echo ""
echo "Press Ctrl+C to stop"
echo ""

flutter run -d linux 2>&1 | grep --line-buffered -E "(Tray|tray|Menu|menu|Toggle|toggle|Exit|exit|Window|window|Debug|debug)"
