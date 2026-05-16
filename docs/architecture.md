# wpx architecture

How wpx organises sites on disk, how it runs services without Docker
or root daemons, and how the reverse proxy keeps everything reachable
on standard ports.

For everyday usage, see the [CLI reference](cli.md). For the install
flow, see the [top-level README](../README.md#install).

---

## Stack

Each site runs its own isolated set of native processes:

| Service     | Options                          | Default          |
|-------------|----------------------------------|------------------|
| Web server  | nginx                            | nginx (latest)   |
| PHP         | 8.0 – 8.5                        | latest           |
| Database    | MySQL · MariaDB · SQLite         | MySQL (latest)   |
| Cache       | Redis · Memcached · none         | Redis            |
| Search      | Elasticsearch (Docker)           | disabled         |
| Mail        | Mailpit                          | enabled          |

### Tools (auto-installed per site)

| Tool                | Description                                         |
|---------------------|-----------------------------------------------------|
| Adminer             | Database management UI                              |
| Xdebug              | Step debugger (toggle on / off without rebuilds)    |
| Query Monitor       | WordPress performance profiler                      |
| Pretty error pages  | Custom nginx error pages                            |
| Cache admin         | Live cache stats + flush UI                         |

## On-disk layout

```text
wpx create mysite
  │
  ├── ~/WPX Sites/mysite.wpx/
  │    ├── wp/              # WordPress install
  │    ├── conf/            # nginx, php-fpm, mysql configs
  │    ├── data/            # mysql datadir, redis dump
  │    ├── logs/            # per-service logs
  │    ├── run/             # PID files
  │    ├── sock/            # unix sockets (php-fpm, mysql)
  │    └── .wpx.json        # site config (source of truth)
  │
  └── processes (native, per-user)
       ├── nginx            → listens on allocated port
       ├── php-fpm          → unix socket, daemonize=no
       ├── mysqld/mariadbd  → unix socket + port
       ├── redis/memcached  → port (if enabled)
       └── mailpit          → SMTP + web UI ports
```

## Design properties

- **No Docker** for the core stack (only Elasticsearch is opt-in
  Dockerised, and only when you pass `--search`).
- **No root daemons** — every service runs as your unprivileged user.
  The only privileged operations are `/etc/hosts` mutations and
  binding to ports 80/443; both go through a single authenticated
  elevation per action.
- **No shared state** — each site is fully isolated under
  `~/WPX Sites/<site>.wpx/`. Removing a site is `wpx destroy <site>`
  followed by `rm -rf ~/WPX\ Sites/<site>.wpx/`.
- **Automatic port allocation** — wpx picks free ports inside a
  configured range per service kind so multiple sites never collide.
- **Dependency-aware startup** — a topological sort ensures, e.g.,
  `mysql` is up before `php-fpm` queries it.

## Reverse proxy

A single global nginx (`wpx proxy start`) listens on `:80` and
`:443` and routes by hostname:

```
*.wpx           → per-site nginx (HTTP)
*.wpx (HTTPS)   → per-site nginx with mkcert cert
```

Per-site nginx instances bind to the allocated dev port (e.g.
`:8081`) and the global proxy forwards. The proxy config is
auto-regenerated on every `wpx create / domain add / apply` and
`wpx proxy reload` SIGHUP-reloads without dropping connections.

This is what makes `https://mysite.wpx` work out of the box without
hard-coded port numbers in the URL.

## VIP Go support

```bash
wpx create enterprise --vip            # memcached + VIP mu-plugins
wpx create enterprise --vip --search   # + Elasticsearch (Docker)
```

The `--vip` flag enables the memcached object cache, copies the VIP
Go layout (mu-plugins, vip-config, sunrise.php), and installs Query
Monitor with a force-enable filter. Elasticsearch is opt-in via
`--search`.

## State directory

```text
~/.wpx/
  ├── config.json           # global defaults
  ├── registry.json         # list of registered sites
  ├── bin/                  # downloaded binaries (php, nginx, mysql, …)
  ├── cache/                # binary catalog cache + PHP extension build cache
  ├── certs/                # mkcert CA + per-site certs
  ├── locks/                # cross-process locks
  ├── logs/                 # global wpx logs
  └── proxy/
      ├── conf.d/           # per-site nginx vhosts
      ├── logs/             # proxy access + error
      └── temp/             # proxy temp dirs
```

Everything wpx writes lives under either `~/WPX Sites/` (per-site)
or `~/.wpx/` (global). Removing both directories returns the host
to a clean state.

## Process model in one line

> wpx provisions, configures, and supervises a bag of native
> POSIX processes per WordPress site, with a single nginx out
> front for routing — no containers, no VMs, no daemons running
> as root.
