#!/bin/bash
echo "========================================="
echo "Terraform Drift Detection (Localhost)"
echo "Running at $(date)"
echo "========================================="

# Pastikan terraform tersedia
if ! command -v terraform >/dev/null 2>&1; then
    echo "❌ ERROR: Terraform not found. Please install terraform first."
    exit 1
fi

# Pastikan terraform sudah di-init
if [ ! -f .terraform.lock.hcl ]; then
    echo "❌ ERROR: Terraform not initialized. Running 'terraform init'..."
    terraform init || { echo "Failed to initialize terraform"; exit 1; }
fi

# Jalankan terraform plan
echo "🔍 Executing terraform plan..."
PLAN_OUTPUT=$(terraform plan -detailed-exitcode -no-color 2>&1)
EXIT_CODE=$?

echo "📊 Terraform plan exit code: $EXIT_CODE"

# Prepare webhook payload
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HOSTNAME=$(hostname)

if [ $EXIT_CODE -eq 2 ]; then
    echo "⚠️  DRIFT DETECTED!"
    echo "Changes found in infrastructure configuration"
    
    # Extract detailed plan information
    PLAN_SUMMARY=$(echo "$PLAN_OUTPUT" | grep -E "Plan:|Changes to Outputs:" | head -1)
    
    # Get more detailed info about changes
    CHANGES_DETAIL=$(echo "$PLAN_OUTPUT" | grep -A5 -B5 "will be created\|will be updated\|will be destroyed" | head -20)
    
    echo "📋 Plan Summary: $PLAN_SUMMARY"
    echo "🔍 Detected Changes:"
    echo "$CHANGES_DETAIL"
    
    # Send webhook to n8n (corrected method and endpoint)
    echo "📡 Sending drift alert to n8n..."
    WEBHOOK_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{
            \"event\": \"drift_detected\",
            \"timestamp\": \"$TIMESTAMP\",
            \"hostname\": \"$HOSTNAME\",
            \"exit_code\": $EXIT_CODE,
            \"message\": \"Configuration drift detected in Terraform infrastructure\",
            \"summary\": \"$PLAN_SUMMARY\",
            \"changes_detail\": \"$CHANGES_DETAIL\",
            \"source\": \"localhost_drift_detection\"
        }" \
        http://localhost:5678/webhook-test/drift-detected 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✅ Drift alert webhook sent successfully"
        echo "🔄 n8n Response: $WEBHOOK_RESPONSE"
    else
        echo "❌ Failed to send drift webhook"
        echo "❌ Error: $WEBHOOK_RESPONSE"
    fi

elif [ $EXIT_CODE -eq 0 ]; then
    echo "✅ No drift detected. Infrastructure is in sync."
    
    # Optional: Send success notification
    echo "📡 Sending success notification..."
    WEBHOOK_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{
            \"event\": \"no_drift\",
            \"timestamp\": \"$TIMESTAMP\",
            \"hostname\": \"$HOSTNAME\",
            \"exit_code\": $EXIT_CODE,
            \"message\": \"No configuration drift detected - infrastructure matches configuration\",
            \"source\": \"localhost_drift_detection\"
        }" \
        http://localhost:5678/webhook/drift-status 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✅ Success notification sent"
        echo "🔄 n8n Response: $WEBHOOK_RESPONSE"
    else
        echo "ℹ️  No n8n webhook configured for success notifications"
        echo "❌ Response: $WEBHOOK_RESPONSE"
    fi

else
    echo "❌ ERROR: Terraform plan failed (exit code: $EXIT_CODE)"
    
    # Extract error message  
    ERROR_MSG=$(echo "$PLAN_OUTPUT" | head -10)
    
    echo "❌ Error Details:"
    echo "$ERROR_MSG"
    
    # Send error notification
    echo "📡 Sending error notification..."
    WEBHOOK_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{
            \"event\": \"terraform_error\",
            \"timestamp\": \"$TIMESTAMP\",
            \"hostname\": \"$HOSTNAME\",
            \"exit_code\": $EXIT_CODE,
            \"message\": \"Terraform execution failed\",
            \"error_details\": \"$ERROR_MSG\",
            \"source\": \"localhost_drift_detection\"
        }" \
        http://localhost:5678/webhook/drift-error 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✅ Error notification sent"
        echo "🔄 n8n Response: $WEBHOOK_RESPONSE"
    else
        echo "❌ Failed to send error notification"  
        echo "❌ Error: $WEBHOOK_RESPONSE"
    fi
fi

echo "========================================="
echo "Drift check completed at $(date)"
echo "========================================="