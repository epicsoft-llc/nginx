# Changelog

All notable changes to this image.

This image has no version number of its own. Its tags are the nginx lines of the official
[nginx](https://hub.docker.com/_/nginx) image it is built on - `stable-alpine` is the stable line - and every one of
them is rebuilt weekly, so it holds a newer nginx release over time. Which one a particular image holds is written
into it:

```
docker image inspect --format '{{index .Config.Labels "image.nginx.version"}}' epicsoft/nginx:stable-alpine
```

Entries here are dated, because there is no number to give them. Each date is also a git tag with a release on GitHub.
New nginx releases from the weekly build are summed up once a quarter, a fix rated high or critical right away.

---

## 2026-10-19

Rebuilt on top of the official image: a change is checked before it is loaded, the reload reports whether it worked,
and a failed reload turns the container unhealthy. **Setups that use the `OBSERVE_*` or `NGINX_CUSTOM_*` variables
need changes** - see *Breaking* at the end.

### Added

- **A reload that answers whether it worked**, through the control API of nginx 1.31.5 and newer: nginx reports the
  result and, when the new configuration does not load, its own messages. `stable-alpine` with nginx 1.30 checks with
  `nginx -t` and reloads by signal until the next stable line brings the control API.
- **`nginx-reload`** for scripts and deployments: checks, reloads, prints what nginx reports and exits with `0` only
  when the reload worked. Optional webhooks after a successful or a failed reload.
- **A healthcheck that knows about reloads**: unhealthy when the master, its workers or the control API do not answer,
  or when the last reload failed - nginx keeps serving the previous configuration in that case, and before nothing
  showed it.
- `linux/arm64` next to `linux/amd64`, and the nginx version in the label `image.nginx.version`.
- Every image goes through `test/smoke.sh` before it is pushed, on every platform: start, automatic reload, refused
  broken configuration, unhealthy and healthy again, reload by hand.
- A mirror on GitHub, `github.com/epicsoft-llc/nginx`, with a release for every entry of this changelog. The
  repository moved from `gitlab.com/epicdocker/nginx` to `gitlab.com/epicsoft-networks/nginx`.

### Changed

- The watcher covers all of `/etc/nginx` instead of `/etc/nginx/conf.d/*.conf`: inotify reports a change right away,
  a checksum compare every five seconds catches changes that send no events, such as bind mounts from Docker Desktop.
- The image starts through the official entrypoint, so templates, `NGINX_ENVSUBST_*` and the other scripts in
  `/docker-entrypoint.d/` work as in the official image.
- The packages of the base image are upgraded as well (`apk upgrade`), so their security fixes do not wait for the
  next official image.
- The pipeline takes its tokens over stdin and through the environment instead of the command line.

### Removed

- The environment variables that edited `nginx.conf` (`NGINX_CUSTOM_*`), the observer settings (`OBSERVE_*`) and
  `EPICSOFT_LOG_LEVEL_DEBUG`.
- bash: the scripts are POSIX `sh` now.

### Breaking

| Setting | Now | Was |
|---|---|---|
| watched files | `NGINX_WATCH`, default `/etc/nginx` | `OBSERVE_FILES`, default `/etc/nginx/conf.d/*.conf` |
| check interval | `NGINX_WATCH_INTERVAL`, default `5` | `OBSERVE_INTERVAL`, default `10` |
| automatic reload off | `NGINX_WATCH=` | `OBSERVE_FILES_ENABLE=false` |
| reload command | `nginx-reload`, fixed | `OBSERVE_COMMAND` |
| `server_tokens`, `proxy_headers_hash_bucket_size`, log format | your own file in `conf.d` | `NGINX_CUSTOM_*` |
| include outside `http`, no `default.conf` | your own `nginx.conf` or `conf.d` | `NGINX_CUSTOM_ADD_DIRECT_INCLUDE`, `NGINX_CUSTOM_DELETE_DEFAULT_CONF` |
| shell in the image | `sh` | `bash` |

---

Earlier changes are in the git history of this repository.
