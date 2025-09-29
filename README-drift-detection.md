# Terraform Drift Detection (Localhost)

Simple localhost-based drift detection system untuk monitoring Terraform infrastructure changes tanpa Docker dependency.

## 🎯 Overview

Sistem ini melakukan:
- **Automated drift detection** setiap 5 menit menggunakan cron
- **Terraform plan monitoring** untuk detect infrastructure changes  
- **n8n webhook integration** untuk notifications dan workflow automation
- **Localhost execution** - no Docker containers required

## 📁 Structure

```
terraform-ghost/
├── scripts/
│   └── drift-check-localhost.sh    # Main drift detection script
├── logs/
│   └── drift-detection.log         # Cron job logs  
├── setup-drift-detection.sh        # Setup script for cron job
└── README-drift-detection.md       # This file
```

## 🚀 Quick Start

### 1. Setup Drift Detection

```bash
# Run setup script to configure cron job
./setup-drift-detection.sh
```

### 2. Manual Test

```bash
# Test drift detection manually
./scripts/drift-check-localhost.sh
```

### 3. Monitor Logs

```bash
# View drift detection logs
tail -f logs/drift-detection.log

# View cron job status
crontab -l | grep drift-check
```

## ⚙️ Configuration

### Webhook Endpoints

The script sends webhooks to n8n on localhost:5678:

- **Drift Detected**: `POST /webhook/drift-detected`
- **No Drift**: `POST /webhook/drift-status`  
- **Error**: `POST /webhook/drift-error`

### Cron Schedule

Default: Every 5 minutes
```bash
*/5 * * * * cd /path/to/terraform-ghost && ./scripts/drift-check-localhost.sh
```

To modify schedule:
```bash
crontab -e
```

### Webhook Payload Examples

**Drift Detected:**
```json
{
  "event": "drift_detected",
  "timestamp": "2025-09-29T02:30:00Z",
  "hostname": "localhost",
  "exit_code": 2,
  "message": "Configuration drift detected",
  "summary": "Plan: 2 to add, 0 to change, 2 to destroy.",
  "source": "localhost_drift_detection"
}
```

**No Drift:**
```json
{
  "event": "no_drift",
  "timestamp": "2025-09-29T02:30:00Z", 
  "hostname": "localhost",
  "exit_code": 0,
  "message": "No configuration drift detected",
  "source": "localhost_drift_detection"
}
```

## 🔧 Management Commands

### Start/Stop Monitoring

```bash
# View current cron jobs
crontab -l

# Remove drift detection cron job
crontab -e
# (Delete the drift-check-localhost.sh line)

# Re-add cron job
./setup-drift-detection.sh
```

### Debugging

```bash
# Check terraform status
terraform --version
terraform validate

# Manual drift check with verbose output
cd /path/to/terraform-ghost
./scripts/drift-check-localhost.sh

# Check cron service
systemctl status cron  # Ubuntu/Debian
systemctl status crond  # CentOS/RHEL
```

### Logs

```bash
# Real-time log monitoring
tail -f logs/drift-detection.log

# Search for specific events
grep "DRIFT DETECTED" logs/drift-detection.log
grep "ERROR" logs/drift-detection.log

# Log rotation (manual cleanup)
> logs/drift-detection.log  # Clear logs
```

## 🔗 n8n Integration

### Setup n8n Workflows

1. **Install n8n** (if not already installed):
```bash
npm install n8n -g
# atau
npx n8n
```

2. **Create Webhook Workflows**:
   - Access n8n: http://localhost:5678
   - Create workflows dengan webhook nodes
   - Use webhook URLs: `/webhook/drift-detected`, `/webhook/drift-status`, `/webhook/drift-error`

3. **Example n8n Workflow**:
   ```
   Webhook (drift-detected) → IF (event=drift_detected) → Slack/Email/Discord
   ```

### Notification Examples

- **Slack Integration**: Send alerts to team channels
- **Email Notifications**: SMTP-based email alerts  
- **Discord Webhooks**: Gaming/dev team notifications
- **GitHub Issues**: Auto-create issues for drift incidents
- **PagerDuty**: Critical infrastructure alerts

## 🛡️ Security Considerations

- **Localhost Only**: No external network exposure
- **File Permissions**: Scripts require execute permissions
- **Cron Security**: Jobs run with user permissions
- **Log Rotation**: Prevent log file growth  

## 🐛 Troubleshooting

### Common Issues

**1. Terraform not found**
```bash
# Install terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

**2. Cron job not running**
```bash
# Check cron service
sudo systemctl status cron
sudo systemctl start cron

# Check cron logs
sudo journalctl -u cron
grep CRON /var/log/syslog
```

**3. Webhook not reaching n8n**
```bash
# Check n8n is running
curl http://localhost:5678/healthz

# Start n8n
npx n8n
# atau
n8n start
```

**4. Permission errors**
```bash
# Fix script permissions
chmod +x scripts/drift-check-localhost.sh
chmod +x setup-drift-detection.sh

# Fix log directory permissions
mkdir -p logs
chmod 755 logs
```

## 📊 Monitoring & Metrics

### Key Metrics to Track

- **Drift Detection Frequency**: How often drifts are detected
- **False Positives**: Expected vs unexpected drifts
- **Response Time**: Time from detection to remediation
- **Infrastructure Stability**: Drift trends over time

### Dashboard Ideas

- **Grafana**: Time-series drift detection metrics
- **n8n Dashboard**: Workflow execution status
- **Simple Logs**: grep-based log analysis

## 🔄 Advanced Usage

### Custom Scheduling

```bash
# Hourly during business hours
0 9-17 * * 1-5 cd /path/to/project && ./scripts/drift-check-localhost.sh

# Daily at 2 AM
0 2 * * * cd /path/to/project && ./scripts/drift-check-localhost.sh

# Every 30 seconds (for testing)
* * * * * cd /path/to/project && ./scripts/drift-check-localhost.sh
* * * * * sleep 30 && cd /path/to/project && ./scripts/drift-check-localhost.sh
```

### Integration dengan CI/CD

```yaml
# GitHub Actions example
- name: Run Drift Detection
  run: |
    cd terraform-ghost
    ./scripts/drift-check-localhost.sh
```

### Multiple Environment Support

```bash
# Create environment-specific scripts
cp scripts/drift-check-localhost.sh scripts/drift-check-staging.sh
cp scripts/drift-check-localhost.sh scripts/drift-check-production.sh

# Modify each script for different terraform workspaces
```

---

## 📞 Support

Untuk issues atau feature requests, silakan buka GitHub issue atau hubungi tim DevOps.

**Happy monitoring! 🎉**