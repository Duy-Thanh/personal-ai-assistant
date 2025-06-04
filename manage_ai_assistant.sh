#!/bin/bash

# Enhanced Personal AI Assistant Management Script
# Provides beautiful interface navigation, memory monitoring, and system management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
API_PORT=5000
OLLAMA_PORT=11434
LOG_FILE="ai_assistant.log"
PID_FILE="ai_assistant.pid"

print_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   🤖 PERSONAL AI ASSISTANT                   ║"
    echo "║              Enhanced Web Interface Manager                  ║"
    echo "║                                                              ║"
    echo "║  ✨ Beautiful UI  🧠 Smart Memory  🔒 Private  ⚡ Fast     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_status() {
    local message=$1
    local color=$2
    echo -e "${color}[$(date '+%H:%M:%S')] ${message}${NC}"
}

check_dependencies() {
    print_status "🔍 Checking dependencies..." $CYAN
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_status "❌ Python3 not found. Please install Python 3.8+" $RED
        exit 1
    fi
    
    # Check Ollama
    if ! command -v ollama &> /dev/null; then
        print_status "❌ Ollama not found. Please install Ollama first" $RED
        exit 1
    fi
    
    # Check requirements
    if [ ! -f "requirements.txt" ]; then
        print_status "📦 Creating requirements.txt..." $YELLOW
        cat > requirements.txt << EOF
flask==2.3.3
flask-cors==4.0.0
requests==2.31.0
gunicorn==21.2.0
EOF
    fi
    
    # Install Python dependencies
    if [ ! -d "venv" ]; then
        print_status "🐍 Creating virtual environment..." $YELLOW
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    pip install -r requirements.txt > /dev/null 2>&1
    
    print_status "✅ Dependencies verified" $GREEN
}

check_ollama_status() {
    if curl -s http://localhost:$OLLAMA_PORT/api/tags > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

start_ollama() {
    print_status "🚀 Starting Ollama service..." $CYAN
    
    if check_ollama_status; then
        print_status "✅ Ollama already running" $GREEN
        return 0
    fi
    
    ollama serve &
    
    # Wait for Ollama to start
    for i in {1..30}; do
        if check_ollama_status; then
            print_status "✅ Ollama service started" $GREEN
            return 0
        fi
        sleep 1
    done
    
    print_status "❌ Failed to start Ollama service" $RED
    exit 1
}

check_model() {
    print_status "🧠 Checking AI model..." $CYAN
    
    if ollama list | grep -q "phi3:mini"; then
        print_status "✅ Phi-3 Mini model ready" $GREEN
    else
        print_status "📥 Downloading Phi-3 Mini model (this may take a while)..." $YELLOW
        ollama pull phi3:mini
        print_status "✅ Phi-3 Mini model downloaded" $GREEN
    fi
}

start_api() {
    print_status "🌐 Starting API server..." $CYAN
    
    if [ -f "$PID_FILE" ] && kill -0 $(cat $PID_FILE) 2>/dev/null; then
        print_status "✅ API server already running (PID: $(cat $PID_FILE))" $GREEN
        return 0
    fi
    
    source venv/bin/activate
    
    # Start API in background
    nohup python3 fast_chatbot_api.py > $LOG_FILE 2>&1 &
    API_PID=$!
    echo $API_PID > $PID_FILE
    
    # Wait for API to start
    for i in {1..30}; do
        if curl -s http://localhost:$API_PORT/health > /dev/null 2>&1; then
            print_status "✅ API server started (PID: $API_PID)" $GREEN
            return 0
        fi
        sleep 1
    done
    
    print_status "❌ Failed to start API server" $RED
    exit 1
}

stop_services() {
    print_status "🛑 Stopping services..." $YELLOW
    
    # Stop API
    if [ -f "$PID_FILE" ]; then
        if kill -0 $(cat $PID_FILE) 2>/dev/null; then
            kill $(cat $PID_FILE)
            print_status "✅ API server stopped" $GREEN
        fi
        rm -f $PID_FILE
    fi
    
    # Stop Ollama (optional - comment out if you want to keep it running)
    # pkill -f "ollama serve" || true
    
    print_status "✅ Services stopped" $GREEN
}

show_status() {
    print_status "📊 System Status:" $CYAN
    echo
    
    # Ollama status
    if check_ollama_status; then
        echo -e "${GREEN}🟢 Ollama Service: Running${NC}"
    else
        echo -e "${RED}🔴 Ollama Service: Stopped${NC}"
    fi
    
    # API status
    if curl -s http://localhost:$API_PORT/health > /dev/null 2>&1; then
        echo -e "${GREEN}🟢 API Server: Running (Port $API_PORT)${NC}"
    else
        echo -e "${RED}🔴 API Server: Stopped${NC}"
    fi
    
    # Model status
    if ollama list | grep -q "phi3:mini"; then
        echo -e "${GREEN}🟢 AI Model: Ready (Phi-3 Mini)${NC}"
    else
        echo -e "${RED}🔴 AI Model: Not Downloaded${NC}"
    fi
    
    # Memory usage
    if curl -s http://localhost:$API_PORT/stats > /dev/null 2>&1; then
        echo
        echo -e "${CYAN}📈 Live Statistics:${NC}"
        curl -s http://localhost:$API_PORT/stats | python3 -m json.tool | grep -E "(total_requests|active_sessions|total_messages_in_memory)" | sed 's/^/  /'
    fi
    
    echo
    echo -e "${BLUE}🌐 Access URLs:${NC}"
    echo -e "  Landing Page: ${WHITE}http://localhost:$API_PORT/${NC}"
    echo -e "  Chat Interface: ${WHITE}http://localhost:$API_PORT/chat${NC}"
    echo -e "  API Health: ${WHITE}http://localhost:$API_PORT/health${NC}"
    echo -e "  Statistics: ${WHITE}http://localhost:$API_PORT/stats${NC}"
}

show_logs() {
    if [ -f "$LOG_FILE" ]; then
        print_status "📋 Recent logs:" $CYAN
        tail -n 20 $LOG_FILE
    else
        print_status "📋 No logs found" $YELLOW
    fi
}

show_memory_usage() {
    print_status "🧠 Memory Usage Analysis:" $CYAN
    
    if curl -s http://localhost:$API_PORT/stats > /dev/null 2>&1; then
        local stats=$(curl -s http://localhost:$API_PORT/stats)
        echo
        echo -e "${WHITE}Memory Conservation Settings:${NC}"
        echo "$stats" | python3 -c "
import sys, json
data = json.load(sys.stdin)
mem = data.get('memory_conservation', {})
print(f'  Max Conversation Length: {mem.get(\"max_conversation_length\", \"N/A\")}')
print(f'  Max Context Messages: {mem.get(\"max_context_messages\", \"N/A\")}')
print(f'  Cleanup Enabled: {mem.get(\"cleanup_enabled\", \"N/A\")}')
print()
print('Current Usage:')
print(f'  Active Sessions: {data.get(\"active_sessions\", 0)}')
print(f'  Total Messages in Memory: {data.get(\"total_messages_in_memory\", 0)}')
print(f'  Total Conversations: {data.get(\"total_conversations\", 0)}')
"
    else
        print_status "❌ Cannot fetch memory statistics - API not running" $RED
    fi
}

open_browser() {
    local url="http://localhost:$API_PORT/"
    print_status "🌐 Opening browser to $url" $CYAN
    
    # Try different browser commands
    if command -v xdg-open > /dev/null; then
        xdg-open $url
    elif command -v open > /dev/null; then
        open $url
    elif command -v start > /dev/null; then
        start $url
    else
        print_status "Please open $url in your browser" $YELLOW
    fi
}

main_menu() {
    while true; do
        clear
        print_banner
        show_status
        echo
        echo -e "${WHITE}Choose an option:${NC}"
        echo -e "  ${GREEN}1)${NC} 🚀 Start All Services"
        echo -e "  ${GREEN}2)${NC} 🛑 Stop All Services"
        echo -e "  ${GREEN}3)${NC} 📊 Show Status"
        echo -e "  ${GREEN}4)${NC} 📋 Show Logs"
        echo -e "  ${GREEN}5)${NC} 🧠 Memory Usage"
        echo -e "  ${GREEN}6)${NC} 🌐 Open Browser"
        echo -e "  ${GREEN}7)${NC} 🔄 Restart Services"
        echo -e "  ${GREEN}0)${NC} 👋 Exit"
        echo
        read -p "Enter your choice [0-7]: " choice
        
        case $choice in
            1)
                echo
                check_dependencies
                start_ollama
                check_model
                start_api
                echo
                print_status "🎉 All services started successfully!" $GREEN
                print_status "🌐 Visit http://localhost:$API_PORT/ to access your AI assistant" $CYAN
                read -p "Press Enter to continue..."
                ;;
            2)
                echo
                stop_services
                read -p "Press Enter to continue..."
                ;;
            3)
                echo
                show_status
                read -p "Press Enter to continue..."
                ;;
            4)
                echo
                show_logs
                read -p "Press Enter to continue..."
                ;;
            5)
                echo
                show_memory_usage
                read -p "Press Enter to continue..."
                ;;
            6)
                open_browser
                read -p "Press Enter to continue..."
                ;;
            7)
                echo
                stop_services
                sleep 2
                check_dependencies
                start_ollama
                check_model
                start_api
                print_status "🔄 Services restarted successfully!" $GREEN
                read -p "Press Enter to continue..."
                ;;
            0)
                print_status "👋 Goodbye!" $CYAN
                exit 0
                ;;
            *)
                print_status "❌ Invalid option. Please try again." $RED
                sleep 1
                ;;
        esac
    done
}

# Command line interface
case "${1:-menu}" in
    start)
        print_banner
        check_dependencies
        start_ollama
        check_model
        start_api
        print_status "🎉 All services started!" $GREEN
        ;;
    stop)
        print_banner
        stop_services
        ;;
    status)
        print_banner
        show_status
        ;;
    logs)
        show_logs
        ;;
    memory)
        show_memory_usage
        ;;
    restart)
        print_banner
        stop_services
        sleep 2
        check_dependencies
        start_ollama
        check_model
        start_api
        print_status "🔄 Services restarted!" $GREEN
        ;;
    menu|*)
        main_menu
        ;;
esac
