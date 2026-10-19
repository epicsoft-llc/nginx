# nginx

This Docker image is managed and kept up to date by [epicsoft LLC](https://epicsoft.one).

The official [nginx image](https://hub.docker.com/_/nginx) with what it leaves to you: the configuration is reloaded
**automatically and gracefully** when it changes, `nginx-reload` tells you whether a reload worked, and the
**healthcheck turns unhealthy when a reload failed** - instead of nginx silently serving the old configuration.

* Base image: https://hub.docker.com/_/nginx (`alpine` variants), platforms `linux/amd64` and `linux/arm64`
* Dockerfile: https://gitlab.com/epicsoft-networks/nginx/-/blob/master/Dockerfile
* Repository: https://gitlab.com/epicsoft-networks/nginx, mirrored to [GitHub](https://github.com/epicsoft-llc/nginx) — issues are welcome on both; code changes only as merge requests on GitLab, the mirror overwrites anything pushed to GitHub
* Container registry: https://gitlab.com/epicsoft-networks/nginx/container_registry
* Docker Hub: https://hub.docker.com/r/epicsoft/nginx
* Changelog: https://gitlab.com/epicsoft-networks/nginx/-/blob/master/CHANGELOG.md
* License: MIT

## What this image adds

| | official image | this image |
|---|---|---|
| Configuration changed | nothing happens until you run `nginx -s reload` or send a `SIGHUP` | checked with `nginx -t` and reloaded automatically - gracefully, the old workers finish their connections |
| Broken configuration | the reload fails, nginx keeps the old configuration and nothing outside shows it | the reload is refused with nginx's own error messages, and the container turns **unhealthy** |
| Reload from a script | `nginx -s reload` - no answer whether it worked | `docker exec <container> nginx-reload` - nginx's messages and an exit code |
| Healthcheck | none | master and workers run, the control API answers, no failed reload |

Everything else is the official image as it is: nginx and its modules - the ACME module included -, templates with
environment variables, the scripts in `/docker-entrypoint.d/`, logging to the container log.

## Versions

The tags follow the nginx lines of the official image and are rebuilt weekly, so each one keeps getting the newest
nginx release of its line.

| Tag | Built on |
|---|---|
| `latest`, `alpine` | `nginx:alpine` - mainline, the line with the newest features and fixes |
| `stable-alpine` | `nginx:stable-alpine` - stable |

The nginx version an image really holds is written into it:

```bash
docker image inspect --format '{{index .Config.Labels "image.nginx.version"}}' epicsoft/nginx:stable-alpine
```

**The answer whether a reload worked needs nginx 1.31.5 or newer**, which brought the control API: mainline has it,
`stable-alpine` with nginx 1.30 gets it with the next stable line. Until then `stable-alpine` checks the configuration
with `nginx -t` and reloads by signal - a configuration that passes the test but still fails to load, on a port that
is in use for example, goes unnoticed there.

## Quick start

Mount the **directory** with the configuration, not a single file: editors and deployment tools usually replace a
file instead of rewriting it, and a single-file mount keeps pointing at the old one.

```bash
docker run -d --name nginx \
  -p 80:80 \
  -v /srv/nginx/conf.d:/etc/nginx/conf.d:ro \
  epicsoft/nginx:latest
```

`/srv/nginx/conf.d/default.conf`, for example:

```
server {
  listen 80;
  server_name example.com;

  location / {
    proxy_pass http://app:8080;
  }
}
```

A Compose example: [example/compose.yml](https://gitlab.com/epicsoft-networks/nginx/-/blob/master/example/compose.yml).

## Reloading

**Automatically:** every change below `/etc/nginx` - the default of `NGINX_WATCH` - is checked with `nginx -t` and
then reloaded. inotify reports a change right away; where no events arrive, for example with a bind mount from
Docker Desktop, a checksum compare every `NGINX_WATCH_INTERVAL` seconds catches it. Certificates kept outside
`/etc/nginx` can be added to `NGINX_WATCH`, so a renewed certificate is loaded without a restart.

```
[nginx-watch] 2026-10-19T10:32:08+00:00 change found, reloading
{"logs":[]}
[nginx-reload] 2026-10-19T10:32:08+00:00 reload done
```

**By hand or from a deployment:** `nginx-reload` does the same and exits with `0` only when the new configuration
runs - an Ansible handler or a CI job can rely on it.

```bash
docker exec nginx nginx-reload
```

A broken configuration never takes nginx down: the reload is refused with nginx's message, nginx keeps serving the
previous configuration, and the container is unhealthy until a reload succeeds.

```
[nginx-reload] 2026-10-19T10:31:17+00:00 configuration invalid, nginx keeps running the previous one:
nginx: [emerg] unknown directive "not-a-directive" in /etc/nginx/conf.d/default.conf:46
nginx: configuration file /etc/nginx/nginx.conf test failed
```

**By signal:** `nginx -s reload` and `docker kill -s HUP nginx` work as in the official image - but neither nginx nor
the healthcheck tells whether a reload sent this way worked.

## Healthcheck

The image checks every 30 seconds:

- the nginx master and its workers run,
- the control API answers, where nginx has one,
- the last reload did not fail.

The reason for an unhealthy container is in `docker inspect`:

```bash
docker inspect --format '{{json .State.Health}}' nginx
```

## Environment variables

| Variable | Default | Meaning |
|---|---|---|
| `NGINX_WATCH` | `/etc/nginx` | files and directories, separated by spaces, whose changes trigger a reload; empty turns the automatic reload off |
| `NGINX_WATCH_INTERVAL` | `5` | seconds between the checksum compares that catch changes without inotify events |
| `NGINX_CONTROL_SOCKET` | `/var/run/nginx-control.sock` | socket of the nginx control API, opened at the start where nginx has one |
| `NGINX_RELOAD_WEBHOOK_SUCCESS_URL` | *empty* | URL called (GET) after a successful reload by `nginx-reload` |
| `NGINX_RELOAD_WEBHOOK_FAILURE_URL` | *empty* | URL called (GET) after a refused or failed reload |

The variables of the official image - `NGINX_ENVSUBST_*`, `NGINX_ENTRYPOINT_*` - work as there.

## Migrating from the earlier image

Until 2026-10 this image compared the checksums of `/etc/nginx/conf.d/*.conf` every ten seconds, ran
`nginx -t && nginx -s reload` without telling whether it worked, and edited `nginx.conf` through environment
variables. The watcher now covers all of `/etc/nginx`, and those settings belong into your own configuration:

| Earlier variable | Now |
|---|---|
| `OBSERVE_FILES_ENABLE=false` | `NGINX_WATCH=` (empty) |
| `OBSERVE_FILES` | `NGINX_WATCH` - files and directories instead of wildcards |
| `OBSERVE_INTERVAL` | `NGINX_WATCH_INTERVAL` |
| `OBSERVE_COMMAND` | removed - the reload is `nginx-reload`, the webhooks report its result |
| `OBSERVE_FILES_CREATE` | removed - mount the directory |
| `NGINX_CUSTOM_ADD_SERVER_TOKENS_OFF=true` | `server_tokens off;` in a file in `conf.d` |
| `NGINX_CUSTOM_PROXY_HEADERS_HASH_BUCKET_SIZE` | `proxy_headers_hash_bucket_size ...;` in a file in `conf.d` |
| `NGINX_CUSTOM_LOGFORMAT_*` | `log_format` in a file in `conf.d`, and `access_log /var/log/nginx/access.log <name>;` in the `server` block |
| `NGINX_CUSTOM_ADD_DIRECT_INCLUDE=true` | your own `/etc/nginx/nginx.conf`, with the `stream` block or the include you need |
| `NGINX_CUSTOM_DELETE_DEFAULT_CONF=true` | mount your own `conf.d` - it replaces `default.conf` |
| `EPICSOFT_LOG_LEVEL_DEBUG` | removed |

bash is not part of the image any more - the scripts are POSIX `sh`. `registry.gitlab.com/epicdocker/nginx` is gone;
Docker Hub `epicsoft/nginx` stays as it is.

## Reporting problems

Issues are welcome on [GitLab](https://gitlab.com/epicsoft-networks/nginx/-/issues) and
[GitHub](https://github.com/epicsoft-llc/nginx/issues). Please report a security problem as a
**confidential issue** on GitLab instead of a public one.

## License

[MIT](https://gitlab.com/epicsoft-networks/nginx/-/blob/master/LICENSE) — Copyright (c) 2018-2026 epicsoft LLC / Alexander Schwarz

The MIT license applies only to files created by epicsoft LLC. Third-party software in the image — nginx, the
Alpine packages and the official `nginx` image — remains under its own licenses.
