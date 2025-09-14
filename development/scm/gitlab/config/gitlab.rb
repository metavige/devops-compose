gitlab_rails['initial_root_password'] = '<my_strong_password>'

external_url 'https://gitlab.gitlab.orb.local'
gitlab_rails['gitlab_shell_ssh_port'] = 8822

nginx['listen_port'] = 80
nginx['listen_https'] = false
nginx['redirect_http_to_https'] = true
letsencrypt['enable'] = false