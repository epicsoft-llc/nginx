<!-- vscode-markdown-toc -->
* 1. [Versions](#Versions)
* 2. [Requirements](#Requirements)
* 3. [Examples](#Examples)
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

The information about changes to files is not passed on to the container by the host, therefore checksums are created by the files and checked for changes in the interval. In case of a faulty nginx configuration, the application and the bash-script will continue, so that the error can be corrected without container restart.


##  1. <a name='Versions'></a>Versions

There is no versioning of this project, the current versions of `stable-alpine` and `alpine` (`latest`) are being built weekly.

If you need a different version, you may copy and modify my templates as needed.

`stable-alpine` `alpine` `latest` [Dockerfile](https://gitlab.com/epicdocker/nginx/blob/master/Dockerfile)


##  2. <a name='Requirements'></a>Requirements

- Docker installed - https://www.docker.com/get-docker


##  3. <a name='Examples'></a>Examples

Create your own configuration or copy it from the existing docker image.

    mkdir -p /tmp/nginx
    docker run --rm -it --entrypoint "" registry.gitlab.com/epicdocker/nginx:latest cat /etc/nginx/conf.d/default.conf > /tmp/nginx/default.conf

Start the container and mount your configuration from the host. In this example, the container blocks the terminal and displays the log.

    docker run --rm -it -v /tmp/nginx:/etc/nginx/conf.d:ro -p 80:80 --name nginx registry.gitlab.com/epicdocker/nginx:latest

Now you can reach the nginx service with a browser on the port `80`. In a second terminal you can now change the configuration file `/tmp/nginx/default.conf` and in the log (first terminal) within a few seconds the modified file `/etc/nginx/conf.d/default.conf` and the command `nginx -s reload` to be executed should be displayed, as well as the message from the nginx itself `signal process started`.


##  4. <a name='Environments'></a>Environments

`OBSERVE_FILES`

*default:* /etc/nginx/conf.d/default.conf

A list of files with absolute paths to monitor for change (based on the checksum). Both one and several files may be specified, these must be separated by a space.

`OBSERVE_FILES_CREATE` 

*default:* true

Checks the list of files and creates files without content that does not exist.

`OBSERVE_COMMAND` 

*default:* nginx -s reload

The command to execute, if any of the submitted files changes.

`OBSERVE_INTERVAL`

*default:* 10

Interval in seconds, in which the changes are checked.


##  5. <a name='Links'></a>Links

- https://gitlab.com/epicdocker/nginx
- https://hub.docker.com/_/nginx/


##  6. <a name='License'></a>License

MIT License see [LICENSE](https://gitlab.com/epicdocker/nginx/blob/master/LICENSE)
