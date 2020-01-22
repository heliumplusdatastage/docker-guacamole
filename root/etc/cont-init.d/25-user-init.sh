#!/usr/bin/with-contenv sh

cat /app/guacamole/user-mapping-template.xml | envsubst > /app/guacamole/user-mapping.xml
