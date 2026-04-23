# wpx

Native WordPress development environment for macOS and Linux. Zero Docker, zero VMs — runs nginx, PHP-FPM, MySQL/MariaDB, Redis/Memcached, Mailpit, and more as native processes. Create a fully working WordPress site in ~12 seconds.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/akash-aman/wpx/main/install.sh | bash
```

Pin a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/akash-aman/wpx/main/install.sh | bash -s -- --version v0.1.0
```

### Requirements

- **macOS** (arm64) or **Linux** (amd64)
- Optional: `mkcert` for HTTPS — `brew install mkcert nss`
- Optional: Docker for Elasticsearch — `--search` flag

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/akash-aman/wpx/main/uninstall.sh | bash
```

## Quick start

```bash
wpx create mysite                        # WordPress site (~12s)
wpx create mysite --php=8.3              # specific PHP version
wpx create mysite --db=mariadb           # MariaDB instead of MySQL
wpx create mysite --cache=redis          # Redis object cache (default)
wpx create mysite --cache=memcached      # Memcached object cache
wpx create mysite --cache=none           # no object cache
wpx create mysite --db=sqlite            # SQLite (no DB server)
wpx create mysite --multisite            # WordPress multisite (subdirectory)
wpx create mysite --multisite --multisite-subdomains  # multisite (subdomains)
wpx create mysite --domain=mysite.dev    # custom domain
wpx create mysite --repo=git@...        # clone repo as wp-content/
wpx create vipsite --vip                 # VIP Go stack (memcached)
wpx create vipsite --vip --search        # VIP Go + Elasticsearch
```

## Commands

### Site lifecycle

```bash
wpx create <site>                    # create a new WordPress site
wpx create <site> --no-tui           # plain text output (no interactive TUI)
wpx start <site>                     # start all services
wpx start <site> [service]           # start a single service (nginx, php-fpm, mysql, etc.)
wpx start --all                      # start all sites
wpx stop <site>                      # stop all services
wpx stop <site> [service]            # stop a single service
wpx stop --all                       # stop all sites
wpx restart <site>                   # restart all services
wpx restart <site> [service]         # restart a single service
wpx restart --all                    # restart all sites
wpx reload <site>                    # graceful reload (SIGHUP/SIGUSR2)
wpx reload <site> [service]          # reload a single service
wpx reload --all                     # reload all sites
wpx destroy <site> --force           # stop + delete site files
wpx destroy --all --force            # destroy everything
```

#### Create flags

| Flag | Default | Description |
|---|---|---|
| `--php` | latest | PHP version (e.g. 8.3, 8.5) |
| `--db` | mysql | Database engine: `mysql`, `mariadb`, `sqlite` |
| `--db-version` | latest | Database version (e.g. 8.4, 11.4.4, 10.6) |
| `--cache` | redis | Cache backend: `redis`, `memcached`, `none` |
| `--cache-version` | latest | Cache version (e.g. 8.6.2, 1.6.41) |
| `--nginx-version` | latest | Nginx version |
| `--domain` | `<name>.test` | Custom site domain |
| `--multisite` | false | Enable WordPress multisite (subdirectory) |
| `--multisite-subdomains` | false | Use subdomain multisite instead |
| `--vip` | false | VIP Go layout + mu-plugins (forces memcached) |
| `--search` | false | Enable Elasticsearch (Docker) |
| `--ssl` | true | HTTPS via mkcert |
| `--mail` | true | Enable Mailpit (SMTP + web UI) |
| `--repo` | — | Git repo URL to clone as `wp-content/` |
| `--wp-version` | latest | WordPress version |
| `--admin-user` | admin | WordPress admin username |
| `--admin-pass` | admin | WordPress admin password |
| `--admin-email` | admin@example.com | WordPress admin email |
| `--tools` | — | Comma-separated: `adminer,xdebug,query-monitor,error-pages,cache-admin` |
| `--no-tui` | false | Disable interactive TUI |

### Site management

```bash
wpx list                             # list all sites with status
wpx info <site>                      # show site details (ports, paths, versions)
wpx open <site>                      # open site in browser
wpx open <site> admin                # open wp-admin
wpx open <site> mail                 # open Mailpit UI
wpx open <site> db                   # open Adminer
wpx logs <site>                      # tail aggregated logs
wpx logs <site> -f                   # follow log output
wpx shell <site>                     # subshell with site env (php, wp, mysql in PATH)
wpx shell <site> --rc                # also source ~/.zshrc or ~/.bashrc
wpx env <site>                       # print shell exports (use with: eval $(wpx env mysite))
wpx apply <site>                     # regenerate all configs from .wpx.json and reload
```

### WordPress & database

```bash
wpx wp <site> <command>              # run WP-CLI commands
wpx db export <site>                 # export database to SQL file
wpx db export <site> output.sql      # export to specific file
wpx db import <site> dump.sql        # import database
wpx db import <site> dump.sql.gz     # import gzip-compressed dump
wpx db import <site> dump.sql --quick   # fast import (disable checks, 3-5x speed)
wpx db import <site> dump.sql --turbo   # fastest (strip indexes, import, rebuild)
wpx search-replace <site> <old> <new>   # search-replace across all tables
wpx search-replace <site> <old> <new> --dry-run     # count matches without modifying
wpx search-replace <site> <old> <new> --prefix=wp_2_ # filter by table prefix
wpx search-replace <site> <old> <new> --workers=16   # parallel workers (default 8)
wpx pull <site>                      # detect domains, propose search-replace, wire nginx/hosts/SSL
wpx pull <site> --quick              # Go-native parallel search-replace (faster)
```

### Domain & multisite

```bash
wpx domain add <site> <domain>                 # add a domain
wpx domain add <site> <domain> --wildcard      # wildcard proxy + SSL (*.domain)
wpx domain add <site> <domain> --title="Blog"  # set subsite title
wpx domain add <site> <domain> --skip-create   # infrastructure only (skip WP subsite)
wpx domain remove <site> <domain>              # remove a domain
wpx domain list <site>                         # list domains
```

### Object cache

```bash
wpx cache flush <site>               # flush object cache (Redis or Memcached)
```

### Xdebug

```bash
wpx xdebug on <site>                # enable Xdebug
wpx xdebug off <site>               # disable Xdebug
wpx xdebug status <site>            # check status
```

### Proxy

```bash
wpx proxy start                     # start global reverse proxy (port 80/443)
wpx proxy stop                      # stop proxy
wpx proxy status                    # check proxy status
wpx proxy reload                    # reload proxy config
wpx proxy clean                     # remove orphan configs for destroyed sites
```

### System

```bash
wpx doctor                          # preflight checks (platform, ports, SSL, deps)
wpx doctor --fix                    # auto-fix repairable issues
wpx orphans                         # detect orphan processes and stale resources
wpx orphans --fix                   # auto-clean orphans
wpx version                         # print version
wpx init                            # initialize ~/.wpx/ and local CA
wpx upgrade-config <site>           # backfill new defaults into existing site config
wpx upgrade-config --all            # upgrade all sites
wpx completion zsh                  # generate zsh completions
wpx completion bash                 # generate bash completions
```

## Stack

Each site runs its own isolated set of native processes:

| Service | Options | Default |
|---|---|---|
| Web server | nginx | nginx (latest) |
| PHP | 8.0 – 8.5 | latest |
| Database | MySQL, MariaDB, SQLite | MySQL (latest) |
| Cache | Redis, Memcached, none | Redis |
| Search | Elasticsearch (Docker) | disabled |
| Mail | Mailpit | enabled |

### Tools (auto-installed per site)

| Tool | Description |
|---|---|
| Adminer | Database management UI |
| Xdebug | Step debugger (toggle on/off) |
| Query Monitor | WordPress performance profiler |
| Pretty error pages | Custom nginx error pages |

## Architecture

```
wpx create mysite
     │
     ├── ~/WPX Sites/mysite.test/
     │    ├── wp/              # WordPress install
     │    ├── conf/            # nginx, php-fpm, mysql configs
     │    ├── data/            # mysql datadir, redis dump
     │    ├── logs/            # per-service logs
     │    ├── run/             # PID files
     │    ├── sock/            # unix sockets (php-fpm, mysql)
     │    └── .wpx.json        # site config
     │
     └── processes (native, per-user)
          ├── nginx            → listens on allocated port
          ├── php-fpm          → unix socket, daemonize=no
          ├── mysqld/mariadbd  → unix socket + port
          ├── redis/memcached  → port (if enabled)
          └── mailpit          → SMTP + web UI ports
```

- **No Docker** (except optional Elasticsearch)
- **No root daemons** — everything runs as your user
- **No shared state** — each site is fully isolated
- **Automatic port allocation** — no collisions between sites
- **Dependency-aware startup** — topological sort ensures correct order

## VIP Go

```bash
wpx create enterprise --vip              # memcached + VIP mu-plugins
wpx create enterprise --vip --search     # + Elasticsearch (Docker)
```

The `--vip` flag enables memcached object cache and installs VIP Go mu-plugins. Elasticsearch is opt-in via `--search`.

## License

Proprietary. All rights reserved.