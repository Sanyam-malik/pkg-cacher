# pkg-cacher

A lightweight mirror-style reverse proxy cache for Linux package managers, Gradle distributions, GitHub releases, and any HTTP artifact source.

Built on NGINX with disk-based caching.

---

# 🚀 What It Does

`pkg-cacher` acts as a mirror-style caching proxy:

```
Client → pkg-cacher → Upstream (first time)
Client → pkg-cacher (cache HIT afterwards)
```

It supports:

- ✅ APT (Ubuntu / Debian)
- ✅ DNF (RHEL 8+, Fedora)
- ✅ YUM (RHEL 7 / CentOS 7)
- ✅ APK (Alpine)
- ✅ Gradle distributions
- ✅ GitHub releases
- ✅ Any HTTP/HTTPS static artifacts
- ✅ CI environments

---

# 🏗 How Mirror Mode Works

All requests must follow this format:

```
https://pkg-cache.example.com/<upstream-host>/<real-path>
```

Example:

```
https://pkg-cache.example.com/archive.ubuntu.com/ubuntu/dists/noble/InRelease
https://pkg-cache.example.com/github.com/gradle/gradle-distributions/releases/download/v9.5.0/gradle-9.5.0-bin.zip
```

The proxy:

1. Extracts `<upstream-host>` from the path
2. Forwards request to that host
3. Caches response on disk
4. Serves future requests from cache

---

# 💾 Disk-Based Cache

- Uses `/var/cache/nginx`
- Configurable TTL (`CACHE_TTL`)
- Cache locking enabled
- Background refresh enabled
- Can serve stale if upstream fails

This is **not in-memory cache**.

---

# ⚙ Environment Variables

| Variable | Description | Example |
|-----------|-------------|----------|
| `CACHE_TTL` | Cache expiration | `24h` |

Example:

```yaml
environment:
  CACHE_TTL: 24h
```

---

# 🐳 Docker Compose Example

```yaml
version: "3.8"

services:
  pkg-cacher:
    image: pkg-cacher:latest
    container_name: pkg-cacher
    ports:
      - "80:80"
    environment:
      CACHE_TTL: 24h
    volumes:
      - ./cache:/var/cache/nginx
    restart: unless-stopped
```

---

# 📦 APT (Ubuntu / Debian)

## Ubuntu 24+ (.sources format)

Edit:

```
/etc/apt/sources.list.d/ubuntu.sources
```

Change:

```
URIs: http://archive.ubuntu.com/ubuntu
```

To:

```
URIs: https://pkg-cache.example.com/archive.ubuntu.com/ubuntu
```

Also update:

```
security.ubuntu.com
```

Then:

```
sudo apt update
```

---

## Older Ubuntu / Debian (.list format)

Edit:

```
/etc/apt/sources.list
```

Change:

```
deb http://archive.ubuntu.com/ubuntu noble main
```

To:

```
deb https://pkg-cache.example.com/archive.ubuntu.com/ubuntu noble main
```

---

## CI Safe Rewrite

```bash
sudo sed -i -E \
"s|https?://([^/ ]+)|https://pkg-cache.example.com/\1|g" \
/etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null || true

sudo sed -i -E \
"s|URIs: https?://([^/ ]+)|URIs: https://pkg-cache.example.com/\1|g" \
/etc/apt/sources.list.d/*.sources 2>/dev/null || true
```

---

# 📦 DNF (RHEL 8+, Fedora, Rocky, Alma)

Edit files in:

```
/etc/yum.repos.d/*.repo
```

Change:

```
baseurl=https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/
```

To:

```
baseurl=https://pkg-cache.example.com/mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/
```

Then:

```
sudo dnf makecache
```

---

# 📦 YUM (RHEL 7 / CentOS 7)

Same configuration as DNF.

Rewrite:

```
baseurl=https://mirror.centos.org/centos/7/os/x86_64/
```

To:

```
baseurl=https://pkg-cache.example.com/mirror.centos.org/centos/7/os/x86_64/
```

Then:

```
sudo yum makecache
```

---

# 📦 APK (Alpine Linux)

Edit:

```
/etc/apk/repositories
```

Change:

```
https://dl-cdn.alpinelinux.org/alpine/v3.20/main
```

To:

```
https://pkg-cache.example.com/dl-cdn.alpinelinux.org/alpine/v3.20/main
```

Then:

```
sudo apk update
```

---

# 📦 Docker Repo Example

Before:

```
https://download.docker.com/linux/ubuntu
```

After:

```
https://pkg-cache.example.com/download.docker.com/linux/ubuntu
```

---

# 📦 NodeSource Example

Before:

```
https://deb.nodesource.com/node_20.x
```

After:

```
https://pkg-cache.example.com/deb.nodesource.com/node_20.x
```

---

# 🔎 Verifying Cache

Check response header:

```
X-Cache-Status: HIT | MISS | STALE
```

Or view logs:

```
Cache:HIT
Cache:MISS
```

Run installs twice — second run should HIT.

---

# ⚡ Performance Notes

Cache MISS includes:

- DNS resolution
- TLS handshake
- Disk write

Cache HIT is significantly faster.

Best results with:

- SSD/NVMe storage
- IPv6 disabled if unused:
  
  ```
  resolver 8.8.8.8 ipv6=off valid=300s;
  ```

- Ignoring upstream cache headers for GitHub releases:
  
  ```
  proxy_ignore_headers Cache-Control Expires;
  proxy_cache_valid any ${CACHE_TTL};
  ```

---

# 🎯 Use Cases

- Self-hosted CI runners
- Bandwidth reduction
- Artifact mirroring
- Faster builds
- Controlled external dependency access

---

# 📄 License

MIT