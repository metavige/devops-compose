### 產生憑證

- 安裝 `mkcert`

```
$ brew install mkcert
```

- 建立根憑證，並且安裝

```
$ mkcert -install
```

- 建立 traefik 憑證

```
$ mkcert -cert-file traefik.crt -key-file traefik.key "*.docker.internal" "docker.internal"
```
