#!/bin/bash

echo "========================================="
echo "Docker Container Security Scan (Trivy)"
echo "Running at $(date)"
echo "========================================="

# Configuration
TRIVY_IMAGE="aquasec/trivy:latest"
WEBHOOK_BASE_URL="http://localhost:5678/webhook"
SCAN_RESULTS_DIR="/tmp/trivy-scans"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HOSTNAME=$(hostname)

# Ensure scan results directory exists
mkdir -p "$SCAN_RESULTS_DIR"

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ ERROR: Docker not found. Please install Docker first."
    exit 1
fi

# Check if Trivy container image is available
echo "🔍 Checking Trivy availability..."
if ! docker image inspect "$TRIVY_IMAGE" >/dev/null 2>&1; then
    echo "📥 Pulling Trivy image..."
    docker pull "$TRIVY_IMAGE" || {
        echo "❌ Failed to pull Trivy image"
        exit 1
    }
fi

# Function to send webhook notification
send_webhook() {
    local event="$1"
    local container_name="$2"
    local severity="$3"
    local vulnerability_count="$4"
    local scan_result="$5"
    
    echo "📡 Sending security alert to n8n..."
    
    # Prepare JSON payload (escaping for shell)
    WEBHOOK_RESPONSE=$(curl -s -X GET \
        "$WEBHOOK_BASE_URL/security-scan" \
        -G \
        --data-urlencode "event=$event" \
        --data-urlencode "timestamp=$TIMESTAMP" \
        --data-urlencode "hostname=$HOSTNAME" \
        --data-urlencode "container=$container_name" \
        --data-urlencode "severity=$severity" \
        --data-urlencode "vulnerability_count=$vulnerability_count" \
        --data-urlencode "scan_result=$scan_result" \
        --data-urlencode "source=trivy_security_scan" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✅ Security webhook sent successfully"
        echo "🔄 n8n Response: $WEBHOOK_RESPONSE"
    else
        echo "❌ Failed to send security webhook"
        echo "❌ Error: $WEBHOOK_RESPONSE"
    fi
}

# Function to scan a single container
scan_container() {
    local container_name="$1"
    local image_name="$2"
    
    echo ""
    echo "🛡️  Scanning container: $container_name"
    echo "📦 Image: $image_name"
    
    # Run Trivy scan
    SCAN_OUTPUT_FILE="$SCAN_RESULTS_DIR/${container_name}_scan.txt"
    
    echo "🔍 Running vulnerability scan..."
    docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$SCAN_RESULTS_DIR:/output" \
        "$TRIVY_IMAGE" image \
        --format table \
        --severity HIGH,CRITICAL \
        --no-progress \
        --timeout 10m \
        "$image_name" > "$SCAN_OUTPUT_FILE" 2>&1
    
    SCAN_EXIT_CODE=$?
    
    if [ $SCAN_EXIT_CODE -ne 0 ]; then
        echo "❌ Scan failed for $container_name"
        send_webhook "scan_error" "$container_name" "ERROR" "0" "Trivy scan failed with exit code: $SCAN_EXIT_CODE"
        return 1
    fi
    
    # Parse scan results
    CRITICAL_COUNT=$(grep -c "CRITICAL" "$SCAN_OUTPUT_FILE" 2>/dev/null || echo "0")
    HIGH_COUNT=$(grep -c "HIGH" "$SCAN_OUTPUT_FILE" 2>/dev/null || echo "0")
    TOTAL_VULNS=$((CRITICAL_COUNT + HIGH_COUNT))
    
    # Get first few vulnerabilities for summary
    VULN_SUMMARY=$(head -20 "$SCAN_OUTPUT_FILE" | tail -10 || echo "No detailed summary available")
    
    echo "📊 Scan Results:"
    echo "   - Critical: $CRITICAL_COUNT"
    echo "   - High: $HIGH_COUNT"
    echo "   - Total: $TOTAL_VULNS"
    
    # Determine severity level
    if [ "$CRITICAL_COUNT" -gt 0 ]; then
        SEVERITY="CRITICAL"
    elif [ "$HIGH_COUNT" -gt 0 ]; then
        SEVERITY="HIGH"
    elif [ "$TOTAL_VULNS" -gt 0 ]; then
        SEVERITY="MEDIUM"
    else
        SEVERITY="LOW"
    fi
    
    # Send notification based on findings
    if [ "$TOTAL_VULNS" -gt 0 ]; then
        echo "⚠️  VULNERABILITIES DETECTED!"
        send_webhook "vulnerabilities_found" "$container_name" "$SEVERITY" "$TOTAL_VULNS" "$VULN_SUMMARY"
    else
        echo "✅ No high/critical vulnerabilities found"
        send_webhook "scan_clean" "$container_name" "INFO" "0" "No high or critical vulnerabilities detected"
    fi
    
    # Store detailed results
    echo "💾 Full scan results saved to: $SCAN_OUTPUT_FILE"
}

# Function to get all running containers
get_running_containers() {
    docker ps --format "{{.Names}}:{{.Image}}" | grep -v "^trivy"
}

# Main scanning loop
echo "🔍 Discovering running containers..."
CONTAINERS=$(get_running_containers)

if [ -z "$CONTAINERS" ]; then
    echo "ℹ️  No running containers found to scan"
    send_webhook "no_containers" "none" "INFO" "0" "No running containers found for security scanning"
    exit 0
fi

echo "📋 Found containers to scan:"
echo "$CONTAINERS" | while IFS=':' read -r name image; do
    echo "   - $name ($image)"
done

echo ""
echo "🚀 Starting security scans..."

# Counter for summary
TOTAL_CONTAINERS=0
CONTAINERS_WITH_VULNS=0
TOTAL_CRITICAL_VULNS=0
TOTAL_HIGH_VULNS=0

# Scan each container
echo "$CONTAINERS" | while IFS=':' read -r container_name image_name; do
    if [ -n "$container_name" ] && [ -n "$image_name" ]; then
        scan_container "$container_name" "$image_name"
        TOTAL_CONTAINERS=$((TOTAL_CONTAINERS + 1))
        
        # Count vulnerabilities for summary
        SCAN_FILE="$SCAN_RESULTS_DIR/${container_name}_scan.txt"
        if [ -f "$SCAN_FILE" ]; then
            CRITICAL_IN_CONTAINER=$(grep -c "CRITICAL" "$SCAN_FILE" 2>/dev/null || echo "0")
            HIGH_IN_CONTAINER=$(grep -c "HIGH" "$SCAN_FILE" 2>/dev/null || echo "0")
            
            if [ "$((CRITICAL_IN_CONTAINER + HIGH_IN_CONTAINER))" -gt 0 ]; then
                CONTAINERS_WITH_VULNS=$((CONTAINERS_WITH_VULNS + 1))
            fi
            
            TOTAL_CRITICAL_VULNS=$((TOTAL_CRITICAL_VULNS + CRITICAL_IN_CONTAINER))
            TOTAL_HIGH_VULNS=$((TOTAL_HIGH_VULNS + HIGH_IN_CONTAINER))
        fi
    fi
done

# Send summary report
echo ""
echo "========================================="
echo "📊 SECURITY SCAN SUMMARY"
echo "========================================="
echo "🔍 Containers Scanned: $TOTAL_CONTAINERS"
echo "⚠️  Containers with Vulnerabilities: $CONTAINERS_WITH_VULNS"
echo "🚨 Total Critical Vulnerabilities: $TOTAL_CRITICAL_VULNS"
echo "⚡ Total High Vulnerabilities: $TOTAL_HIGH_VULNS"
echo "📁 Detailed results in: $SCAN_RESULTS_DIR"

# Determine overall security posture
if [ "$TOTAL_CRITICAL_VULNS" -gt 0 ]; then
    OVERALL_SEVERITY="CRITICAL"
    OVERALL_STATUS="URGENT_ACTION_REQUIRED"
elif [ "$TOTAL_HIGH_VULNS" -gt 0 ]; then
    OVERALL_SEVERITY="HIGH" 
    OVERALL_STATUS="ACTION_REQUIRED"
elif [ "$CONTAINERS_WITH_VULNS" -gt 0 ]; then
    OVERALL_SEVERITY="MEDIUM"
    OVERALL_STATUS="REVIEW_RECOMMENDED"
else
    OVERALL_SEVERITY="LOW"
    OVERALL_STATUS="ALL_CLEAR"
fi

# Send summary webhook
SUMMARY_MESSAGE="Security scan completed. Scanned: $TOTAL_CONTAINERS containers. Found: $TOTAL_CRITICAL_VULNS critical, $TOTAL_HIGH_VULNS high severity vulnerabilities."

send_webhook "scan_summary" "all_containers" "$OVERALL_SEVERITY" "$((TOTAL_CRITICAL_VULNS + TOTAL_HIGH_VULNS))" "$SUMMARY_MESSAGE"

echo ""
echo "========================================="
echo "Security scan completed at $(date)"
echo "Status: $OVERALL_STATUS"
echo "========================================="

# Cleanup old scan results (keep last 10 scans)
find "$SCAN_RESULTS_DIR" -name "*.txt" -type f -mtime +7 -delete 2>/dev/null || true

exit 0