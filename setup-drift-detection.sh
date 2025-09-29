#!/bin/bash
# Setup Drift Detection Cron Job (Localhost)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CRON_LOG="$PROJECT_DIR/logs/drift-detection.log"

echo "🚀 Setting up Terraform Drift Detection (Localhost)"
echo "Project directory: $PROJECT_DIR"

# Create logs directory
mkdir -p "$PROJECT_DIR/logs"

# Create or update cron job
CRON_ENTRY="*/5 * * * * cd $PROJECT_DIR && $PROJECT_DIR/scripts/drift-check-localhost.sh >> $CRON_LOG 2>&1"

echo "📅 Setting up cron job..."
echo "Schedule: Every 5 minutes"
echo "Log file: $CRON_LOG"

# Add to crontab (remove existing first to avoid duplicates)
(crontab -l 2>/dev/null | grep -v "drift-check-localhost.sh"; echo "$CRON_ENTRY") | crontab -

if [ $? -eq 0 ]; then
    echo "✅ Cron job added successfully!"
    echo ""
    echo "📋 Current crontab:"
    crontab -l | grep drift-check
    echo ""
    echo "📝 Logs will be written to: $CRON_LOG"
    echo "📊 View logs: tail -f $CRON_LOG"
    echo ""
    echo "🧪 Test manual run:"
    echo "   cd $PROJECT_DIR && ./scripts/drift-check-localhost.sh"
    echo ""
    echo "⏹️  To remove cron job:"
    echo "   crontab -e"
else
    echo "❌ Failed to add cron job"
    exit 1
fi