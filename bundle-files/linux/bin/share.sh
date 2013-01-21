#!/bin/bash
# Alfresco Share startup script
# Author: Will Abson
catalina="tomcat-app/bin/catalina.sh"
if [ "$1" = "start" ]; then
  $catalina start
elif [ "$1" = "start-jpda" ]; then
  export JPDA_ADDRESS=8001
  $catalina jpda start
elif [ "$1" = "stop" ]; then
  $catalina stop
elif [ "$1" = "restart" ]; then
  $catalina stop
  sleep 1
  $catalina start
else
  echo "Usage: $0 start|stop|restart|start-jpda"
fi
