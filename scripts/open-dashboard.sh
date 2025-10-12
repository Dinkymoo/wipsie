#!/bin/bash
# Quick dashboard launcher for VS Code dev container

echo "🎯 Opening Wipsie Dashboard..."

# Method 1: Try VS Code simple browser via code command
if command -v code &> /dev/null; then
    echo "📱 Opening in VS Code Simple Browser..."
    code --open-url "file:///workspaces/wipsie/dashboard/index.html"
fi

# Method 2: Show file location for manual opening
echo "📁 Dashboard location: /workspaces/wipsie/dashboard/index.html"
echo "💡 In VS Code:"
echo "   1. Open Explorer (Ctrl+Shift+E)"
echo "   2. Navigate to dashboard/index.html"
echo "   3. Right-click → 'Open with Live Server' or 'Preview'"

# Method 3: Start a simple HTTP server for browser access
echo ""
echo "🌐 Starting local HTTP server..."
echo "📡 Dashboard will be available at: http://localhost:8080"
echo "🔧 Use Ctrl+C to stop the server"
echo ""

cd /workspaces/wipsie/dashboard
python3 -m http.server 8080
