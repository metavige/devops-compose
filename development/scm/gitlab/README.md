## gitlab

- 初始化，如果不知道 gitlab 預設 root 帳號密碼，可以進入到 gitlab 內，使用下列指令重設密碼

```shell
gitlab-rake "gitlab:password:reset[root]"
```

## gitlab-runner

- 進入到 Gitlab
- 進入 Admin Area > Runners 或專案的 Settings > CI/CD > Runners
  - 建立新的 Runner 並取得 registration token
  - 網站會提供指令
- 進入 gitlab-runner container 執行指令

> 這邊是透過內部網路，不經過 https，因為憑證是 `self-signed`

```shell
gitlab-runner register --url http://gitlab/ --token {token}
```
### SSH

```
> ssh-keygen -t ed25519 -C "gitlab-runner"
```

- 複製 ssh key 到 gitlab 內
- 嘗試在 gitlab-runner 內，git clone 一次專案，確認 `~/.ssh/known_hosts` 已經存在

### runner config.toml 設定

幾件事情要注意

- `runner.url` 與 `clone_url` 網址要一樣
- 因為都在同一個 compose 內，所以透過 `http` 存取即可，不需要使用 `https`
  - 搭配 `gitlab.rb` 的設定 `external_url 'http://gitlab.docker.internal'`
  - 有關 HTTP Redirect 的部分，目前會由 traefik 處理
- 如果有需要使用 ssh, `runners.docker` 需要設定好 `volumes`，把本機的設定掛載進去
- 要注意如果有設定 docker, `network_mode` 需要設定好同樣的網路，不然會無法存取 gitlab

```toml
[[runners]]
  name = "docker-runner-1"
  url = "http://gitlab.docker.internal"
  id = 1
  token = "xxxxxx"
  executor = "docker"
  clone_url = "git@gitlab.docker.internal:"

  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache","/root/.ssh:/root/.ssh:ro","/etc/ssl/certs:/etc/ssl/certs:ro"]
    shm_size = 0
    network_mtu = 0
    network_mode = "devops"
```