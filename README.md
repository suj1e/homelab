# homelab

阿里云 2C4G 个人服务器基础设施：

```text
Internet
    │
    └── Caddy :80/:443
          │
          ├── Homepage       home.<domain>
          ├── Uptime Kuma    kuma.<domain>
          ├── Beszel         beszel.<domain>
          ├── n8n             n8n.<domain>
          └── Home Assistant ha.<domain>
                                  │
                                  └── Xiaomi Home → 米家云
```

## 目录

```text
homelab/
├── README.md
├── compose.yml
├── .env.example
├── .gitignore
├── caddy/
│   └── Caddyfile
├── homepage/
│   ├── docker.yaml
│   ├── services.yaml
│   ├── settings.yaml
│   └── widgets.yaml
├── uptime-kuma/
├── beszel/
├── n8n/
├── scripts/
│   └── install-xiaomi-home.sh
└── home-assistant/
    └── configuration.yaml
```

运行数据、证书、数据库、工作流和密钥都留在本机目录，不提交到 GitHub。

## 子域名和 DNS

将以下记录指向阿里云服务器公网 IP：

```text
home.example.com
kuma.example.com
beszel.example.com
n8n.example.com
ha.example.com
```

也可以配置 `*.example.com` 的泛域名记录。阿里云安全组只需要放行 TCP 80/443；SSH 端口按自己的安全策略处理。

## 首次部署

在服务器上执行：

```bash
git clone https://github.com/suj1e/homelab.git
cd homelab
cp .env.example .env
```

编辑 `.env`：

1. 将 `BASE_DOMAIN` 和 `ACME_EMAIL` 改成真实值。
2. 将 Homepage、n8n 的域名改成对应的真实子域名。
3. 用 `openssl rand -hex 32` 生成 `N8N_ENCRYPTION_KEY`，以后不要更换。
4. Beszel 的 `BESZEL_AGENT_KEY/TOKEN` 先保留占位值，完成下方的 Beszel 初始化后再填写。

先检查 Compose 展开结果：

```bash
docker compose config
```

确认无误后启动主服务：

```bash
docker compose up -d
docker compose ps
```

Caddy 会自动申请并续期 HTTPS 证书。第一次申请证书前，需要确保 DNS 已生效且 80/443 可以从公网访问。

## Beszel 初始化

1. 打开 `https://beszel.<domain>`，创建 Hub 管理员账号。
2. 在 Beszel 中添加当前服务器系统。
3. 选择 Unix socket 方式，并使用：

   ```text
   /beszel_socket/beszel.sock
   ```

4. 将 Beszel 页面生成的 `KEY` 和 `TOKEN` 填入 `.env`。
5. 启动 Agent profile：

   ```bash
   docker compose --profile beszel-agent up -d beszel-agent
   ```

Agent 使用宿主机网络和 Docker socket，用于采集阿里云服务器及容器指标；它默认不会在普通 `docker compose up -d` 中启动，避免在还没有 Hub 凭证时反复重启。

## Home Assistant 和 Xiaomi Home

打开 `https://ha.<domain>`，完成 Home Assistant 初始化后：

仓库提供了官方 Xiaomi Home 自定义集成的可重复安装脚本。首次安装或更新组件时，在仓库根目录执行：

```bash
bash scripts/install-xiaomi-home.sh
docker compose restart homeassistant
```

脚本默认固定安装官方仓库的 `v0.4.7`。需要升级时，显式指定官方仓库中的版本：

```bash
XIAOMI_HOME_REF=v0.4.7 bash scripts/install-xiaomi-home.sh
docker compose restart homeassistant
```

组件代码会安装到 Home Assistant 的运行目录，该目录已被 `.gitignore` 忽略；账号、OAuth token 和设备数据不会进入 Git。

1. 进入 **Settings → Devices & services**。
2. 选择 **Add Integration**。
3. 搜索并添加 **Xiaomi Home**。
4. 使用米家 App 对应的 Xiaomi 账号，并选择设备所在的服务器区域。

米家云可访问的摄像头、音箱、插座等设备会由 Xiaomi Home 集成提供给 Home Assistant。需要家庭局域网发现、蓝牙、Zigbee 或 Matter 的设备，不属于阿里云服务器这套远程云接入范围，后续应迁移 Home Assistant 到家中的设备或增加专门的家庭网关。

## 更新和备份

更新镜像：

```bash
git pull
docker compose pull
docker compose up -d
```

至少备份以下目录：

```text
caddy/data/
uptime-kuma/
beszel/data/
n8n/
home-assistant/
```

`.env` 也必须单独安全备份，尤其是 `N8N_ENCRYPTION_KEY` 和 Beszel 凭证。
