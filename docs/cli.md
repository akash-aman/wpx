# wpx CLI command reference

Every subcommand, every flag. Adapted from the original pre-monorepo
public README — kept as a single document so the `man`-style
"everything in one place" lookup still works.

For installation, see the [top-level README](../README.md).
For internals (stack, on-disk layout, process model) see
[architecture.md](architecture.md).

---

## Site lifecycle

```bash
wpx create <site>                     # create a new WordPress site
wpx create <site> --no-tui            # plain-text output (no interactive TUI)

wpx start   <site>                    # start all services for the site
wpx start   <site> <service>          # start a single service (nginx, php-fpm, mysql, …)
wpx start   --all                     # start every registered site

wpx stop    <site>                    # stop all services
wpx stop    <site> <service>          # stop a single service
wpx stop    --all                     # stop every site

wpx restart <site>                    # restart all services
wpx restart <site> <service>          # restart a single service
wpx restart --all                     # restart every site

wpx reload  <site>                    # graceful reload (SIGHUP/SIGUSR2)
wpx reload  <site> <service>          # reload a single service
wpx reload  --all                     # reload every site

wpx destroy <site> --force            # stop + delete site files
wpx destroy --all --force             # destroy every site
```

### `create` flags

| Flag | Default | Description |
|---|---|---|
| `--php` | latest | PHP version (e.g. `8.3`, `8.5`) |
| `--db` | `mysql` | Database engine: `mysql`, `mariadb`, `sqlite` |
| `--db-version` | latest | Database version (e.g. `8.4`, `11.4.4`, `10.6`) |
| `--cache` | `redis` | Cache backend: `redis`, `memcached`, `none` |
| `--cache-version` | latest | Cache version (e.g. `8.6.2`, `1.6.41`) |
| `--nginx-version` | latest | Nginx version |
| `--wp-version` | latest | WordPress version |
| `--domain` | `<name>.wpx` | Custom site domain |
| `--multisite` | false | Enable WordPress multisite (subdirectory) |
| `--multisite-subdomains` | false | Use subdomain multisite instead |
| `--vip` | false | VIP Go layout + mu-plugins (forces memcached) |
| `--search` | false | Enable Elasticsearch (Docker) |
| `--ssl` | true | HTTPS via mkcert |
| `--mail` | true | Enable Mailpit (SMTP + web UI) |
| `--repo` | — | Git repo URL to clone as `wp-content/` |
| `--admin-user` | `admin` | WordPress admin username |
| `--admin-pass` | `admin` | WordPress admin password |
| `--admin-email` | `admin@example.com` | WordPress admin email |
| `--tools` | — | Comma-separated tools to enable: `adminer,xdebug,query-monitor,error-pages,cache-admin` |
| `--no-tui` | false | Disable interactive TUI (plain text output) |

### `create` examples

```bash
wpx create mysite                            # WordPress (~12s)
wpx create mysite --php=8.3                  # specific PHP
wpx create mysite --db=mariadb               # MariaDB instead of MySQL
wpx create mysite --cache=redis              # Redis cache (default)
wpx create mysite --cache=memcached          # Memcached cache
wpx create mysite --cache=none               # no object cache
wpx create mysite --db=sqlite                # SQLite (no DB server)
wpx create mysite --multisite                # multisite (subdirectory)
wpx create mysite --multisite --multisite-subdomains
wpx create mysite --domain=mysite.dev        # custom domain
wpx create mysite --repo=git@...             # clone repo as wp-content/
wpx create vipsite --vip                     # VIP Go stack (memcached)
wpx create vipsite --vip --search            # VIP Go + Elasticsearch
```

## Site management

```bash
wpx list                              # list all sites with status
wpx info <site>                       # show site details (ports, paths, versions)

wpx open <site>                       # open site in browser
wpx open <site> admin                 # open wp-admin
wpx open <site> mail                  # open Mailpit UI
wpx open <site> db                    # open Adminer

wpx logs <site>                       # tail aggregated logs
wpx logs <site> -f                    # follow log output

wpx shell <site>                      # subshell with site env (php, wp, mysql on PATH)
wpx shell <site> --rc                 # also source ~/.zshrc or ~/.bashrc

wpx env <site>                        # print shell exports (use with: eval $(wpx env mysite))
wpx apply <site>                      # regenerate all configs from .wpx.json and reload
```

## WordPress & database

```bash
wpx wp <site> <command>               # run any WP-CLI command

wpx db export <site>                  # export database to SQL file
wpx db export <site> out.sql          # export to specific file
wpx db import <site> dump.sql         # import database
wpx db import <site> dump.sql.gz      # import gzip-compressed dump
wpx db import <site> dump.sql --quick # fast import (disable checks, 3-5x speed)
wpx db import <site> dump.sql --turbo # fastest (strip indexes, import, rebuild)

wpx search-replace <site> <old> <new>                # search-replace across all tables
wpx search-replace <site> <old> <new> --dry-run      # count matches without modifying
wpx search-replace <site> <old> <new> --prefix=wp_2_ # filter by table prefix
wpx search-replace <site> <old> <new> --workers=16   # parallel workers (default 8)

wpx pull <site>                       # detect domains, propose search-replace,
                                      # then wire nginx + /etc/hosts + SSL
wpx pull <site> --quick               # Go-native parallel search-replace (faster)
```

## Domain & multisite

```bash
wpx domain add    <site> <domain>                    # add a domain
wpx domain add    <site> <domain> --wildcard         # wildcard proxy + SSL (*.domain)
wpx domain add    <site> <domain> --title="Blog"     # set subsite title
wpx domain add    <site> <domain> --skip-create      # infra only (no WP subsite)
wpx domain remove <site> <domain>                    # remove a domain
wpx domain list   <site>                             # list domains
```

## Object cache

```bash
wpx cache flush <site>                # flush object cache (Redis or Memcached)
```

## Xdebug

```bash
wpx xdebug on     <site>              # enable Xdebug
wpx xdebug off    <site>              # disable Xdebug
wpx xdebug status <site>              # check status
```

## Reverse proxy

```bash
wpx proxy start                       # start global proxy (port 80 / 443)
wpx proxy stop                        # stop proxy
wpx proxy status                      # check proxy status
wpx proxy reload                      # reload proxy config
wpx proxy clean                       # remove orphan configs for destroyed sites
```

## System

```bash
wpx doctor                            # preflight checks (platform, ports, SSL, deps)
wpx doctor --fix                      # auto-fix repairable issues
wpx orphans                           # detect orphan processes / stale resources
wpx orphans --fix                     # auto-clean orphans

wpx version                           # print version
wpx init                              # initialise ~/.wpx/ and local CA
wpx upgrade-config <site>             # backfill new defaults into existing site config
wpx upgrade-config --all              # upgrade every site

wpx self-update                       # upgrade CLI + desktop app together
wpx self-update --check               # report only, never modifies
wpx self-update --pre                 # include pre-releases

wpx completion zsh                    # generate zsh completions
wpx completion bash                   # generate bash completions
```

## MCP server

```bash
wpx mcp serve                         # start the Model Context Protocol server (stdio)
```

Drop the config snippet generated by the desktop app's `⌘K → MCP`
dialog into your AI client (VS Code, Cursor, Claude Desktop) and
**54 MCP tools** light up automatically. The complete tool list is
in the [top-level README](../README.md#-mcp-tools).
