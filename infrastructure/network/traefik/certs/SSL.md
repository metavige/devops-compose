# SSL 憑證設定指南

本目錄用於存放 SSL/TLS 憑證檔案，為本地開發環境提供 HTTPS 支援。

## 使用 mkcert 生成本地憑證

### 安裝 mkcert

```bash
# macOS
brew install mkcert

# 或使用 curl 下載
curl -JLO "https://dl.filippo.io/mkcert/latest?for=darwin/amd64"
chmod +x mkcert-*
sudo mv mkcert-* /usr/local/bin/mkcert
```

### 初始設定

```bash
# 安裝本地 CA (憑證管理機構)
mkcert -install
```

### 生成通配符憑證

```bash
# 進入憑證目錄
cd infrastructure/network/traefik/certs/

# 方法 1: 使用新的命名約定 (推薦)
mkcert -cert-file local-cert.pem -key-file local-key.pem "*.docker.internal" "docker.internal" localhost 127.0.0.1

# 方法 2: 使用舊的命名約定 (向後兼容)
mkcert -cert-file traefik.crt -key-file traefik.key "*.docker.internal" "docker.internal"
```

### 憑證檔案說明

生成的檔案：
- `local-cert.pem` / `traefik.crt`: 憑證檔案
- `local-key.pem` / `traefik.key`: 私鑰檔案

這些檔案會被 Traefik 的 TLS 配置 (`conf/tls.yml`) 使用。

## 生產環境憑證

### Let's Encrypt 自動憑證

Traefik 已配置 Let's Encrypt 憑證解析器：

```yaml
# docker-compose.yml 中的配置
- '--certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL:-admin@example.com}'
- '--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json'
- '--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web'
```

使用方式：在服務的 labels 中加入：
```yaml
labels:
  - 'traefik.http.routers.myservice.tls.certresolver=letsencrypt'
```

## 安全建議

1. **本地開發**: 使用 mkcert 生成的自簽憑證
2. **測試環境**: 可使用 Let's Encrypt 測試 CA
3. **生產環境**: 使用 Let's Encrypt 或商業憑證

## 故障排除

### 憑證未被信任
- 確認已執行 `mkcert -install`
- 重新啟動瀏覽器
- 檢查系統憑證商店

### 憑證檔案權限
```bash
# 設定適當的檔案權限
chmod 600 *.pem *.crt *.key
```

### 檢查憑證資訊
```bash
# 查看憑證詳細資訊
openssl x509 -in local-cert.pem -text -noout
# 或
openssl x509 -in traefik.crt -text -noout
```
