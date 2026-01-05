# Vaultwarden - 自託管密碼管理器

Vaultwarden 是 Bitwarden 的輕量級實現，使用 Rust 編寫，資源佔用極低，完全相容所有 Bitwarden 官方客戶端。

## 特色

- ✅ 完全相容 Bitwarden 客戶端（桌面、手機、瀏覽器插件）
- 🚀 極低資源消耗（Raspberry Pi 可運行）
- 🔒 支援所有 Bitwarden 高級功能
- 📦 支援 SQLite、MySQL、PostgreSQL
- 🔄 支援 WebSocket 即時同步
- 📧 支援 SMTP 郵件通知

## 快速開始

### 1. 配置環境變數

```bash
# 複製環境變數範例檔
cp .env.example .env

# 編輯 .env 檔案，至少設定以下項目：
# - VAULTWARDEN_ADMIN_TOKEN (管理員令牌)
# - SMTP_* (郵件設定，可選)
```

### 2. 生成管理員令牌

有兩種方式生成管理員令牌：

**方式 1：使用 Vaultwarden 內建工具**
```bash
# 先啟動服務
docker compose up -d vaultwarden

# 生成令牌雜湊
docker exec -it vaultwarden /vaultwarden hash

# 將生成的雜湊值填入 .env 的 VAULTWARDEN_ADMIN_TOKEN
# 然後重啟服務
docker compose restart vaultwarden
```

**方式 2：使用 OpenSSL**
```bash
openssl rand -base64 48
```

### 3. 啟動服務

```bash
# 僅啟動主服務
docker compose up -d

# 同時啟動備份服務
docker compose --profile backup up -d
```

### 4. 訪問服務

- **Web 界面**: https://vault.docker.internal
- **管理介面**: https://vault.docker.internal/admin

## 首次設定

### 建立第一個帳號

1. 訪問 https://vault.docker.internal
2. 點選「建立帳號」
3. 輸入電子郵件和主密碼
4. **重要**：妥善保管主密碼，遺失後無法恢復

### 停用公開註冊

首個帳號建立後，建議關閉公開註冊：

```bash
# 編輯 .env
VAULTWARDEN_SIGNUPS_ALLOWED=false

# 重啟服務
docker compose restart vaultwarden
```

之後可透過管理介面邀請新用戶。

## 客戶端設定

### 瀏覽器插件

1. 安裝 [Bitwarden 瀏覽器插件](https://bitwarden.com/download/)
2. 點選設定圖示（⚙️）
3. 輸入自架伺服器 URL：`https://vault.docker.internal`
4. 使用您的帳號登入

### 桌面應用程式

1. 下載 [Bitwarden 桌面應用](https://bitwarden.com/download/)
2. 檔案 → 帳號設定
3. 選擇「自託管」
4. 輸入伺服器 URL：`https://vault.docker.internal`
5. 登入

### 行動裝置

1. 安裝 Bitwarden App ([iOS](https://apps.apple.com/app/bitwarden-password-manager/id1137397744) / [Android](https://play.google.com/store/apps/details?id=com.x8bit.bitwarden))
2. 點選設定 → 自託管環境
3. 輸入伺服器 URL：`https://vault.docker.internal`
4. 登入

## 備份與還原

### 啟用自動備份

```bash
# 1. 設定備份相關環境變數（.env 檔案）
RCLONE_REMOTE_NAME=local
RCLONE_REMOTE_DIR=/backup
VAULTWARDEN_BACKUP_CRON=0 2 * * *  # 每天凌晨 2 點
VAULTWARDEN_BACKUP_PASSWORD=your_secure_password
VAULTWARDEN_BACKUP_KEEP_DAYS=30

# 2. 啟動備份服務
docker compose --profile backup up -d
```

### 手動備份

```bash
# 備份資料庫檔案（使用 cp，無需 sqlite3 工具）
docker compose exec vaultwarden sh -c 'cp /data/db.sqlite3 /data/backup/manual-backup-db.sqlite3'

# 或直接複製整個 data 目錄到備份卷
docker compose exec vaultwarden tar czf /backup/manual-full-backup.tar.gz /data
```

### 還原備份

```bash
# 1. 停止服務
docker compose down

# 2. 還原資料
docker run --rm -v vaultwarden_data:/data -v $(pwd)/backup:/backup alpine \
  sh -c "cd /data && tar xzf /backup/your-backup.tar.gz"

# 3. 重啟服務
docker compose up -d
```

## 管理維護

### 訪問管理介面

1. 訪問 https://vault.docker.internal/admin
2. 輸入管理員令牌
3. 可查看用戶、診斷資訊、配置等

### 檢視日誌

```bash
docker compose logs -f vaultwarden
```

### 更新版本

```bash
# 拉取最新映像
docker compose pull

# 重啟服務
docker compose up -d
```

## 安全建議

1. ✅ **使用 HTTPS**：已透過 Traefik 自動配置
2. ✅ **強主密碼**：使用高強度的主密碼
3. ✅ **定期備份**：啟用自動備份並定期測試還原
4. ✅ **關閉公開註冊**：首次設定後立即關閉
5. ✅ **保護管理介面**：妥善保管管理員令牌
6. ⚠️ **防暴力破解**：考慮使用 Fail2ban 監控日誌
7. ⚠️ **定期更新**：保持 Vaultwarden 和 Traefik 最新版本
8. ⚠️ **監控診斷**：定期檢查管理介面的診斷訊息

## 進階設定

### 使用 PostgreSQL

如果預期會有大量用戶，建議使用 PostgreSQL：

```yaml
# docker-compose.yml 中取消註解：
environment:
  - DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/vaultwarden
```

### 配置 Rclone 遠端備份

```bash
# 1. 進入備份容器配置 Rclone
docker compose exec vaultwarden-backup rclone config

# 2. 按照提示配置遠端儲存（如 Google Drive, S3, Dropbox 等）

# 3. 更新 .env 中的 RCLONE_REMOTE_NAME
```

### SMTP 郵件設定範例

**Gmail**
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURITY=starttls
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=your-email@gmail.com
```

**Office 365**
```env
SMTP_HOST=smtp.office365.com
SMTP_PORT=587
SMTP_SECURITY=starttls
SMTP_USERNAME=your-email@outlook.com
SMTP_PASSWORD=your-password
SMTP_FROM=your-email@outlook.com
```

## 常見問題

### Q: 主密碼忘記了怎麼辦？
A: 無法恢復。這是零知識加密的特性，確保只有您能訪問資料。

### Q: 如何遷移現有的 Bitwarden 資料？
A: 從官方 Bitwarden 匯出資料（設定 → 匯出保管庫），然後在 Vaultwarden 中匯入。

### Q: 支援雙因素認證（2FA）嗎？
A: 是的，Vaultwarden 支援 TOTP、WebAuthn、Duo、YubiKey 等多種 2FA 方式。

### Q: 可以在公網使用嗎？
A: 可以，但需要配置公網域名和有效的 SSL 憑證，並加強安全措施。

## 相關連結

- [Vaultwarden Wiki](https://github.com/dani-garcia/vaultwarden/wiki)
- [Bitwarden 官網](https://bitwarden.com/)
- [Bitwarden 客戶端下載](https://bitwarden.com/download/)
- [安全最佳實踐](https://github.com/dani-garcia/vaultwarden/wiki/Security-best-practices)

## 故障排除

### 無法登入
1. 檢查域名設定是否正確
2. 確認 HTTPS 可正常訪問
3. 檢查日誌：`docker compose logs vaultwarden`

### WebSocket 連線失敗
1. 確認 Traefik labels 中的 WebSocket 路由配置正確
2. 檢查防火牆是否阻擋 3012 端口

### 郵件發送失敗
1. 確認 SMTP 設定正確
2. 檢查是否需要使用應用專用密碼（如 Gmail）
3. 查看日誌中的錯誤訊息
