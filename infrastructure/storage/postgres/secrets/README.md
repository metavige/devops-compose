# PostgreSQL 機密檔案設定

此目錄包含 PostgreSQL 相關的機密資訊檔案。

## 必要檔案

### postgres_password.txt
PostgreSQL 資料庫的 postgres 使用者密碼

```bash
# 建立檔案
echo "your_secure_postgres_password" > postgres_password.txt
```

### pgadmin_password.txt
pgAdmin 管理界面的登入密碼

```bash
# 建立檔案
echo "your_secure_pgadmin_password" > pgadmin_password.txt
```

## 安全注意事項

1. **檔案權限**: 確保機密檔案只有擁有者可讀取
   ```bash
   chmod 600 *.txt
   ```

2. **Git 忽略**: 這些檔案已在 .gitignore 中設定忽略，不會被提交

3. **密碼強度**: 使用強密碼，包含大小寫字母、數字和特殊字元

4. **定期更換**: 定期更換密碼以提高安全性

## 初始化

如果檔案不存在，可以使用以下命令生成隨機密碼：

```bash
# 生成隨機密碼
openssl rand -base64 32 > postgres_password.txt
openssl rand -base64 32 > pgadmin_password.txt

# 設定適當權限
chmod 600 *.txt
```