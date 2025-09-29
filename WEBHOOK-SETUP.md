# N8N Workflow Setup Guide

## 🚀 Quick Setup untuk n8n Webhooks

### 1. Start n8n (jika belum running)

```bash
# Install n8n jika belum ada
npm install n8n -g

# Start n8n
n8n start
# atau 
npx n8n
```

### 2. Akses n8n Interface

Buka browser: http://localhost:5678

### 3. Import Workflow Basic

1. **Create New Workflow**
2. **Import workflow JSON** dari file: `n8n-workflows/drift-detection-basic.json`
3. **Activate workflow**

### 4. Setup Webhook Endpoints

Untuk testing cepat, buat 3 webhook nodes dengan path:

- `/webhook/drift-detected` - untuk drift alerts
- `/webhook/drift-status` - untuk status OK  
- `/webhook/drift-error` - untuk errors

### 5. Test Webhook

Setelah webhook aktif, test dengan:

```bash
# Test drift detection
./scripts/drift-check-localhost.sh

# Manual webhook test
curl -X POST http://localhost:5678/webhook/drift-detected \
  -H "Content-Type: application/json" \
  -d '{"test": "manual test"}'
```

## 📋 Alternative: Simple HTTP Server untuk Testing

Jika n8n belum ready, gunakan simple HTTP server:

```bash
# Terminal 1: Start simple HTTP server
python3 -m http.server 5678

# Terminal 2: Test drift detection
./scripts/drift-check-localhost.sh
```

## 🎯 Current Issue

n8n webhook endpoint `/webhook/drift-detected` belum dikonfigurasi, menyebabkan:
- Response: 404 "This webhook is not registered for POST requests"
- Solution: Setup webhook dalam n8n workflow

## ✅ Script Status

Drift detection script sudah bekerja dengan benar:
- ✅ Deteksi terraform drift (exit code 2)
- ✅ Proper webhook payload dengan detail perubahan
- ✅ POST method yang benar
- ✅ Response handling yang informatif

**Next step**: Setup n8n webhook atau gunakan alternative notification method.