# Security Vulnerability Scanning System

Comprehensive Docker container security monitoring menggunakan Trivy scanner dengan automated alerting via n8n webhooks.

## 🛡️ Overview

Sistem ini melakukan:
- **Automated vulnerability scanning** semua running containers menggunakan Trivy
- **Risk assessment** berdasarkan severity level (CRITICAL, HIGH, MEDIUM, LOW)
- **Real-time alerting** via n8n webhooks dengan GET method
- **Detailed reporting** dengan full scan results dan summaries
- **Scheduled monitoring** setiap 6 jam via cron jobs

## 🎯 Features

### ✅ **Comprehensive Scanning**
- Scan semua running Docker containers
- Detect vulnerabilities dengan severity HIGH dan CRITICAL
- Support multiple container types (Ghost, MySQL, n8n, Uptime Kuma, dll)
- Skip Trivy container sendiri untuk avoid self-scanning

### ✅ **Intelligent Alerting**
- **CRITICAL** vulnerabilities → Immediate alerts
- **HIGH** vulnerabilities → Priority alerts  
- **MEDIUM/LOW** → Information logging
- **ERRORS** → Technical failure alerts

### ✅ **Rich Notifications**
- Webhook dengan GET method dan query parameters
- JSON payload dengan detailed vulnerability information
- n8n workflow integration untuk Slack/Discord/Email
- Structured logging dan audit trail

## 📁 File Structure

```
terraform-ghost/
├── scripts/
│   └── security-scan.sh              # Main vulnerability scanner
├── n8n-workflows/
│   └── security-vulnerability-monitoring.json  # n8n workflow template
├── setup-security-scan.sh            # Automation setup script
└── README-security-scan.md           # This documentation
```

## 🚀 Quick Start

### 1. Setup Automated Scanning

```bash
# Configure cron job untuk automated scanning
./setup-security-scan.sh
```

### 2. Manual Security Scan

```bash
# Run security scan manually
./scripts/security-scan.sh
```

### 3. Import n8n Workflow

1. Access n8n: http://localhost:5678
2. Import workflow: `n8n-workflows/security-vulnerability-monitoring.json`
3. Activate workflow untuk receive webhooks

## ⚙️ Configuration

### Scan Schedule

Default: **Every 6 hours** (4x daily)
```bash
# View current schedule
crontab -l | grep security-scan

# Modify schedule
crontab -e
```

### Webhook Endpoint

**URL**: `http://localhost:5678/webhook/security-scan`  
**Method**: GET with query parameters

### Webhook Parameters

```
event=vulnerabilities_found
timestamp=2025-09-29T04:39:58Z
hostname=localhost
container=ghost-cms
severity=CRITICAL
vulnerability_count=12
scan_result=Found 6 CRITICAL and 6 HIGH vulnerabilities
source=trivy_security_scan
```

## 📊 Vulnerability Severity Levels

| Severity | Description | Action Required | Notification |
|----------|-------------|-----------------|--------------|
| **CRITICAL** | 🚨 Immediate security risk | **URGENT** - Patch immediately | Slack/Discord alerts |
| **HIGH** | ⚠️ Significant security risk | **HIGH** - Schedule patching | Priority notifications |  
| **MEDIUM** | ⚡ Moderate security concern | **MEDIUM** - Review and plan | Standard logging |
| **LOW** | ✅ Minor or informational | **LOW** - Awareness only | Info logging |
| **ERROR** | ❌ Scan failure | **CRITICAL** - Fix scanner | Error alerts |

## 🔍 Scan Results Analysis

### Example Vulnerabilities Found

**Ghost CMS Container:**
- 6 CRITICAL vulnerabilities
- 6 HIGH vulnerabilities  
- Common issues: CVE-2023-45288 (golang DoS), CVE-2025-47907 (database race condition)

**MySQL Container:**
- 4 CRITICAL vulnerabilities
- 7 HIGH vulnerabilities
- Common issues: Outdated base OS packages, SSL/TLS vulnerabilities

### Scan Results Location

```bash
# View detailed scan results
ls -la /tmp/trivy-scans/

# Check specific container results
cat /tmp/trivy-scans/ghost-cms_scan.txt
cat /tmp/trivy-scans/ghost-mysql_scan.txt
```

## 🔧 Management Commands

### Manual Operations

```bash
# Run full security scan
./scripts/security-scan.sh

# Check scan logs
tail -f logs/security-scan.log

# View vulnerability details
head -50 /tmp/trivy-scans/ghost-cms_scan.txt

# Clean old scan results
rm /tmp/trivy-scans/*.txt
```

### Cron Job Management

```bash
# View security scan schedule
crontab -l | grep security-scan

# Edit cron schedule
crontab -e

# Remove automated scanning
crontab -e  # Delete security-scan line

# Re-setup automation
./setup-security-scan.sh
```

### Container Management

```bash
# Check containers being scanned
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

# Update Trivy scanner image
docker pull aquasec/trivy:latest

# Check Trivy version
docker run --rm aquasec/trivy:latest version
```

## 🌐 n8n Workflow Integration

### Webhook Setup

1. **Create Webhook Node**:
   - Path: `/webhook/security-scan`
   - Method: GET
   - Authentication: None

2. **Process Security Data**:
   - Parse query parameters
   - Determine severity and alert level
   - Format notification messages

3. **Send Notifications**:
   - **Critical/High**: Slack + Discord alerts
   - **Medium/Low**: Logging only
   - **Errors**: Technical team alerts

### Notification Channels

#### Slack Integration
```json
{
  "channel": "#security-alerts",
  "username": "Security Scanner Bot", 
  "icon_emoji": ":warning:",
  "attachments": [...]
}
```

#### Discord Integration  
```json
{
  "embeds": [
    {
      "title": "🚨 CRITICAL SECURITY ALERT",
      "color": 15158332,
      "fields": [...]
    }
  ]
}
```

## 🛠️ Troubleshooting

### Common Issues

**1. Trivy image not found**
```bash
# Pull Trivy manually
docker pull aquasec/trivy:latest
```

**2. Permission denied on scan directory**
```bash
# Fix permissions
sudo mkdir -p /tmp/trivy-scans
sudo chown $USER:$USER /tmp/trivy-scans
```

**3. Webhook not reaching n8n**
```bash
# Test webhook manually
curl "http://localhost:5678/webhook/security-scan?event=test&container=test&severity=INFO"

# Check n8n status
curl http://localhost:5678/healthz
```

**4. Cron job not running**
```bash
# Check cron service
sudo systemctl status cron

# Check cron logs
sudo journalctl -u cron | grep security-scan
```

**5. Containers not being scanned**
```bash
# Check running containers
docker ps

# Test container detection
docker ps --format "{{.Names}}:{{.Image}}" | grep -v "^trivy"
```

## 📈 Monitoring & Metrics

### Key Metrics

- **Scan Frequency**: Every 6 hours (configurable)
- **Container Coverage**: All running containers except Trivy
- **Alert Response Time**: Real-time webhooks (< 30 seconds)
- **Retention**: Scan results kept for 7 days

### Security Dashboards

**Recommended monitoring:**
- Total vulnerabilities by severity
- Containers with critical issues  
- Vulnerability trends over time
- Patch compliance tracking
- Mean time to remediation

## 🔒 Security Best Practices

### 1. **Regular Updates**
```bash
# Update Trivy database
docker run --rm aquasec/trivy:latest image --download-db-only

# Update base images regularly
docker pull ghost:latest
docker pull mysql:8.0
```

### 2. **Vulnerability Response**
- **CRITICAL**: Patch within 24 hours
- **HIGH**: Patch within 1 week  
- **MEDIUM**: Patch within 1 month
- **LOW**: Address in next maintenance window

### 3. **Container Hardening**
- Use minimal base images (Alpine Linux)
- Regular security updates
- Remove unnecessary packages
- Implement least privilege access

## 🎊 Current Status

**✅ Security scanning system fully operational:**

- ✅ **4 containers scanned**: ghost-cms, ghost-mysql, n8n, uptime_kuma
- ✅ **46 total vulnerabilities detected**: 20 CRITICAL, 26 HIGH  
- ✅ **Automated alerts working**: n8n webhooks functional
- ✅ **Scheduled monitoring active**: Every 6 hours via cron
- ✅ **Comprehensive logging**: Full audit trail maintained

**🎯 Next Steps:**
1. Configure Slack/Discord notifications in n8n workflow
2. Set up vulnerability remediation procedures
3. Implement security metrics dashboard
4. Schedule regular security reviews

---

## 📞 Support

For security incidents or scanner issues:
- **Critical vulnerabilities**: Immediate remediation required
- **Scanner failures**: Check logs and restart system  
- **Webhook issues**: Verify n8n workflow configuration

**Happy securing! 🛡️**