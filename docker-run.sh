#!/bin/bash

docker run -d --name="Zoneminder" \
--net="bridge" \
--privileged="false" \
--shm-size="1G" \
--device /dev/dri:/dev/dri \
-p 8443:443/tcp \
-p 8080:80/tcp \
-p 9000:9000/tcp \
-e TZ="America/Chicago" \
-e PUID="99" \
-e PGID="100" \
-e MULTI_PORT_START="0" \
-e MULTI_PORT_END="0" \
-e NO_START_ZN="1" \
-v "/mnt/cache/appdata/Zoneminder":"/config":rw \
-v "/mnt/cache/appdata/Zoneminder/data":"/var/cache/zoneminder":rw \
dlandon/zoneminder.unraid
