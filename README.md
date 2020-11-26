## Trarfik

考慮到每種服務，可能都有自己的服務端點，但服務跟服務之間可能有重複的 Port  
使用上不方便，所以考慮使用 traefik 在本機  
透過 customize domain 的方式，以及在本機的 `dnsmasq` 服務，做到在本機的開發環境測試  

## Local Development

- 此份資料是用在本地端開發使用
- 為了 Performance Issue, 不使用 `kubernetes`
- 不是統一啟動，有需要再進入目錄，使用 `docker-compose up -d` 啟動
- 所有的服務入口，統一透過 traefik 進入