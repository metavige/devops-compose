### 產生憑證

```
openssl req -x509 -nodes -newkey rsa:2048 -days 350 -keyout traefik.key -out traefik.crt -config req.cnf -extensions 'v3_req'
```

- 放到 `certs` 目錄下
- 記得信任憑證

```
$ certtool i ./traefik.crt
```