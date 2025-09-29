#!/bin/bash

echo "========================================="
echo "Setup Security Scanning Automation"
echo "========================================="

# Get current directory
PROJECT_DIR=$(pwd)
SCRIPT_PATH="$PROJECT_DIR/scripts/security-scan.sh"
LOG_DIR="$PROJECT_DIR/logs"

# Ensure logs directory exists
mkdir -p "$LOG_DIR"

# Check if security scan script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ ERROR: Security scan script not found at $SCRIPT_PATH"
    exit 1
fi

# Make sure script is executable
chmod +x "$SCRIPT_PATH"

echo "📁 Project Directory: $PROJECT_DIR"
echo "🛡️  Security Script: $SCRIPT_PATH"
echo "📝 Log Directory: $LOG_DIR"

# Create cron job for security scanning
CRON_COMMAND="0 */6 * * * cd $PROJECT_DIR && ./scripts/security-scan.sh >> $LOG_DIR/security-scan.log 2>&1"

echo ""
echo "🕰️  Setting up automated security scanning..."
echo "📅 Schedule: Every 6 hours (4 times daily)"
echo "📝 Logs: $LOG_DIR/security-scan.log"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "security-scan.sh"; then
    echo "⚠️  Existing security scan cron job found. Updating..."
    # Remove existing entry
    crontab -l 2>/dev/null | grep -v "security-scan.sh" | crontab -
fi

# Add new cron job
(crontab -l 2>/dev/null; echo "$CRON_COMMAND") | crontab -

if [ $? -eq 0 ]; then
    echo "✅ Security scanning automation setup successfully!"
    echo ""
    echo "📋 Current cron jobs:"
    crontab -l | grep -E "(security-scan|drift-check)"
    echo ""
    echo "🔧 Management Commands:"
    echo "   Manual scan:     ./scripts/security-scan.sh"
    echo "   View logs:       tail -f $LOG_DIR/security-scan.log"
    echo "   Edit schedule:   crontab -e"
    echo "   Remove job:      crontab -e (delete security-scan line)"
    echo ""
    echo "🌐 n8n Webhook Endpoint: http://localhost:5678/webhook/security-scan"
    echo "🎯 Webhook Method: GET with query parameters"
else
    echo "❌ Failed to setup cron job"
    exit 1
fi

echo "========================================="
echo "Setup completed successfully!"
echo "========================================="