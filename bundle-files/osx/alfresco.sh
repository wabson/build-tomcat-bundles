#!/bin/bash

#
# Start/stop script for Alfresco
# Author: Will Abson
#
# Can be used to stop/start Alfresco installed in a standalone Tomcat instance, as well as MySQL.
# By default the script will look for a 'tomcat' directory in the current directory, which is best for demo environments.
# If you only have a single Alfresco instance you can change the location of $ALF_HOME to the install location, e.g. /opt/alfresco.
# If you have installed Alfresco in the system Tomcat instance, you should use /etc/init.d/tomcat6 or equivalent instead of this script.
#
# Usage: alfresco.sh start|stop|restart
#

# Set the following to where Tomcat is installed
if [ -z "${ALF_HOME}" ]; then
  ALF_HOME=`pwd`
fi

# Change location to Alfresco installation dir. Logs are placed here by default.
cd "${ALF_HOME}"

# Installation directories
TOMCAT_HOME="${ALF_HOME}/tomcat"
TOMCAT_APP_HOME="${ALF_HOME}/tomcat-app"
ALF_DATA_HOME="${ALF_HOME}/data"
MYSQL_DATA_DIR="${ALF_DATA_HOME}/mysql"
SOLR_HOME="${ALF_DATA_HOME}/solr"
MYSQL_HOME="${ALF_HOME}/mysql"
MYSQL_PID="${MYSQL_HOME}/mysql.pid"
MYSQL_SOCK="${MYSQL_HOME}/mysql.sock"
MYSQL_TMP_DIR="${MYSQL_HOME}/tmp"
MYSQL_USER="admin"
MYSQL_PASS="admin"
PG_DATA_DIR="${ALF_DATA_HOME}/postgres"
PG_PORT=54321
PG_USER="admin"
PG_PASS="admin"

# Port that MySQL should listen on
MYSQL_PORT="33061"

# Set default JVM values
export JAVA_OPTS='-Xms512m -Xmx1024m -Xss1024k -XX:MaxPermSize=256m -XX:NewSize=256m -server'
export JAVA_OPTS="${JAVA_OPTS} -Dalfresco.home=${ALF_HOME} -Dcom.sun.management.jmxremote=true"
export JAVA_OPTS="${JAVA_OPTS} -Ddir.root=${ALF_DATA_HOME}"
export JAVA_OPTS="${JAVA_OPTS} -Dooo.user=${ALF_DATA_HOME}"
test -d "$SOLR_HOME" && export JAVA_OPTS="${JAVA_OPTS} -Dindex.subsystem.name=solr -Ddir.keystore=\\\${dir.root}/keystore -Dsun.security.ssl.allowUnsafeRenegotiation=true"
export JAVA_OPTS="${JAVA_OPTS} ${ALFRESCO_OPTS}"

# Set database properties
if [ -d "${MYSQL_HOME}" ]; then
  export JAVA_OPTS="${JAVA_OPTS} -Ddb.driver=org.gjt.mm.mysql.Driver -Ddb.url=jdbc:mysql://localhost:${MYSQL_PORT}/alfresco -Ddb.username=${MYSQL_USER} -Ddb.password=${MYSQL_PASS}"
elif [ -d "${PG_DATA_DIR}" ]; then
  export JAVA_OPTS="${JAVA_OPTS} -Ddb.driver=org.postgresql.Driver -Ddb.url=jdbc:postgresql://localhost:${PG_PORT}/alfresco -Ddb.username=${PG_USER} -Ddb.password=${PG_PASS}"
fi

# Set default Tomcat values
export CATALINA_HOME="${TOMCAT_HOME}"
export CATALINA_BASE="${TOMCAT_HOME}"
export CATALINA_PID="${TOMCAT_HOME}/tomcat.pid"

# Add MySQL library paths
export LD_LIBRARY_PATH="${MYSQL_HOME}/lib:/usr/local/lib:/usr/lib:$LD_LIBRARY_PATH"
export MAGICK_HOME="/usr/local"

# Start Tomcat and MySQL if present
function start_all {
  prepare
  echo "Starting Database"
  db_start
  echo "Starting Tomcat"
  tomcat_start "$@"
}

# Stop Tomcat and MySQL if running
function stop_all {
  echo "Stopping Tomcat"
  tomcat_stop
  echo "Stopping Database"
  db_stop
}

# Restart Tomcat and MySQL
function restart_all {
  stop_all
  start_all
}

# Perform pre-flight checks, create prerequisite directories, etc.
function prepare {
  if [ ! -d "${TOMCAT_HOME}" ]; then
    echo "Tomcat directory '${TOMCAT_HOME}' not found. Are you in the right directory?"
    exit 1
  fi
  if [ ! -d "${ALF_DATA_HOME}" ]; then
    mkdir "${ALF_DATA_HOME}"
  fi
}

# Start Tomcat
function tomcat_start {
  prepare
  # Remove PID file if process does not exist
  if [ -e "$CATALINA_PID" ]; then
    PID=`cat $CATALINA_PID`
    if [ -z `ps -p $PID -o comm=` ]; then
      rm "$CATALINA_PID"
    fi
  fi
  if [ ! -e "$CATALINA_PID" ]; then
    catalina_opts="start"
    test "$1" = "jpda" && catalina_opts="jpda start"
    sh -c "${TOMCAT_HOME}/bin/catalina.sh $catalina_opts"
  else
    echo "Tomcat is already started"
  fi
}

# Start MySQL
function mysql_start {
  # Remove PID file if process does not exist
  if [ -e "$MYSQL_PID" ]; then
    PID=`cat $MYSQL_PID`
    if [ -z `ps -p $PID -o comm=` ]; then
      rm "$MYSQL_PID"
    fi
  fi
  if [ ! -e "$MYSQL_PID" ]; then
    prepare
    # Create data dir if it does not already exist
    if [ ! -d "${MYSQL_DATA_DIR}" ]; then
      mkdir "${MYSQL_DATA_DIR}"
    fi
    if [ ! -d "${MYSQL_TMP_DIR}" ]; then
      mkdir "${MYSQL_TMP_DIR}"
    fi
    # Install DB if it is not already installedZ
    if [ ! -d "${MYSQL_DATA_DIR}/mysql" ]; then
      echo "Installing MySQL database"
      # --no-defaults required for MySQL 5.5, which will attempt to chown the directory to user given in system my.cnf otherwise
      "${MYSQL_HOME}/scripts/mysql_install_db" --basedir="${MYSQL_HOME}" --datadir="${MYSQL_DATA_DIR}" --no-defaults
    fi
    # Start mysqld
    "${MYSQL_HOME}/bin/mysqld" --no-defaults --port="${MYSQL_PORT}" --pid-file="${MYSQL_PID}" --socket="${MYSQL_SOCK}" --character-set-server="utf8" --collation-server="utf8_general_ci" --default-storage-engine=INNODB --basedir="${MYSQL_HOME}" --datadir="${MYSQL_DATA_DIR}" --tmpdir="${MYSQL_TMP_DIR}" &
    # Wait for 5s
    sleep 5
    # Create the Alfresco DB if it does not exist already
    if [ ! -d "${MYSQL_DATA_DIR}/alfresco" ]; then
      echo "Creating alfresco database"
      "${MYSQL_HOME}/bin/mysql" --host=127.0.0.1 --port="${MYSQL_PORT}" --user="root" --password="" -e "CREATE DATABASE alfresco; GRANT ALL PRIVILEGES on alfresco.* TO ${MYSQL_USER}@localhost IDENTIFIED BY '${MYSQL_PASS}'"
    fi
  else
    echo "MySQL is already started"
  fi
}

function pg_start {
  # See http://willbryant.net/software/mac_os_x/postgres_initdb_fatal_shared_memory_error_on_leopard for problems with initdb on OSX
  test ! -e "${PG_DATA_DIR}" && mkdir -p "${PG_DATA_DIR}"
  test ! -e "${PG_DATA_DIR}/base" && initdb "${PG_DATA_DIR}"
  pg_ctl -D "${PG_DATA_DIR}" -o "-p ${PG_PORT}" -l logfile start
  sleep 1
  test -z "`psql -p ${PG_PORT} -d postgres --list | grep '^ alfresco'`" && psql -p "${PG_PORT}" -d postgres -c "CREATE DATABASE alfresco;" && psql -p "${PG_PORT}" -d postgres -c "CREATE USER ${PG_USER} WITH PASSWORD '${PG_PASS}';" && psql -p "${PG_PORT}" -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE alfresco to ${PG_USER};"
}

function db_start {
  if [ ! -z "`which psql`" -a ! -z "`which pg_ctl`" ]; then
    pg_start
  elif [ -d "${MYSQL_HOME}" ]; then
    mysql_start
  else
    echo "Could not find a database!"
    exit 1
  fi
}

function pg_stop {
  pg_ctl -D "${PG_DATA_DIR}" -o "-p ${PG_PORT}" stop
}

function db_stop {
  if [ -d "${PG_DATA_DIR}" ]; then
    pg_stop
  else
    mysql_stop
  fi
}

# Stop Tomcat
function tomcat_stop {
  # Sometimes Tomcat does not shut down in time for catalina.sh, which only seems willing to wait 10s.
  #
  # We could call catalina.sh stop -force, which will kill the process after this time. However this seems
  # a little unnececeassary.
  #
  # Instead we try catalina.sh stop, and if that doesn't work we wait a little longer. Then finally we 
  # kill the process if it is still there

  PID=`cat $CATALINA_PID`

  sh -c "${TOMCAT_HOME}/bin/catalina.sh stop 20 -force"

  # Wait 10s
  if [ -f "$CATALINA_PID" ]; then
     COUNTER=0
     while [ $COUNTER -lt 10 ]; do
       if [ ! -z "`ps -p $PID -o comm=`" ]; then
         sleep 1
       fi
       let COUNTER=COUNTER+1
     done

     # Kill the process
     if [ ! -z "`ps -p $PID -o comm=`" ]; then
        echo "Killing Tomcat process: $PID"
        kill -9 $PID
     fi
  fi

  # Remove the PID file if it still exists
  if [ -f "$CATALINA_PID" ]; then
     echo "Removing PID file $CATALINA_PID"
     rm $CATALINA_PID
  fi
}

# Stop MySQL
function mysql_stop {
  if [ -e "$MYSQL_PID" ]; then
    WAIT=10
    kill `cat "$MYSQL_PID"` >/dev/null
    # Wait for process to exit (when PID file is removed)
    while [ $WAIT -ge 0 ]; do
      if [ ! -e "$MYSQL_PID" ]; then
        break
      fi
      if [ $WAIT -gt 0 ]; then
        sleep 1
      fi
      if [ $WAIT -eq 0 ]; then
        echo "MySQL did not stop after ${WAIT} seconds."
      fi
      WAIT=`expr $WAIT - 1 `
    done
  else
    echo "Error: Could not find MySQL PID file"
  fi
}

# Install AMP files for the specified webapp (specified as argument)
function install_amps {
  INSTALLED_AMPS=0
  for f in `find "${ALF_HOME}/amps/$1" -name "*.amp"`; do
    echo "Installing AMP file \"$f\""
    if [ -f "${TOMCAT_HOME}/webapps/$1.war" ]; then
      java -jar "${ALF_HOME}/bin/alfresco-mmt.jar" install "$f" "${TOMCAT_HOME}/webapps/$1.war"
    elif [ -f "${TOMCAT_APP_HOME}/webapps/$1.war" ]; then
      java -jar "${ALF_HOME}/bin/alfresco-mmt.jar" install "$f" "${TOMCAT_APP_HOME}/webapps/$1.war"
    else
      echo "Could not find WAR file $1"
      exit 1
    fi
    let INSTALLED_AMPS=INSTALLED_AMPS+1
    mv "$f" "$f.installed"
  done
  if [ $INSTALLED_AMPS -gt 0 ]; then
    echo "Installed $INSTALLED_AMPS AMP files"
    if [ -d "${TOMCAT_HOME}/webapps/$1" ]; then
      while true; do
        read -p "Do you wish to remove the old web application files?" yn
        case $yn in
            [Yy]* ) rm -rf "${TOMCAT_HOME}/webapps/$1"; break;;
            [Nn]* ) break;;
            * ) echo "Please answer Y or N.";;
        esac
      done
    fi
  fi
}

if [ "$1" = "start" ]; then
  start_all
elif [ "$1" = "start-jpda" ]; then
  start_all jpda
elif [ "$1" = "start-tomcat" ]; then
  tomcat_start
elif [ "$1" = "start-tomcat-jpda" ]; then
  tomcat_start jpda
elif [ "$1" = "start-mysql" ]; then
  mysql_start
elif [ "$1" = "start-db" ]; then
  db_start
elif [ "$1" = "stop" ]; then
  stop_all
elif [ "$1" = "stop-tomcat" ]; then
  tomcat_stop
elif [ "$1" = "stop-mysql" ]; then
  mysql_stop
elif [ "$1" = "stop-db" ]; then
  db_stop
elif [ "$1" = "restart" ]; then
  restart_all
elif [ "$1" = "restart-tomcat" ]; then
  tomcat_stop
  tomcat_start
elif [ "$1" = "install_amps" -o "$1" = "install-amps" ]; then
  install_amps alfresco
  install_amps share
elif [ "$1" = "install-amps-alfresco" ]; then
  install_amps alfresco
elif [ "$1" = "install-amps-share" ]; then
  install_amps share
else
  echo "Usage: $0 start|stop|restart|install-amps|start-jpda|start-tomcat|start-tomcat-jpda|start-mysql|stop-tomcat|stop-mysql|restart-tomcat"
fi
