Ghost terraform code using docker.

Pastikan sudah ada terraform.tfvars yang mengandung `database_password="PASSWORDDATABASE"` sebagai password, dan password harus berupa string (tidak bisa numberik for some reason?)

Untuk penelitian RSBP.

untuk menjalankan docker (uptime kuma, trivy), jalankan perintah:
```bash
docker-compose up -d
```
Perintah akan secara otomatis mendownload dan membuat container-container yang diperlukan.

Script yang harus dijalankan (bisa manual/otomatis menggunakan cron):
```bash
./scripts/check_drift.sh
./scripts/security-scan.sh
```

Workflow n8n:
```.
├ n8n_workflows
```
Impor ke n8n.