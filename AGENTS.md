# AGENTS.md

Guidance for AI coding agents and contributors working in this repository.

## What this repository is

A thin layer on top of the official `nginx` image (published as `epicsoft/nginx`). It adds one thing the official
image leaves to the user, done properly: reloading the configuration. Four shell scripts under `rootfs/` are the
product; the rest is the Dockerfile, the pipeline, the smoke test and documentation. `README.md` is the published
Docker Hub description and is uploaded by the pipeline, so it is part of the release artifact, not just documentation.

| | |
|---|---|
| **Repository** | developed on `gitlab.com/epicsoft-networks/nginx` (branch `master`), mirrored to `github.com/epicsoft-llc/nginx` |
| **Registries** | `registry.gitlab.com/epicsoft-networks/nginx` and Docker Hub `epicsoft/nginx` |
| **Platforms** | `linux/amd64` and `linux/arm64` |

Everything the official image does is kept as it is — its entrypoint with the scripts in `/docker-entrypoint.d/`
(templates, IPv6, worker tuning), `STOPSIGNAL SIGQUIT`, the master as `root` with the workers as `nginx`, logging to the
container log. Do not re-add what nginx or the official image do themselves.

## Rules

- **Public repository, MIT.** No internals in any file: no internal hosts, runner or server names, no credentials, no
  infrastructure details.
- **Everything in English** - Dockerfile, scripts, comments, README, CHANGELOG, commit messages.
- **No attribution lines** - no `Co-Authored-By:` trailer, no "Generated with" line and no session link in files,
  commit messages or merge request texts.
- **Never commit, push, merge, rebase or tag** - changes stay in the working tree.
- **`README.md` is part of the release:** every link in it stays absolute, a relative link breaks on Docker Hub, and
  it stays below 25,000 bytes.
- **A change users notice gets a `CHANGELOG.md` entry** under a date heading, `## YYYY-MM-DD` - never
  `## [Unreleased]`; the image has no version of its own.

## How it works

- **`nginx-entrypoint`** adds `-l unix:$NGINX_CONTROL_SOCKET` to the `nginx` command where nginx has the control API
  (1.31.5 and newer, found through `nginx -h`), removes a socket left from an earlier start and hands over to the
  official `/docker-entrypoint.sh`, which `exec`s nginx - the master is PID 1 and gets the stop signal.
- **`/docker-entrypoint.d/90-nginx-watch.sh`** starts **`nginx-watch`** as the last step before nginx, after the
  official scripts have rendered the templates. The watcher takes its baseline checksum right then, so a change during
  the start of nginx is reloaded once it runs. It waits for inotify events below `NGINX_WATCH` with a timeout of
  `NGINX_WATCH_INTERVAL` seconds and compares a checksum over all watched files after every wake-up. The checksum is
  what decides: a bind mount from Docker Desktop sends no events, and editors write in several steps.
- **`nginx-reload`** runs `nginx -t` first - a broken file is never handed to the master - then reloads through the
  control API with `PATCH /1/control/config`, which answers once the new workers run: `200`, or `422` with nginx's
  messages. Without the control API it sends `nginx -s reload`, and nginx does not answer. It writes
  `ok|failed <epoch>` to `/var/run/nginx-reload.state` and calls the optional webhooks.
- **`nginx-healthcheck`** looks for the master and worker processes, asks `GET /1/` on the control socket where there
  is one, and reads the state file: unhealthy when the last reload failed, because nginx then keeps serving the
  previous configuration. A reload sent past `nginx-reload` - `nginx -s reload`, `SIGHUP` - is not seen.

## Tests

```bash
docker build -t nginx:test --pull --no-cache --build-arg NGINX_TAG=alpine .
sh test/smoke.sh nginx:test                      # optionally a platform as second argument
```

`test/smoke.sh` starts nginx with `test/default.conf` (copied in with `docker cp`, which works against a `docker:dind`
service as well) and goes through: answer, healthy, the control API where nginx has one, automatic reload of a valid
change, a broken change refused and unhealthy while the previous configuration keeps serving, healthy again after the
fix; then, in a second container without the watcher, a reload by hand. The pipeline runs it for both lines and every
platform before the push; a new behaviour of the scripts belongs into it. Check `NGINX_TAG=stable-alpine` as well - it
takes the path without the control API.

## Tags and pipeline (`.gitlab-ci.yml`)

| Tag | Built on |
|---|---|
| `latest`, `alpine` | `nginx:alpine` (mainline) |
| `stable-alpine` | `nginx:stable-alpine` |

There is no version number of this image; a tag is an nginx line, rebuilt weekly. The nginx version comes from
`NGINX_VERSION` of the official image and goes into the label `image.nginx.version`. `CHANGELOG.md` therefore has
dated entries.

**Git tags and GitHub releases:** a git tag is the date of a `CHANGELOG.md` entry, such as `2026-10-19`, set on the
green commit of the default branch that carries the entry. Until then the entry may still grow; once tagged it is
fixed, and a correction goes into the next entry. A tag pipeline runs only `github-release`, which waits for the tag on
GitHub and creates the release from that entry. Tags are protected, because `GITHUB_TOKEN` is a protected variable.

New nginx releases reach the images with the weekly build and need no commit. They get one entry per quarter, in
January, April, July and October, listing the nginx versions of the latest build; a release that fixes a
vulnerability rated high or critical gets its entry right away.

One job per line extends `.build` and sets `VERSION` (the published tag), optionally `EXTRA_TAGS` (further names for
the same image, `alpine` on `latest`) and `NGINX_TAG` (the official tag). Each platform is built, loaded and
smoke-tested before the multi-platform push, which reuses those layers from the builder cache. The `docker:dind`
service runs with TLS, which buildx only takes from a Docker context — hence `docker context create dind` before
`docker buildx create`. `linux/arm64` on an `amd64` runner needs QEMU (`binfmt_misc`) on the runner host, which is why
the jobs carry the runner tag `imagex`. Publishing happens only from the default branch and the weekly schedule.

CI variables: `DOCKER_HUB_USER` (protected), `DOCKER_HUB_TOKEN` and `GITHUB_TOKEN` (masked, protected). The tokens go
in over stdin and through the environment, never onto a command line.

**GitHub mirror:** a push mirror in the GitLab project settings (Repository → Mirroring repositories) with its own
token — not part of the pipeline. Changes are never pushed to GitHub directly; the mirror would overwrite them.

**The next stable line** brings the control API to `stable-alpine`. The scripts need no change - `nginx-entrypoint`
finds `-l` in `nginx -h` - but the README section on versions describes the difference between the lines: update it.

## Conventions

- `.editorconfig`: 2-space indent, LF, UTF-8, final newline, trailing whitespace trimmed (except Markdown), 120 columns
  (180 for YAML, off for Markdown); `.gitattributes` keeps LF in the repository.
- The scripts are POSIX `sh` (the image has no bash) and get their executable bit from `COPY --chmod=755`.
- `apk --no-cache upgrade` comes before `apk add`: `apk add` never upgrades the packages of the base image.
- Commit messages follow Conventional Commits (`feat:`, `fix:`, `ci:`, `chore:`).
