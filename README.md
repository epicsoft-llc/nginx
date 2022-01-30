<!-- vscode-markdown-toc -->
* 1. [Versions](#Versions)
* 2. [Requirements](#Requirements)
* 3. [Examples](#Examples)
	* 3.1. [Change configuration file](#Changeconfigurationfile)
	* 3.2. [Custom log format](#Customlogformat)
	* 3.3. [Log format for 'proxy_protocol'](#Logformatforproxy_protocol)
* 4. [Environments](#Environments)
* 5. [Links](#Links)
* 6. [License](#License)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->


# Nginx with automatic reload 

Nginx with automatic reload on file/configuration change.

The image extends the official [nginx](https://hub.docker.com/_/nginx/) image by a bash-script that detects changes based on the checksum and thus provides a way to reload nginx without restarting the conteiner or service.

The image offers the possibility to change the standard logging format and thus to choose a user-defined format, e.g. to access other variables when using the proxy protocol. This overwrites the default parameter `access_log` and uses the custom logging format.

The information about changes to files is not passed on to the container by the host, therefore checksums are created by the files and checked for changes in the interval. In case of a faulty nginx configuration, the application and the bash-script will continue, so that the error can be corrected without container restart.


##  1. <a name='Versions'></a>Versions

There is no versioning of this project, the current versions of `stable-alpine` and `alpine` (`latest`) are being built weekly.

If you need a different version, you may copy and modify my templates as needed.

`stable-alpine` `alpine` `latest` [Dockerfile](https://gitlab.com/epicdocker/nginx/blob/master/Dockerfile)


##  2. <a name='Requirements'></a>Requirements

- Docker installed - https://www.docker.com/get-docker


##  3. <a name='Examples'></a>Examples


###  3.1. <a name='Changeconfigurationfile'></a>Change configuration file 

Create your own configuration or copy it from the existing docker image.

```bash
mkdir -p /tmp/nginx
docker run --rm -it --entrypoint "" registry.gitlab.com/epicdocker/nginx:latest cat /etc/nginx/conf.d/default.conf > /tmp/nginx/default.conf
```

Start the container and mount your configuration from the host. In this example, the container blocks the terminal and displays the log.

```bash
docker run --rm -it --name nginx \
	-v /tmp/nginx:/etc/nginx/conf.d:ro \
	-p 80:80 \
	  registry.gitlab.com/epicdocker/nginx:latest
```

Now you can reach the nginx service with a browser on the port `80`. In a second terminal you can now change the configuration file `/tmp/nginx/default.conf` and in the log (first terminal) within a few seconds the modified file `/etc/nginx/conf.d/default.conf` and the command `nginx -t && nginx -s reload` to be executed should be displayed, as well as the message from the nginx itself `signal process started`.


###  3.2. <a name='Customlogformat'></a>Custom log format 

Start the Docker container with activated and user-defined logging format.

```bash
docker run --rm -it --name nginx \
	-e NGINX_CUSTOM_LOGFORMAT_ENABLE=true \
	-e NGINX_CUSTOM_LOGFORMAT='Example log format - $remote_addr - $remote_user [$time_local] "$request"' \
	-p 80:80 \
	  registry.gitlab.com/epicdocker/nginx:latest
```

In the browser, go to the page `http://localhost/` and reload a few times, e.g. with pressing `F5`. Then the logs in the user-defined format can be seen in the console.

```bash
[INFO] 2018-04-17T15:04:38+0000 Custom log format enabled
[INFO] 2018-04-17T15:04:38+0000 Starting observation for files '/etc/nginx/conf.d/*.conf' with command 'nginx -t && nginx -s reload'
Example log format - 172.17.0.1 - - [17/Apr/2018:15:08:43 +0000] "GET / HTTP/1.1"
Example log format - 172.17.0.1 - - [17/Apr/2018:15:08:44 +0000] "GET / HTTP/1.1"
Example log format - 172.17.0.1 - - [17/Apr/2018:15:08:45 +0000] "GET / HTTP/1.1"
```

Stop the container by pressing `Ctrl + C`.


###  3.3. <a name='Logformatforproxy_protocol'></a>Log format for 'proxy_protocol'

The following format can be used for the proxy protocol. Logging format taken from the [nginx documentation](https://docs.nginx.com/nginx/admin-guide/load-balancer/using-proxy-protocol/).

```bash
NGINX_CUSTOM_LOGFORMAT='$proxy_protocol_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"'
```


##  4. <a name='Environments'></a>Environments

`OBSERVE_FILES_ENABLE`

*default:* true

Enables (`true`) or disables (`false`) the monitoring of files. In combination with `NGINX_CUSTOM_DELETE_DEFAULT_CONF`, it should probably be turned off unless other file is to be monitored.

`OBSERVE_FILES`

*default:* /etc/nginx/conf.d/*.conf

A list of files with absolute paths to monitor for change (based on the checksum). One-, several- and wildcard-files may be specified, these must be separated by a space.

`OBSERVE_FILES_CREATE` 

*default:* true

Checks the list of files and creates files without content that does not exist. Wildcard files will be ignored and only directory created.

`OBSERVE_COMMAND` 

*default:* nginx -t && nginx -s reload

The command to execute, if any of the submitted files changed.

`OBSERVE_INTERVAL`

*default:* 10

Interval in seconds, in which the changes are checked.

`NGINX_CUSTOM_LOGFORMAT_ENABLE`

*default:* false

General switch on (`true`) or off (`false`) the user-defined logging format functionality.

`NGINX_CUSTOM_LOGFORMAT`

*default:* `'Custom log format - $remote_addr - $remote_user [$time_local] "$request"'`

The content of the nginx logging format. 

`NGINX_CUSTOM_LOGFORMAT_NAME`

*default:* custom

Name given to the logging format. `main` is already reserved and must not be used.

`NGINX_CUSTOM_ADD_SERVER_TOKENS_OFF`

*default:* false

Prevents sending the nginx version number in response. Adds the parameter `server_tokens off` to the nginx configuration directly in the HTTP context at the highest configuration level. This is valid for all website configurations. 

`NGINX_CUSTOM_ADD_DIRECT_INCLUDE`

*default:* false

Adds an additional include path to the configuration `/etc/nginx/inc.d/`, which is outside the HTTP context. This setting is required if you want to configure stream(s), as they can not be included in the HTTP context. The configuration file must have the suffix `.conf` to be included.

`NGINX_CUSTOM_DELETE_DEFAULT_CONF`

*default:* false

Deletes the default web page configuration file `/etc/nginx/conf.d/default.conf`. This setting is mainly needed if you use only the alternate include path of configuration file, see `NGINX_CUSTOM_ADD_DIRECT_INCLUDE`. If no custom file is being monitored, `OBSERVE_FILES_ENABLE` should be disabled.

`EPICSOFT_LOG_LEVEL_DEBUG`

*default:* false

Toggles the debug message from epicsoft scripts on (`true`) or off (`false`).

`NGINX_CUSTOM_PROXY_HEADERS_HASH_BUCKET_SIZE`

*default:* *not set (used nginx default)*

Parameter is set in 'http' context, description see [nginx documentation](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_headers_hash_bucket_size).


##  5. <a name='Links'></a>Links

- https://gitlab.com/epicdocker/nginx
- https://hub.docker.com/_/nginx/


##  6. <a name='License'></a>License

MIT License see [LICENSE](https://gitlab.com/epicdocker/nginx/blob/master/LICENSE)
