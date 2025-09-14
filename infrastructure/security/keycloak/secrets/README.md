# Keycloak 機密檔案設定

此目錄包含 Keycloak 相關的機密資訊檔案。

## 必要檔案

### keycloak_admin_password.txt
Keycloak 管理員帳號密碼 (admin 使用者)

```bash
# 建立檔案
echo "your_secure_admin_password" > keycloak_admin_password.txt
```

### keycloak_db_password.txt
Keycloak 資料庫使用者密碼 (用於連接 PostgreSQL)

```bash
# 建立檔案
echo "your_secure_db_password" > keycloak_db_password.txt
```

## 安全注意事項

1. **檔案權限**: 確保機密檔案只有擁有者可讀取
   ```bash
   chmod 600 *.txt
   ```

2. **Git 忽略**: 這些檔案已在 .gitignore 中設定忽略，不會被提交

3. **密碼強度**:
   - 管理員密碼：至少 12 位，包含大小寫字母、數字和特殊字元
   - 資料庫密碼：可使用更長的隨機密碼

4. **資料庫權限**: keycloak_db_password.txt 中的密碼需要與 PostgreSQL 中設定的密碼一致

## 初始化

### 自動生成隨機密碼
```bash
# 生成隨機密碼
openssl rand -base64 32 > keycloak_admin_password.txt
openssl rand -base64 32 > keycloak_db_password.txt

# 設定適當權限
chmod 600 *.txt
```

### 手動設定密碼
```bash
# 設定管理員密碼 (記得要記住這個密碼)
echo "MySecureAdminPassword123!" > keycloak_admin_password.txt

# 設定資料庫密碼
echo "MySecureDbPassword456!" > keycloak_db_password.txt

# 設定權限
chmod 600 *.txt
```

## 資料庫配置

確保在 PostgreSQL 中建立對應的使用者和資料庫：

```sql
-- 在 PostgreSQL 中執行
CREATE USER keycloak WITH PASSWORD 'your_secure_db_password';
CREATE DATABASE keycloak OWNER keycloak;
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
```

## 首次登入

啟動 Keycloak 後，使用以下資訊登入管理界面：

- **URL**: https://keycloak.docker.internal
- **使用者名稱**: admin
- **密碼**: keycloak_admin_password.txt 檔案中的內容