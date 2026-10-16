# devops-compose

本機開發用的 DevOps 服務集合。每個服務一個資料夾，各自一份 `docker-compose.yml`，有需要再啟動。

## 設計原則

- 以本機開發為核心，不使用 Kubernetes，避免筆電資源被吃光
- 不統一啟動，需要哪個服務就起哪個
- 所有服務共用 `devops` network，彼此可以用 compose service 名稱互連
- 所有 HTTP 入口統一透過 Traefik，每個服務以 `<service>.${MY_DOMAIN}` 存取，不用記 port
- DNS 由 repo 內的 CoreDNS 容器提供，不依賴主機上額外安裝的 dnsmasq
- HTTPS 憑證以 `mkcert` 自簽，瀏覽器不會跳警告

## 架構

```
瀏覽器 / CLI
   │  https://nexus.docker.internal
   ▼
macOS resolver (/etc/resolver/docker.internal)
   │  *.docker.internal → 127.0.0.1:10053
   ▼
CoreDNS 容器 ──► 回 127.0.0.1
   │
   ▼
Traefik 容器 (:80 / :443)
   │  依 Host 轉發
   ▼
各服務容器 (devops network)
```

- `traefik/`：Traefik 與 CoreDNS 兩個 service 放在同一份 compose，一起啟動
- CoreDNS 只回答 `${MY_DOMAIN}` 這個 zone，不接管其他 DNS 查詢
- Traefik 的 `defaultRule` 會用 compose service 名稱自動產生 `Host()` 規則，多數服務不用額外寫 rule

## 前置需求

| 工具 | 用途 | 安裝 |
|---|---|---|
| Docker Desktop | 跑容器 | https://www.docker.com/ |
| task | 指令入口 | `brew install go-task` |
| mkcert | 本機 HTTPS 憑證 | `brew install mkcert` |

## 第一次設定

只需要做一次。

1. 建立共用 network

   ```sh
   task network
   ```

2. 設定 macOS resolver，讓 `*.docker.internal` 交給 CoreDNS 解析（需要 sudo）

   ```sh
   task dns:setup
   ```

   這個指令會寫入 `/etc/resolver/docker.internal`：

   ```
   nameserver 127.0.0.1
   port 10053
   ```

3. 產生憑證並安裝根憑證

   ```sh
   mkcert -install
   cd traefik/certs
   mkcert -cert-file traefik.crt -key-file traefik.key "*.docker.internal" "docker.internal"
   ```

4. 啟動 Traefik 與 CoreDNS

   ```sh
   task
   ```

5. 驗證

   ```sh
   task dns:check          # 等同 dscacheutil -q host -a name traefik.docker.internal
   curl -I https://traefik.docker.internal
   ```

   注意 `dig` 與 `nslookup` 不會走 `/etc/resolver`，用它們測會以為沒生效。

## 日常使用

```sh
task                      # 啟動 traefik + coredns
task start -- nexus       # 啟動 nexus
task stop -- nexus        # 停止 nexus，保留容器
task down -- nexus        # 移除 nexus 容器
task config -- nexus      # 檢視合併後的 compose 設定
```

`--` 後面接的是服務資料夾名稱。

## .env

```
MY_DOMAIN=docker.internal
DEFAULT_NETWORK=devops
BASE_NETWORK_YAML="docker-compose.network.yaml"
```

- `MY_DOMAIN`：所有服務的 domain 尾綴，Traefik label 與 CoreDNS zone 都從這裡展開
- `BASE_NETWORK_YAML`：每個服務啟動時都會一起載入的共用 network 設定

## 新增服務的慣例

在新資料夾放一份 `docker-compose.yml`，不要寫 `version:`，不要自己宣告 network。

```yaml
services:
  myapp:
    image: example/myapp
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.myapp.tls=true'
      - 'traefik.http.routers.myapp.entrypoints=websecure'
      - 'traefik.http.services.myapp.loadbalancer.server.port=8080'
```

- service 名稱就是 subdomain，上例會得到 `https://myapp.docker.internal`
- 需要自訂 host 時再加 `traefik.http.routers.myapp.rule=Host(\`other.$MY_DOMAIN\`)`
- 資料持久化用 named volume，不要 bind mount 到 repo 目錄內
- 容器內要存取其他服務的對外網址時（例如 Jenkins 連 `nexus.docker.internal`），加 `extra_hosts`，流量會經由主機的 Traefik 回來：

  ```yaml
  extra_hosts:
    - 'nexus.${MY_DOMAIN}:host-gateway'
  ```

## 斷網或 DNS 被擋時的備援

CoreDNS 方案不依賴外部網路。若在其他機器上臨時使用、不想動系統 resolver，可以改用公開的萬用 DNS：

```
MY_DOMAIN=127.0.0.1.nip.io
```

改完 `task` 重啟 Traefik 即可，網址變成 `https://nexus.127.0.0.1.nip.io`。這種方式需要能連外，且可能被企業 DNS 的 rebinding 防護擋掉。憑證要另外涵蓋這個 domain：

```sh
mkcert -cert-file traefik.crt -key-file traefik.key \
  "*.docker.internal" "docker.internal" \
  "*.127.0.0.1.nip.io" "127.0.0.1.nip.io"
```

## 疑難排解

| 現象 | 原因 | 處理 |
|---|---|---|
| 所有 `*.docker.internal` 都打不開 | CoreDNS 沒跑 | `docker ps` 確認，`task` 重啟 |
| `dig` 查不到但瀏覽器可以 | `dig` 不走 `/etc/resolver` | 用 `dscacheutil` 或 `curl` 驗證 |
| 瀏覽器跳憑證警告 | 沒跑 `mkcert -install`、憑證沒涵蓋 domain 或已過期（mkcert 憑證效期約 2 年 3 個月） | 重做「第一次設定」第 3 步，`openssl x509 -in traefik/certs/traefik.crt -noout -dates` 可查效期 |
| 所有服務都 404，Traefik log 出現 `client version ... is too old` | Traefik 版本太舊，Docker 拒絕其 API | 升級 `traefik/docker-compose.yml` 的 image 版本 |
| 第一次 `task start` 失敗，說 network 不存在 | 沒建 `devops` network | `task network` |
