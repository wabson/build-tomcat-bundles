#!/bin/bash

# Alfresco Linux Tomcat bundle build script
# Author: Will Abson

if [ "$1" == "-h" ]; then
  echo "Usage: make-tomcat-bundle.sh source target platform"
  exit
fi

if [ -z "$1" ]; then
  echo "Must specify a target package name"
  exit 1
fi

BUNDLE_PKG="$2"
WAR_PKG="$1"
PLATFORM="$3"
test -z "$PLATFORM" && PLATFORM="linux"
TEMP_DIR="tomcat-bundle-`date +%s`"
BUNDLE_NAME="`echo $BUNDLE_PKG | sed -e 's/\\.tar\\.gz$//' -e 's/\\.zip$//'`"
BUNDLE_DIR="${TEMP_DIR}/${BUNDLE_NAME}"
#WAR_PKG="`echo $BUNDLE_NAME | sed -e 's/\\-tomcat//'`.zip"
TOMCAT_PKG_TAR="apache-tomcat-6.0.29.tar.gz"
TOMCAT_PKG_ZIP="apache-tomcat-6.0.29.zip"
# Pre-4.0
#MYSQL_PKG_LINUX="mysql-5.1.59-linux-i686-glibc23.tar.gz"
#MYSQL_PKG_WINDOWS="mysql-noinstall-5.1.59-win32.zip"
# For 4.0
if [ "$PLATFORM" == "linux" ]; then
  MYSQL_PKG_LINUX="mysql-5.5.16-linux2.6-i686.tar.gz"
elif [ "$PLATFORM" == "osx" ]; then
  MYSQL_PKG_LINUX="mysql-5.5.25-osx10.6-x86_64.tar.gz"
fi
MYSQL_PKG_WINDOWS="mysql-5.5.16-win32.zip"
MYSQL_FILES_WINDOWS="*/bin/libmysql.dll */bin/mysql.exe */bin/mysqladmin.exe */bin/mysqld.exe */data/* */share/* */COPYING */EXCEPTIONS-CLIENT"
ALF_SCRIPT="/usr/local/bin/alfresco.sh"

if [ -e "${BUNDLE_DIR}" ]; then
  echo "Bundle already exists in '${BUNDLE_DIR}'"
  exit 1
fi

if [ -e "${BUNDLE_PKG}" ]; then
  echo "Bundle package '${BUNDLE_PKG}' already exists"
  exit 1
fi

if [ ! -f "${WAR_PKG}" ]; then
  echo "WAR package '${WAR_PKG}' does not exist"
  exit 1
fi

# Create required directories
mkdir -p "${BUNDLE_DIR}"

# Extract files from WAR bundle
echo "Extracting files from WAR bundle ${WAR_PKG}"
unzip -q "${WAR_PKG}" "bin/alfresco-mmt.jar" "licenses/*" "web-server/*" "README.txt" -d "${BUNDLE_DIR}"

# Extract Tomcat package files
case "$BUNDLE_PKG" in
  *.zip)
    echo "Extracting Tomcat files from ${TOMCAT_PKG_ZIP}"
    unzip -q "${TOMCAT_PKG_ZIP}" -x '*/webapps/docs/*' '*/webapps/examples/*' '*/webapps/host-manager/*' '*/webapps/manager/*' -d "${BUNDLE_DIR}"
    ;;
  *.tar.gz)
    echo "Extracting Tomcat files from ${TOMCAT_PKG_TAR}"
    tar -xzf "${TOMCAT_PKG_TAR}" -C "${BUNDLE_DIR}" --exclude='*/webapps/docs' --exclude='*/webapps/examples' --exclude='*/webapps/host-manager' --exclude='*/webapps/manager'
    ;;
  *)
    echo "Unsupported archive format"
    ;;
esac
mv "${BUNDLE_DIR}"/apache-tomcat-* "${BUNDLE_DIR}/tomcat"

# Extract MySQL files. Only the files required to run mysqld and bootstrap the alfresco database are copied over.
case "$BUNDLE_PKG" in
  *.zip)
    if [ -f "${MYSQL_PKG_WINDOWS}" ]; then
      echo "Adding MySQL files from ${MYSQL_PKG_WINDOWS}"
      unzip -q "${MYSQL_PKG_WINDOWS}" -d "${BUNDLE_DIR}" $MYSQL_FILES_WINDOWS
      mv "${BUNDLE_DIR}"/mysql-* "${BUNDLE_DIR}/mysql"
    else
      echo "Not adding MySQL to bundle. File '${MYSQL_PKG_WINDOWS}' not found."
    fi
    ;;
  *.tar.gz)
    if [ -f "${MYSQL_PKG_LINUX}" ]; then
      echo "Adding MySQL files from ${MYSQL_PKG_LINUX}"
      #tar -xzf "${MYSQL_PKG_LINUX}" -C "${BUNDLE_DIR}" --wildcards '*/bin/mysqld' '*/bin/mysqld_safe' '*/bin/mysql' '*/bin/my_print_defaults' '*/bin/resolveip' '*/lib' '*/scripts' '*/share' '*/support-files' --exclude='*/lib/*.a' --exclude='*/lib/.la'
      #tar -xzf "${MYSQL_PKG_LINUX}" -C "${BUNDLE_DIR}" --wildcards --no-wildcards-match-slash '*/bin/mysqld' '*/bin/mysqld_safe' '*/bin/mysql' '*/bin/my_print_defaults' '*/bin/resolveip' '*/scripts' '*/share' --exclude='**/*.a' --exclude='**/*.la'
      tar -xzf "${MYSQL_PKG_LINUX}" -C "${BUNDLE_DIR}" '*/bin/mysqld' '*/bin/mysqld_safe' '*/bin/mysql' '*/bin/my_print_defaults' '*/bin/resolveip' '*/scripts' '*/share'
      mv "${BUNDLE_DIR}"/mysql-* "${BUNDLE_DIR}/mysql"
    else
      echo "Not adding MySQL to bundle. File '${MYSQL_PKG_LINUX}' not found."
    fi
    ;;
  *)
    echo "Unsupported archive format"
    ;;
esac

# Add additional files to Tomcat from web-server directory in WAR bundle
cp -rf "${BUNDLE_DIR}/web-server/"* "${BUNDLE_DIR}/tomcat"
rm -rf "${BUNDLE_DIR}/web-server"

# Add extra files and directories
case "$BUNDLE_PKG" in
  *.zip)
    cp -pr bundle-files/windows/* "${BUNDLE_DIR}"
    ;;
  *.tar.gz)
    if [ "$PLATFORM" == "linux" ]; then
      cp -pr bundle-files/linux/* "${BUNDLE_DIR}"
    elif [ "$PLATFORM" == "osx" ]; then
      cp -pr bundle-files/macos/* "${BUNDLE_DIR}"
    fi
    ;;
  *)
    echo "Unsupported archive format"
    ;;
esac

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
