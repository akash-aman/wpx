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

Every wpx capability is exposed as an MCP tool — **55 tools across 18 categories**. Drop the JSON snippet from the in-app dialog (`⌘K → mcp`) into your client's config and the tools below light up automatically.

#### Cache

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>cache_flush</code></td><td>Flush the object cache (Redis or Memcached) for a site.</td></tr>
</tbody>
</table>

#### Database

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>db_export</code></td><td>Export a site's database to a SQL file. Returns the output file path.</td></tr>
<tr><td><code>db_import</code></td><td>Import a SQL dump into a site's database. Supports .sql and .sql.gz files.</td></tr>
<tr><td><code>db_query</code></td><td>Run a SQL query directly against a site's MySQL/MariaDB database. Bypasses wp-cli and VIP restrictions. Returns tab-separated results.</td></tr>
</tbody>
</table>

#### Diagnostics

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>doctor</code></td><td>Run preflight/health checks.</td></tr>
<tr><td><code>logs_read</code></td><td>Read recent log entries for a site.</td></tr>
<tr><td><code>orphans_check</code></td><td>Detect stale PIDs, orphan processes, port conflicts.</td></tr>
<tr><td><code>pull</code></td><td>Import production database and rewire domains.</td></tr>
<tr><td><code>upgrade_config</code></td><td>Backfill missing .wpx.json fields and regenerate configs.</td></tr>
</tbody>
</table>

#### Domains

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>domain_add</code></td><td>Map a domain to a multisite. Adds proxy config, /etc/hosts entry, and SSL certificate.</td></tr>
<tr><td><code>domain_remove</code></td><td>Remove a domain mapping from a multisite.</td></tr>
<tr><td><code>domain_list</code></td><td>List all domains mapped to a multisite.</td></tr>
</tbody>
</table>

#### Meta

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>help_discover</code></td><td>Discover wpx commands, subcommands, and flags by running --help. Use this when you need to find exact flag names or available subcommands. Examples: command='create', command='db import', command='domain'.</td></tr>
</tbody>
</table>

#### Site lifecycle

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>site_create</code></td><td>Create a new WordPress site with the specified stack. Returns site details including URLs and ports.</td></tr>
<tr><td><code>site_destroy</code></td><td>Destroy a WordPress site — stops services, removes files, cleans hosts and proxy.</td></tr>
<tr><td><code>site_start</code></td><td>Start a site. By default starts every service; pass `service` to start just one (nginx, php-fpm, mysql, mariadb, redis, memcached, mailpit, elasticsearch, …). Use services_list to discover which services exist on the site.</td></tr>
<tr><td><code>site_stop</code></td><td>Stop a site. By default stops every service; pass `service` to stop just one.</td></tr>
<tr><td><code>site_restart</code></td><td>Restart a site. By default restarts every service; pass `service` to restart just one.</td></tr>
<tr><td><code>site_reload</code></td><td>Graceful reload (SIGHUP/SIGUSR2) of a site. By default reloads every service that supports it; pass `service` to reload just one.</td></tr>
<tr><td><code>site_apply</code></td><td>Regenerate all config files from .wpx.json and reload services.</td></tr>
</tbody>
</table>

#### Plugins (wp-cli)

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>plugin_list</code></td><td>List all installed plugins for a site with status, version, and update info.</td></tr>
<tr><td><code>plugin_install</code></td><td>Install a WordPress plugin from the plugin directory or a URL.</td></tr>
<tr><td><code>plugin_activate</code></td><td>Activate an installed WordPress plugin.</td></tr>
<tr><td><code>plugin_deactivate</code></td><td>Deactivate an active WordPress plugin.</td></tr>
</tbody>
</table>

#### Plugins (DB-direct)

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>plugin_db_list</code></td><td>List all plugins from filesystem + DB status. Works even when the site has a fatal PHP error. Shows active/network-active/inactive status by reading directly from the database.</td></tr>
<tr><td><code>plugin_db_toggle</code></td><td>Enable or disable one or more plugins via direct DB manipulation. Accepts comma-separated plugin paths for batch operations. Single DB read + single DB write. Bypasses wp-cli and PHP.</td></tr>
<tr><td><code>plugin_db_disable_all</code></td><td>Emergency: disable ALL plugins via DB. Use when a site is completely broken by a plugin fatal error.</td></tr>
<tr><td><code>plugin_db_enable_all</code></td><td>Enable ALL plugins found on disk via DB. Scans wp-content/plugins/ and activates every discovered plugin.</td></tr>
</tbody>
</table>

#### Reverse proxy

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>proxy_start</code></td><td>Start the global reverse proxy (ports 80/443).</td></tr>
<tr><td><code>proxy_stop</code></td><td>Stop the global reverse proxy.</td></tr>
<tr><td><code>proxy_reload</code></td><td>Reload the global reverse proxy configuration.</td></tr>
<tr><td><code>proxy_status</code></td><td>Show proxy status and ports.</td></tr>
<tr><td><code>proxy_clean</code></td><td>Remove orphaned proxy configs for destroyed sites.</td></tr>
</tbody>
</table>

#### Pull from production

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>pull_detect</code></td><td>Detect all production domains in a site's database and propose local domain mappings. Returns JSON with proposed from/to pairs for each blog in the multisite. Use before pull_execute to let the user review and adjust mappings.</td></tr>
<tr><td><code>pull_execute</code></td><td>Execute domain migration: updates wp_blogs, runs search-replace per mapping, adds proxy entries, reports hosts to add. Pass the mappings JSON from pull_detect (modified if needed). Use quick=true for Go-based parallel search-replace (faster, bypasses WP-CLI).</td></tr>
<tr><td><code>hosts_add</code></td><td>Add /etc/hosts entries for a site. Auto-discovers all domains: primary for single sites, primary + subsite domains for subdomain multisites. Skips existing entries. Requires sudo.</td></tr>
</tbody>
</table>

#### Database — search / replace

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>search_replace</code></td><td>Run a search-replace across all WordPress tables. Handles serialized data safely.</td></tr>
</tbody>
</table>

#### Services (status)

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>services_list</code></td><td>List every service for a site (nginx, php-fpm, mysql/mariadb, redis/memcached, mailpit, elasticsearch, …) with PID, port, version, uptime, memory, CPU, and config/log paths. Use this to see which services exist on a site before you target one with site_start / site_stop / site_restart / site_reload.</td></tr>
</tbody>
</table>

#### Site management

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>site_list</code></td><td>List all wpx-managed WordPress sites with their domains, ports, and status.</td></tr>
<tr><td><code>site_info</code></td><td>Show detailed configuration for a site: stack versions, ports, paths, features. Access the site via the domain URL (e.g. https://domain.test/) — do NOT use localhost:&lt;port&gt;. The ports object shows internal backend ports for direct DB/Redis connections only; the wpx proxy routes HTTP/HTTPS on standard ports 80/443.</td></tr>
<tr><td><code>site_open</code></td><td>Get the URL for a site or one of its services (does not open a browser).</td></tr>
<tr><td><code>site_env</code></td><td>Get environment variables for a site's shell (PHP path, socket paths, etc.).</td></tr>
<tr><td><code>version</code></td><td>Print the wpx version.</td></tr>
<tr><td><code>wpx_init</code></td><td>Initialize the wpx global directory (~/.wpx/) and local CA for HTTPS.</td></tr>
</tbody>
</table>

#### Themes (wp-cli)

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>theme_list</code></td><td>List all installed themes for a site.</td></tr>
<tr><td><code>theme_install</code></td><td>Install a WordPress theme from the theme directory or a URL.</td></tr>
<tr><td><code>theme_activate</code></td><td>Activate an installed WordPress theme.</td></tr>
</tbody>
</table>

#### Themes (DB-direct)

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>theme_db_list</code></td><td>List all themes from filesystem + active status from DB. Works even when the site has a fatal PHP error.</td></tr>
<tr><td><code>theme_db_switch</code></td><td>Switch the active theme via direct DB update. Bypasses wp-cli and PHP — works even when the site is broken.</td></tr>
</tbody>
</table>

#### WordPress users

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>user_create</code></td><td>Create a WordPress user.</td></tr>
<tr><td><code>user_list</code></td><td>List all WordPress users for a site.</td></tr>
</tbody>
</table>

#### WP-CLI passthrough

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>wp_run</code></td><td>Execute any WP-CLI command against a site. Examples: 'plugin list', 'option get siteurl', 'cache flush', 'db query \</td></tr>
</tbody>
</table>

#### Xdebug

<table>
<thead><tr><th align="left">Tool</th><th align="left">Description<img src="https://raw.githubusercontent.com/akash-aman/wpx/main/assets/spacer.png" width="800" height="1" alt=""></th></tr></thead>
<tbody>
<tr><td><code>xdebug_on</code></td><td>Enable Xdebug for a site. Returns IDE configuration.</td></tr>
<tr><td><code>xdebug_off</code></td><td>Disable Xdebug for a site.</td></tr>
<tr><td><code>xdebug_status</code></td><td>Check Xdebug status for a site.</td></tr>
</tbody>
</table>

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
> wpx currently targets **macOS on Apple Silicon (arm64) only**.
> Intel Macs, Linux, and Windows are on the roadmap.

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