# wpx

Fast native WordPress development environment for macOS and Linux.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/akash-aman/wpx/main/install.sh | bash
```

Pin a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/akash-aman/wpx/main/install.sh | bash -s -- --version v0.0.0-test.1
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/akash-aman/wpx/main/uninstall.sh | bash
```

## Quick start

```bash
wpx create mysite              # create a WordPress site
wpx create vip --vip           # VIP Go stack (memcached; pass --search for ES)
wpx list                       # list sites
wpx stop mysite                # stop a site
wpx start mysite               # start a site
wpx destroy mysite             # destroy a site
wpx doctor                     # check system health
```

## Requirements

- macOS (arm64) or Linux (amd64)
- Optional: `mkcert` for HTTPS (`brew install mkcert nss`)
- Optional: Docker for Elasticsearch (`--search` flag)
