# Nginx with inotifywait 

Nginx with inotifywait and automatic reload on file change.

The image extends the official [nginx](https://hub.docker.com/_/nginx/) image with `inotify-tools` and offers a very convenient way to reload the nginx.


## Versions

There is no versioning of this project, the current versions of `alpine` and `stable-alpine` are being built weekly.

If you need a different version, you may copy and modify my templates as needed.

`alpine` `stable-alpine` [Dockerfile](https://gitlab.com/epicdocker/nginx/blob/master/Dockerfile) ToDo Link


## Requirements

- Docker installed - https://www.docker.com/get-docker


## Examples

ToDo


## Environments

`INOTIFYWAIT_MODIFY_FILES` **required**

*default:* _empty_

A list of files with absolute paths to monitor for `modify`. Both one and several files may be specified, these must be separated by a space.

`INOTIFYWAIT_MODIFY_FILES_CREATE` 

*default:* true

Checks the list of files and creates files without content that does not exist.

`INOTIFYWAIT_MODIFY_COMMAND` 

*default:* nginx -s reload

The command to execute, if any of the submitted files changes.


## Links

- https://gitlab.com/epicdocker/nginx
- https://hub.docker.com/_/nginx/


## License

MIT License see [LICENSE](https://gitlab.com/epicdocker/nginx/blob/master/LICENSE) ToDo Link
