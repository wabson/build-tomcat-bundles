#!/bin/sh
alfdir=.

if [ ! -z "$1" ]; then
  alfdir="$1"
fi

if [ ! -d "$alfdir/tomcat-app" ]; then
  mkdir "$alfdir/tomcat-app"
  cp -pr "$alfdir/tomcat/LICENSE" "$alfdir/tomcat/NOTICE" "$alfdir/tomcat/RELEASE-NOTES" "$alfdir/tomcat/RUNNING.txt" "$alfdir/tomcat/bin" "$alfdir/tomcat/conf" "$alfdir/tomcat/endorsed" "$alfdir/tomcat/lib" "$alfdir/tomcat/shared" "$alfdir/tomcat-app"
  mkdir "$alfdir/tomcat-app/logs" "$alfdir/tomcat-app/temp" "$alfdir/tomcat-app/webapps" "$alfdir/tomcat-app/work"
  # Copy webapps
  cp -pr "$alfdir/tomcat/webapps/ROOT" "$alfdir/tomcat-app/webapps"
  mv "$alfdir/tomcat/webapps/share"* "$alfdir/tomcat-app/webapps"
  # Remove webapp context files
  test -f "$alfdir/tomcat-app/conf/Catalina/localhost/solr.xml" && rm "$alfdir/tomcat-app/conf/Catalina/localhost/solr.xml"
  test -f "$alfdir/tomcat-app/conf/Catalina/localhost/alfresco.xml" && rm "$alfdir/tomcat-app/conf/Catalina/localhost/alfresco.xml"
  # Configure ports
  sed -i ".bak" -e "s/8005/8006/" -e "s/8080/8081/" -e "s/8443/8444/" "$alfdir/tomcat-app/conf/server.xml"
  sed -i ".bak" -e "s/8080/8081/" "$alfdir/tomcat-app/conf/server.xml"
  # Share startup script
  cp -pr "$alfdir/bin/share.sh" "$alfdir"
else
  echo "Web-tier Tomcat exists already"
fi

