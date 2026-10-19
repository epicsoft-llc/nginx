#!/bin/sh
#### sh test/smoke.sh <image> [platform] - the reload cases against test/default.conf, run before every push

set -e

export MSYS_NO_PATHCONV=1

readonly IMAGE="$1"
readonly PLATFORM="${2:-}"
readonly NAME="nginx-smoke-$$"
readonly CONFIG="/etc/nginx/conf.d/default.conf"

PLATFORM_ARG=""
if [ -n "${PLATFORM}" ]; then
  PLATFORM_ARG="--platform=${PLATFORM}"
fi

cleanup() {
  docker rm -f "${NAME}" > /dev/null 2>&1 || true
}
trap cleanup EXIT

#### polls a command inside the container until it succeeds or the time is up
waitFor() {
  _DESCRIPTION="$1"
  shift
  _TRIES=0
  until docker exec "${NAME}" "$@" > /dev/null 2>&1; do
    _TRIES=$((_TRIES + 1))
    if [ "${_TRIES}" -ge 30 ]; then
      echo "FAIL: ${_DESCRIPTION}"
      docker logs "${NAME}" 2>&1 | tail -n 30
      exit 1
    fi
    sleep 2
  done
  echo "ok: ${_DESCRIPTION}"
}

answer() {
  docker exec "${NAME}" sh -c "wget -q -O - http://127.0.0.1:8080/ 2>/dev/null"
}

#### the arguments are options for 'docker create'
start() {
  docker create --name "${NAME}" ${PLATFORM_ARG} "$@" "${IMAGE}" > /dev/null # ok: optional
  docker cp "$(dirname "$0")/default.conf" "${NAME}:${CONFIG}"
  docker start "${NAME}" > /dev/null
}

start -e NGINX_WATCH_INTERVAL=2
waitFor "nginx answers" sh -c "wget -q -O - http://127.0.0.1:8080/ | grep -q smoke-before"
waitFor "healthcheck is healthy after the start" nginx-healthcheck
if docker exec "${NAME}" sh -c 'nginx -h 2>&1 | grep -q -e "-l addr"'; then
  waitFor "the control API is open" sh -c 'curl -s -f --unix-socket "${NGINX_CONTROL_SOCKET}" http://localhost/1/'
else
  echo "ok: nginx $(docker exec "${NAME}" sh -c 'echo "${NGINX_VERSION}"') has no control API, it reloads by signal"
fi

docker exec "${NAME}" sed -i 's/smoke-before/smoke-after/' "${CONFIG}"
waitFor "a valid change is reloaded automatically" sh -c "wget -q -O - http://127.0.0.1:8080/ | grep -q smoke-after"
waitFor "healthcheck stays healthy after the reload" nginx-healthcheck

docker exec "${NAME}" sh -c "echo 'not-a-directive;' >> ${CONFIG}"
waitFor "a broken change turns the container unhealthy" sh -c "! nginx-healthcheck"
if docker exec "${NAME}" nginx-reload > /dev/null 2>&1; then
  echo "FAIL: nginx-reload accepted a broken configuration"
  exit 1
fi
echo "ok: nginx-reload refuses the broken configuration"
if [ "$(answer)" != "smoke-after" ]; then
  echo "FAIL: nginx does not serve the previous configuration any more"
  exit 1
fi
echo "ok: nginx keeps serving the previous configuration"

docker exec "${NAME}" sed -i '/not-a-directive/d' "${CONFIG}"
waitFor "the fix makes the container healthy again" nginx-healthcheck

cleanup
start -e NGINX_WATCH=
waitFor "without the watcher: healthy after the start" nginx-healthcheck
docker exec "${NAME}" sed -i 's/smoke-before/smoke-manual/' "${CONFIG}"
if ! docker exec "${NAME}" nginx-reload > /dev/null 2>&1; then
  echo "FAIL: nginx-reload refused a valid configuration"
  exit 1
fi
echo "ok: nginx-reload accepts a valid configuration"
waitFor "nginx-reload brings the change" sh -c "wget -q -O - http://127.0.0.1:8080/ | grep -q smoke-manual"

echo "smoke test passed${PLATFORM:+ on ${PLATFORM}}"
