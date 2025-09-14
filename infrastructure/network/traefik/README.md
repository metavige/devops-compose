# Traefik - 反向代理服務

Traefik 是一個現代化的反向代理和負載均衡器，專為容器化環境設計。

## 功能特色

- **自動服務發現**: 自動偵測 Docker 容器並配置路由
- **SSL/TLS 終端**: 處理 HTTPS 憑證和 SSL 終端
- **負載均衡**: 支援多種負載均衡算法
- **中間件支援**: 認證、壓縮、速率限制等
- **監控面板**: 內建 Web 管理界面

## 服務配置

### 版本
- **映像**: `traefik:v3.5`
- **升級**: 從舊版 v3.2.1 升級

### 端口配置
- `80`: HTTP 入口 (自動重導向至 HTTPS)
- `443`: HTTPS 入口
- `3306`: MySQL TCP 路由
- `5432`: PostgreSQL TCP 路由

### 重要配置檔案

#### **動態配置**
- `conf/middlewares.yml`: 中間件定義 (認證、CORS、安全標頭等)
- `conf/tls.yml`: TLS/SSL 配置

#### **憑證管理**
- `certs/`: SSL 憑證存放目錄
- 支援 Let's Encrypt 自動憑證
- 本地開發可使用 mkcert 生成自簽憑證

## 存取方式

### 管理界面
- **URL**: https://traefik.docker.internal
- **功能**: 服務狀態、路由規則、中間件配置

### API 端點
- 健康檢查: `/ping`
- 指標資料: `/metrics` (Prometheus 格式)

## Whoami 測試服務

包含一個 Whoami 測試服務用於驗證 Traefik 配置：

- **URL**: https://whoami.docker.internal
- **功能**: 顯示請求標頭和伺服器資訊
- **用途**: 測試反向代理是否正常運作

## 安全配置

### 生產環境建議
- 停用不安全的 API: `KC_API_INSECURE=false`
- 啟用基本認證保護管理界面
- 配置適當的 TLS 協定版本
- 啟用安全標頭中間件

### 開發環境
- API 允許不安全存取以便除錯
- 使用自簽憑證
- 開放管理界面端口

## 故障排除

### 常見問題
1. **服務無法存取**: 檢查 DNS 解析 (*.docker.internal)
2. **SSL 憑證錯誤**: 確認憑證檔案路徑和權限
3. **路由不生效**: 檢查 Docker 標籤配置

### 日誌查看
```bash
# 查看 Traefik 日誌
docker-compose -f infrastructure/network/docker-compose.yml logs traefik

# 即時監控日誌
docker-compose -f infrastructure/network/docker-compose.yml logs -f traefik
```

## 相關連結

- [Traefik 官方文檔](https://doc.traefik.io/traefik/)
- [Whoami HTTPS 設定參考](https://community.traefik.io/t/how-to-make-whoami-example-work-with-https-and-self-signed-certificates/3052)