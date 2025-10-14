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