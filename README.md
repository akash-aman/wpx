<div align="center">

# 🌐 wpx

Native WordPress development environments for macOS — plus a desktop GUI
that drives them and an MCP server that lets your AI assistant operate
them too. Every service — nginx, PHP-FPM, MySQL / MariaDB / SQLite,
Redis / Memcached, Mailpit, and Elasticsearch — runs natively on the
host. No Docker required (a Docker runtime is on the roadmap, not
currently supported).



Made with ❤️ by [Akash Aman](https://linktr.ee/akash_aman)

[![Patreon](https://img.shields.io/badge/Patreon-support-orange)](https://www.patreon.com/akashaman)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-yellow)](https://www.buymeacoffee.com/akashaman)
[![Hire Me](https://img.shields.io/badge/Hire%20Me-email-blue)](mailto:sir.akashaman@gmail.com)


</div>

---

## Overview

`wpx` lets you spin up a fully-configured local WordPress site in
about 12 seconds:

```bash
wpx create mysite                          # → https://mysite.wpx
wpx create vipsite --vip                   # → VIP Go w/ memcached + ES
wpx create shop --domain myshop.dev        # → custom domain
```

Every site gets its own `nginx + php-fpm + database + cache` quartet,
mkcert-issued HTTPS, a reverse proxy on :80/:443, and lifecycle
commands that survive reboots. The desktop app puts the same surface
behind a point-and-click GUI; the MCP server lets you drive all of it
from any AI client that speaks Model Context Protocol.

## ✨ Key Features

| Capability            | Description                                                                        |
|-----------------------|------------------------------------------------------------------------------------|
| Create site           | One command → full WordPress install with HTTPS in ~12 s                            |
| Multi-stack           | PHP versions, MySQL / MariaDB / SQLite, Redis / Memcached, multisite + VIP support |
| HTTPS via mkcert      | Locally-trusted certificates per site, no browser warnings                          |
| Reverse proxy         | One nginx on :80/:443 routes every `*.wpx` hostname to its site                    |
| Pull from production  | 3-step wizard: import dump → confirm domain mappings → search-replace + reproxy    |
| Site lifecycle        | `start` / `stop` / `restart` / `reload` (whole stack or per-service)                |
| Doctor                | Preflight + auto-fix for ports, hosts, mkcert, binaries, disk, proxy               |
| Orphans               | Detect & clean leftover processes / files from previous runs                        |
| Notifications drawer  | Replay every toast surfaced this session (`🔔` in the topbar of the desktop app)    |
| ⌘K Command palette    | Fuzzy navigate + run actions across sites, pages, tabs                              |
| MCP integration       | 54+ tools for VS Code, Cursor, Claude Desktop                                       |
| Self-update           | `wpx self-update` upgrades CLI **and** desktop app in one command                   |

## 🛠️ MCP Tools

<!-- MCP_TOOLS_START -->

Every wpx capability is exposed as an MCP tool — **54 tools across 17 categories**. Drop the JSON snippet from the in-app dialog (`⌘K → mcp`) into your client's config and the tools below light up automatically.

#### Cache

| Tool | Description |
|------|-------------|
| `cache_flush` | Flush the object cache (Redis or Memcached) for a site. |

#### Database

| Tool | Description |
|------|-------------|
| `db_export` | Export a site's database to a SQL file. Returns the output file path. |
| `db_import` | Import a SQL dump into a site's database. Supports .sql and .sql.gz files. |
| `db_query` | Run a SQL query directly against a site's MySQL/MariaDB database. Bypasses wp-cli and VIP restrictions. Returns tab-separated results. |

#### Diagnostics

| Tool | Description |
|------|-------------|
| `doctor` | Run preflight/health checks. |
| `logs_read` | Read recent log entries for a site. |
| `orphans_check` | Detect stale PIDs, orphan processes, port conflicts. |
| `pull` | Import production database and rewire domains. |
| `upgrade_config` | Backfill missing .wpx.json fields and regenerate configs. |

#### Domains

| Tool | Description |
|------|-------------|
| `domain_add` | Map a domain to a multisite. Adds proxy config, /etc/hosts entry, and SSL certificate. |
| `domain_remove` | Remove a domain mapping from a multisite. |
| `domain_list` | List all domains mapped to a multisite. |

#### Meta

| Tool | Description |
|------|-------------|
| `help_discover` | Discover wpx commands, subcommands, and flags by running --help. Use this when you need to find exact flag names or available subcommands. Examples: command='create', command='db import', command='domain'. |

#### Site lifecycle

| Tool | Description |
|------|-------------|
| `site_create` | Create a new WordPress site with the specified stack. Returns site details including URLs and ports. |
| `site_destroy` | Destroy a WordPress site — stops services, removes files, cleans hosts and proxy. |
| `site_start` | Start all or a specific service for a site. |
| `site_stop` | Stop all or a specific service for a site. |
| `site_restart` | Restart all or a specific service for a site. |
| `site_reload` | Graceful reload (SIGHUP/SIGUSR2) for all or a specific service. |
| `site_apply` | Regenerate all config files from .wpx.json and reload services. |

#### Plugins (wp-cli)

| Tool | Description |
|------|-------------|
| `plugin_list` | List all installed plugins for a site with status, version, and update info. |
| `plugin_install` | Install a WordPress plugin from the plugin directory or a URL. |
| `plugin_activate` | Activate an installed WordPress plugin. |
| `plugin_deactivate` | Deactivate an active WordPress plugin. |

#### Plugins (DB-direct)

| Tool | Description |
|------|-------------|
| `plugin_db_list` | List all plugins from filesystem + DB status. Works even when the site has a fatal PHP error. Shows active/network-active/inactive status by reading directly from the database. |
| `plugin_db_toggle` | Enable or disable one or more plugins via direct DB manipulation. Accepts comma-separated plugin paths for batch operations. Single DB read + single DB write. Bypasses wp-cli and PHP. |
| `plugin_db_disable_all` | Emergency: disable ALL plugins via DB. Use when a site is completely broken by a plugin fatal error. |
| `plugin_db_enable_all` | Enable ALL plugins found on disk via DB. Scans wp-content/plugins/ and activates every discovered plugin. |

#### Reverse proxy

| Tool | Description |
|------|-------------|
| `proxy_start` | Start the global reverse proxy (ports 80/443). |
| `proxy_stop` | Stop the global reverse proxy. |
| `proxy_reload` | Reload the global reverse proxy configuration. |
| `proxy_status` | Show proxy status and ports. |
| `proxy_clean` | Remove orphaned proxy configs for destroyed sites. |

#### Pull from production

| Tool | Description |
|------|-------------|
| `pull_detect` | Detect all production domains in a site's database and propose local domain mappings. Returns JSON with proposed from/to pairs for each blog in the multisite. Use before pull_execute to let the user review and adjust mappings. |
| `pull_execute` | Execute domain migration: updates wp_blogs, runs search-replace per mapping, adds proxy entries, reports hosts to add. Pass the mappings JSON from pull_detect (modified if needed). Use quick=true for Go-based parallel search-replace (faster, bypasses WP-CLI). |
| `hosts_add` | Add /etc/hosts entries for a site. Auto-discovers all domains: primary for single sites, primary + subsite domains for subdomain multisites. Skips existing entries. Requires sudo. |

#### Database — search / replace

| Tool | Description |
|------|-------------|
| `search_replace` | Run a search-replace across all WordPress tables. Handles serialized data safely. |

#### Site management

| Tool | Description |
|------|-------------|
| `site_list` | List all wpx-managed WordPress sites with their domains, ports, and status. |
| `site_info` | Show detailed configuration for a site: stack versions, ports, paths, features. Access the site via the domain URL (e.g. https://domain.test/) — do NOT use localhost:<port>. The ports object shows internal backend ports for direct DB/Redis connections only; the wpx proxy routes HTTP/HTTPS on standard ports 80/443. |
| `site_open` | Get the URL for a site or one of its services (does not open a browser). |
| `site_env` | Get environment variables for a site's shell (PHP path, socket paths, etc.). |
| `version` | Print the wpx version. |
| `wpx_init` | Initialize the wpx global directory (~/.wpx/) and local CA for HTTPS. |

#### Themes (wp-cli)

| Tool | Description |
|------|-------------|
| `theme_list` | List all installed themes for a site. |
| `theme_install` | Install a WordPress theme from the theme directory or a URL. |
| `theme_activate` | Activate an installed WordPress theme. |

#### Themes (DB-direct)

| Tool | Description |
|------|-------------|
| `theme_db_list` | List all themes from filesystem + active status from DB. Works even when the site has a fatal PHP error. |
| `theme_db_switch` | Switch the active theme via direct DB update. Bypasses wp-cli and PHP — works even when the site is broken. |

#### WordPress users

| Tool | Description |
|------|-------------|
| `user_create` | Create a WordPress user. |
| `user_list` | List all WordPress users for a site. |

#### WP-CLI passthrough

| Tool | Description |
|------|-------------|
| `wp_run` | Execute any WP-CLI command against a site. Examples: 'plugin list', 'option get siteurl', 'cache flush', 'db query \ |

#### Xdebug

| Tool | Description |
|------|-------------|
| `xdebug_on` | Enable Xdebug for a site. Returns IDE configuration. |
| `xdebug_off` | Disable Xdebug for a site. |
| `xdebug_status` | Check Xdebug status for a site. |

<!-- MCP_TOOLS_END -->

## 📖 Documentation

| Doc | What's in it |
|---|---|
| [docs/cli.md](docs/cli.md) | Full CLI command reference — every subcommand, every flag, real examples |
| [docs/architecture.md](docs/architecture.md) | Stack, on-disk layout, process model, port allocation strategy |

## Install

The umbrella installer drops both the CLI binary and (on macOS) the
desktop app in one go:

```bash
curl -fsSL https://raw.githubusercontent.com/akash-aman/wpx/main/install.sh | bash
```

Flags:

| Flag                  | Effect                                       |
|-----------------------|----------------------------------------------|
| `--version vX.Y.Z`    | Pin a specific release                       |
| `--cli-only`          | Install only the CLI binary                  |
| `--app-only`          | Install only the desktop app (macOS only)    |

After install:

```bash
wpx --help                # full CLI surface
wpx self-update --check   # is a newer release available?
wpx self-update           # upgrade both CLI + app
open -a wpx               # launch the desktop app
```

> [!NOTE]
> wpx currently targets **macOS only** (Apple Silicon + Intel).
> Linux and Windows support is on the roadmap.

## 🤝 Contributing

This repository is the **public release distribution**. Source code,
issues, and pull requests live in the private codebase repo — please
reach out at <sir.akashaman@gmail.com> if you'd like access.

## 🔒 Security

By participating you agree to abide by the
[Code of Conduct](CODE_OF_CONDUCT.md). Found a security issue?
Please follow the responsible-disclosure process in
[SECURITY.md](SECURITY.md) — do **not** open a public issue.

## 📝 License

This project is **proprietary** — see [LICENSE](LICENSE) for the full
terms. The published binaries are licensed for personal, internal use
only; redistribution, modification, and re-publishing of the source
are not permitted. For commercial licensing or source-code access
contact <sir.akashaman@gmail.com>.


<div align="center">

[![Patreon](https://img.shields.io/badge/Patreon-support-orange)](https://www.patreon.com/akashaman)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-yellow)](https://www.buymeacoffee.com/akashaman)
[![Hire Me](https://img.shields.io/badge/Hire%20Me-email-blue)](mailto:sir.akashaman@gmail.com)

### Made with ❤️ by [Akash Aman](https://linktr.ee/akash_aman)

</div>