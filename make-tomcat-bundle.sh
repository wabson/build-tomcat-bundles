#!/bin/bash

# Alfresco Linux Tomcat bundle build script
# Author: Will Abson

tomcat_version=7.0.32
mysql_version=5.5.28

function usage {
  echo "Usage: make-tomcat-bundle.sh source target platform"
}

if [ "$1" == "-h" ]; then
  usage
  exit
fi

if [ -z "$1" ]; then
  echo "Must specify a source package"
  usage
  exit 1
fi

if [ -z "$2" ]; then
  echo "Must specify a target package"
  usage
  exit 1
fi

if [ -z "$3" ]; then
  echo "Must specify a target platform"
  usage
  exit 1
fi

if [ "$3" != "win32" -a "$3" != "linux" -a "$3" != "osx" ]; then
  echo "Target platform must be one of win32, linux or osx"
  usage
  exit 1
fi

BUNDLE_PKG="$2"
WAR_PKG="$1"
PLATFORM="$3"
test -z "$PLATFORM" && PLATFORM="linux"
TEMP_DIR="tomcat-bundle-`date +%s`"
BUNDLE_NAME="`echo $WAR_PKG | sed -e 's/\\.tar\\.gz$//' -e 's/\\.zip$//'`"
BUNDLE_NAME=`basename "$BUNDLE_NAME"`
BUNDLE_DIR="${TEMP_DIR}/${BUNDLE_NAME}"
#WAR_PKG="`echo $BUNDLE_NAME | sed -e 's/\\-tomcat//'`.zip"
TOMCAT_PKG_TAR="apache-tomcat-$tomcat_version.tar.gz"
TOMCAT_PKG_ZIP="apache-tomcat-$tomcat_version.zip"
# Pre-4.0
#MYSQL_PKG_LINUX="mysql-5.1.59-linux-i686-glibc23.tar.gz"
#MYSQL_PKG_WINDOWS="mysql-noinstall-5.1.59-win32.zip"
# For 4.0
if [ "$PLATFORM" == "linux" ]; then
  MYSQL_PKG_LINUX="mysql-$mysql_version-linux2.6-i686.tar.gz"
elif [ "$PLATFORM" == "osx" ]; then
  MYSQL_PKG_LINUX="mysql-$mysql_version-osx10.6-x86_64.tar.gz"
fi
MYSQL_PKG_WINDOWS="mysql-$mysql_version-win32.zip"
#MYSQL_FILES_WINDOWS="*/bin/libmysql.dll */bin/mysql.exe */bin/mysqladmin.exe */bin/mysqld.exe */data/* */share/* */COPYING */EXCEPTIONS-CLIENT"
# In MySQL 5.5.28 files have changed
MYSQL_FILES_WINDOWS="*/lib/libmysql.dll */bin/mysql.exe */bin/mysqladmin.exe */bin/mysqld.exe */data/* */share/* */COPYING"
ALF_SCRIPT="/usr/local/bin/alfresco.sh"

if [ -e "${BUNDLE_DIR}" ]; then
  echo "Bundle already exists in '${BUNDLE_DIR}'"
  exit 1
fi

if [ -e "${BUNDLE_PKG}" ]; then
  echo "Bundle package '${BUNDLE_PKG}' already exists"
  exit 1
fi

if [ ! -e "${WAR_PKG}" ]; then
  echo "WAR package '${WAR_PKG}' does not exist"
  exit 1
fi

# Create required directories
mkdir -p "${BUNDLE_DIR}"

# Extract Tomcat package files
case "$PLATFORM" in
  win32)
    echo "Extracting Tomcat files from ${TOMCAT_PKG_ZIP}"
    unzip -q "${TOMCAT_PKG_ZIP}" -x '*/webapps/docs/*' '*/webapps/examples/*' '*/webapps/host-manager/*' '*/webapps/manager/*' -d "${BUNDLE_DIR}"
    ;;
  linux | osx)
    echo "Extracting Tomcat files from ${TOMCAT_PKG_TAR}"
    tar -xzf "${TOMCAT_PKG_TAR}" -C "${BUNDLE_DIR}" --exclude='*/webapps/docs' --exclude='*/webapps/examples' --exclude='*/webapps/host-manager' --exclude='*/webapps/manager'
    ;;
  *)
    echo "Unsupported platform"
    ;;
esac
mv "${BUNDLE_DIR}"/apache-tomcat-* "${BUNDLE_DIR}/tomcat"

if [ -f "${WAR_PKG}" ]; then
  # Extract files from WAR bundle
  echo "Extracting files from WAR bundle ${WAR_PKG}"
  unzip -q "${WAR_PKG}" "bin/alfresco-mmt.jar" "licenses/*" "web-server/*" -d "${BUNDLE_DIR}"

  # Add additional files to Tomcat from web-server directory in WAR bundle
  test ! -d "${BUNDLE_DIR}/web-server" && echo "Required web-server directory not found in source file" && exit 1
  test ! -d "${BUNDLE_DIR}/web-server/webapps" && echo "Required web-server/webapps directory not found in source file" && exit 1
  cp -pr "${BUNDLE_DIR}/web-server/"* "${BUNDLE_DIR}/tomcat"
  rmdir "${BUNDLE_DIR}/web-server"
elif [ -d "${WAR_PKG}" ]; then
  test ! -d "${WAR_PKG}/webapps" && echo "Required webapps directory not found in source directory" && exit 1
  cp -pr "${WAR_PKG}/"* "${BUNDLE_DIR}/tomcat"
else
  echo "Missing or bad source file/directory '${WAR_PKG}'"
  exit 1
fi

if [ ! "$4" == "--nomysql" ]; then
  # Extract MySQL files. Only the files required to run mysqld and bootstrap the alfresco database are copied over.
  case "$PLATFORM" in
    win32)
      if [ -f "${MYSQL_PKG_WINDOWS}" ]; then
        echo "Adding MySQL files from ${MYSQL_PKG_WINDOWS}"
        unzip -q "${MYSQL_PKG_WINDOWS}" -d "${BUNDLE_DIR}" $MYSQL_FILES_WINDOWS
        mv "${BUNDLE_DIR}"/mysql-* "${BUNDLE_DIR}/mysql"
      else
        echo "WARNING: Not adding MySQL to bundle. File '${MYSQL_PKG_WINDOWS}' not found."
      fi
      ;;
    linux | osx)
      if [ -f "${MYSQL_PKG_LINUX}" ]; then
        echo "Adding MySQL files from ${MYSQL_PKG_LINUX}"
        #tar -xzf "${MYSQL_PKG_LINUX}" -C "${BUNDLE_DIR}" --wildcards '*/bin/mysqld' '*/bin/mysqld_safe' '*/bin/mysql' '*/bin/my_print_defaults' '*/bin/resolveip' '*/lib' '*/scripts' '*/share' '*/support-files' --exclude='*/lib/*.a' --exclude='*/lib/.la'
        #tar -xzf "${MYSQL_PKG_LINUX}" -C "${BUNDLE_DIR}" --wildcards --no-wildcards-match-slash '*/bin/mysqld' '*/bin/mysqld_safe' '*/bin/mysql' '*/bin/my_print_defaults' '*/bin/resolveip' '*/scripts' '*/share' --exclude='**/*.a' --exclude='**/*.la'
        tar -xzf "${MYSQL_PKG_LINUX}" -C "${BUNDLE_DIR}" '*/bin/mysqld' '*/bin/mysqld_safe' '*/bin/mysql' '*/bin/my_print_defaults' '*/bin/resolveip' '*/scripts' '*/share'
        mv "${BUNDLE_DIR}"/mysql-* "${BUNDLE_DIR}/mysql"
      else
      echo "WARNING: Not adding MySQL to bundle. File '${MYSQL_PKG_LINUX}' not found."
      fi
      ;;
    *)
      echo "Unsupported archive format"
      ;;
  esac
fi

# Add extra files and directories
cp -pr bundle-files/$PLATFORM/* "${BUNDLE_DIR}"

# Package up the archive
echo "Creating archive '${BUNDLE_PKG}'"
cd "$TEMP_DIR"
case "$BUNDLE_PKG" in
  *.zip)
    zip -rq "${BUNDLE_PKG}" "${BUNDLE_NAME}"
    ;;
  *.tar.gz)
    tar -czf "${BUNDLE_PKG}" "${BUNDLE_NAME}"
    ;;
  *)
    echo "Unsupported archive format"
    ;;
esac
mv "${BUNDLE_PKG}" ..

# Remove the temp directory
cd ..
rm -rf "$TEMP_DIR"

# End
