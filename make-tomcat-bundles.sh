#!/bin/bash

# Alfresco Tomcat bundles build script
# Author: Will Abson

if [ -z "$1" ]; then
  echo "Must specify ZIP file"
  exit 1
fi

ZIP="$1"
BUNDLE_BASE=`echo $ZIP | sed -e 's/.zip//' -e 's/alfresco-community/alfresco-community-tomcat/' -e 's/alfresco-enterprise/alfresco-enterprise-tomcat/'`

# Windows
./make-tomcat-bundle.sh "$BUNDLE_BASE.zip"
mv "$BUNDLE_BASE.zip" "$BUNDLE_BASE-mysql-win32.zip"

./make-tomcat-bundle.sh "$BUNDLE_BASE.tar.gz"
mv "$BUNDLE_BASE.tar.gz" "$BUNDLE_BASE-mysql-linux.tar.gz"

