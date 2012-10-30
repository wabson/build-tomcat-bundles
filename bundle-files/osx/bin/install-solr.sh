#!/bin/bash

# Keystore password
KEYSTORE_PASSWORD=kT9X6oe68t
#KEYSTORE_PASSWORD=custompassword

function usage() {
  echo "Usage: $0 solr-zip alfresco-dir"
}

function add_tomcat_user() {
  ln=`grep -n '\s*</tomcat-users>\s*' "$1" | cut -d ":" -f 1`
  lc="$( wc -l "$1" | sed -e 's/^  *//g' | cut -d " " -f 1 )"
  if [ -z "`grep \"$2,\" \"$1\"`" ]; then
    head -n $((ln-1)) $1 > $1.head
    echo "  <user username=\"CN=$2, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB\" roles=\"$3\" password=\"null\"/>" > $1.this
    tail -n $((lc-ln+1)) $1 > $1.tail
    cat $1.head $1.this $1.tail > $1
    rm $1.head $1.this $1.tail
  fi
}

function enable_ssl() {
  ln=`grep -n '\s*</Service>\s*' "$1" | cut -d ":" -f 1`
  lc="$( wc -l "$1" | sed -e 's/^  *//g' | cut -d " " -f 1 )"
  if [ -z "`grep \"ssl.keystore\" \"$1\"`" ]; then
    head -n $((ln-1)) $1 > $1.head
    echo '' > $1.this
    echo '    <Connector port="8443" protocol="org.apache.coyote.http11.Http11Protocol" SSLEnabled="true"' >> $1.this
    echo '               maxThreads="150" scheme="https" keystoreFile="../data/keystore/ssl.keystore" keystorePass="'$KEYSTORE_PASSWORD'" keystoreType="JCEKS"' >> $1.this
    echo '               secure="true" connectionTimeout="240000" truststoreFile="../data/keystore/ssl.truststore" truststorePass="'$KEYSTORE_PASSWORD'"' >> $1.this
    echo '               truststoreType="JCEKS" clientAuth="false" sslProtocol="TLS" allowUnsafeLegacyRenegotiation="true" />' >> $1.this
    echo '' >> $1.this
    tail -n $((lc-ln+1)) $1 > $1.tail
    cat $1.head $1.this $1.tail > $1
    rm $1.head $1.this $1.tail
  fi
}

function generate_keystores() {
   # The subject name of the key used to sign the certificates
   REPO_SUBJECT_NAME="/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Alfresco Repository"
   # The repository server certificate subject name, as specified in tomcat/conf/tomcat-users.xml with roles="repository"
   REPO_CERT_DNAME="CN=Alfresco Repository, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB"
   # The SOLR client certificate subject name, as specified in tomcat/conf/tomcat-users.xml with roles="repoclient"
   SOLR_CLIENT_CERT_DNAME="CN=Alfresco Repository Client, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB"
   # The number of days before the certificate expires
   CERTIFICATE_VALIDITY=36525
   BROWSER_KEYSTORE_PASSWORD=alfresco

   openssl genrsa -des3 -passout pass:$KEYSTORE_PASSWORD -out ca.key 1024
   openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -passin pass:$KEYSTORE_PASSWORD -subj "$REPO_SUBJECT_NAME" -passout pass:$KEYSTORE_PASSWORD

   # Generate Alfresco Repository SSL keystores
   keytool -genkey -alias 'ssl.repo' -keyalg RSA -keystore ssl.keystore -storetype JCEKS -dname "$REPO_CERT_DNAME" -storepass "$KEYSTORE_PASSWORD" -keypass "$KEYSTORE_PASSWORD"
   keytool -keystore ssl.keystore -alias 'ssl.repo' -certreq -file repo.csr -storetype JCEKS -storepass "$KEYSTORE_PASSWORD"
   openssl x509 -CA ca.crt -CAkey ca.key -CAcreateserial -req -in repo.csr -out repo.crt -days "$CERTIFICATE_VALIDITY" -passin pass:$KEYSTORE_PASSWORD
   keytool -import -alias 'alfresco.ca' -file ca.crt -keystore ssl.keystore -storetype JCEKS -storepass $KEYSTORE_PASSWORD -noprompt
   keytool -import -alias 'ssl.repo' -file repo.crt -keystore ssl.keystore -storetype JCEKS -storepass $KEYSTORE_PASSWORD -noprompt
   keytool -importkeystore -srckeystore ssl.keystore -srcstorepass $KEYSTORE_PASSWORD -srcstoretype JCEKS -srcalias 'ssl.repo' -srckeypass $KEYSTORE_PASSWORD -destkeystore browser.p12 -deststoretype pkcs12 -deststorepass $BROWSER_KEYSTORE_PASSWORD -destalias repo -destkeypass $BROWSER_KEYSTORE_PASSWORD
   keytool -import -alias AlfrescoCA -file ca.crt -keystore ssl.truststore -storetype JCEKS -storepass $KEYSTORE_PASSWORD -noprompt

   # Generate Alfresco Solr SSL keystores
   keytool -genkey -alias 'ssl.repo.client' -keyalg RSA -keystore ssl.repo.client.keystore -storetype JCEKS -storepass $KEYSTORE_PASSWORD -keypass "$KEYSTORE_PASSWORD" -dname "$SOLR_CLIENT_CERT_DNAME"
   keytool -keystore ssl.repo.client.keystore -alias 'ssl.repo.client' -certreq -file ssl.repo.client.csr -storetype JCEKS -storepass $KEYSTORE_PASSWORD
   openssl x509 -CA ca.crt -CAkey ca.key -CAcreateserial -req -in ssl.repo.client.csr -out ssl.repo.client.crt -days "$CERTIFICATE_VALIDITY" -passin pass:$KEYSTORE_PASSWORD
   keytool -import -alias 'alfresco.ca' -file ca.crt -keystore ssl.repo.client.keystore -storetype JCEKS -storepass $KEYSTORE_PASSWORD -noprompt
   keytool -import -alias 'ssl.repo.client' -file ssl.repo.client.crt -keystore ssl.repo.client.keystore -storetype JCEKS -storepass $KEYSTORE_PASSWORD -noprompt
   keytool -import -alias 'alfresco.ca' -file ca.crt -keystore ssl.repo.client.truststore -storetype JCEKS -storepass $KEYSTORE_PASSWORD -noprompt

   # Copy files
   cp ssl.keystore ssl.truststore browser.p12 data/keystore/
   cp ssl.repo.client.keystore ssl.repo.client.truststore solr/workspace-SpacesStore/conf
   cp ssl.repo.client.keystore ssl.repo.client.truststore solr/archive-SpacesStore/conf

   # Remove temporary files
   rm repo.csr ca.key ca.crt repo.crt ssl.keystore browser.p12 ssl.truststore ssl.repo.client.csr ssl.repo.client.crt ssl.repo.client.keystore ssl.repo.client.truststore
}

# Copy files from a source distribution
function copy_keystore_files() {
  test ! -d "$1" && echo "Cannot find keystore files" && exit 1
  cp "$1/ssl.keystore" "$1/ssl.truststore" "$1/keystore" "$1/ssl-keystore-passwords.properties" "$1/ssl-truststore-passwords.properties" "$1/keystore-passwords.properties" "$2/data/keystore"
}

REPO_SRC="~/Development/projects/tomcat-bundles/code/root/projects/repository"
KEYSTORE="$REPO_SRC/config/alfresco/keystore"
SOLR_ZIP="$1"
DD=.

if [ ! -z "$2" ]; then
  DD="$2"
fi

# Check parameters
test -z "$SOLR_ZIP" && echo "Must specify the location of the SOLR ZIP file" && usage && exit 1
test ! -f "$SOLR_ZIP" && echo "The SOLR ZIP file '$SOLR_ZIP' does not exist or is not a file" && usage && exit 1
test -z "$SOLR_ZIP" && echo "Must specify the location of the target Alfresco directory" && usage && exit 1
test ! -d "$DD" && echo "The target Alfresco directory does not exist or is not a directory" && usage && exit 1
test ! -d "$DD/tomcat" && echo "The target Alfresco directory must contain a 'tomcat' subdirectory" && usage && exit 1

REAL_DD=`cd $DD; pwd`
ESCAPED_DD=`echo "$REAL_DD" | sed -e 's/\//\\\\\//g'`

mkdir -p "$DD/solr"
unzip -qf "$SOLR_ZIP" -d "$DD/solr"
test ! -d "$DD/tomcat/conf/Catalina/localhost" && mkdir -p "$DD/tomcat/conf/Catalina/localhost"
cp "$DD/solr/solr-tomcat-context.xml" "$DD/tomcat/conf/Catalina/localhost/solr.xml"

sed -i -e "s/@@ALFRESCO_SOLR_DIR@@/$ESCAPED_DD\/solr/g" "$DD/tomcat/conf/Catalina/localhost/solr.xml"
sed -i -e "s/@@ALFRESCO_SOLR_DIR@@/$ESCAPED_DD\/data\/solr/" "$DD/solr/workspace-SpacesStore/conf/solrcore.properties"
sed -i -e "s/@@ALFRESCO_SOLR_DIR@@/$ESCAPED_DD\/data\/solr/" "$DD/solr/archive-SpacesStore/conf/solrcore.properties"

test ! -d "$DD/data/solr" && mkdir -p "$DD/data/solr"
test ! -d "$DD/data/keystore" && mkdir -p "$DD/data/keystore"

# Copy keystore files. Generation of keys could be enabled here but does not currently work
#generate_keystores
if [ -d "$DD/solr/alf_data/keystore" ]; then
  copy_keystore_files "$DD/solr/alf_data/keystore" "$DD"
else
  copy_keystore_files "$KEYSTORE" "$DD"
fi

add_tomcat_user "$DD/tomcat/conf/tomcat-users.xml" "Alfresco Repository Client" "repoclient"
add_tomcat_user "$DD/tomcat/conf/tomcat-users.xml" "Alfresco Repository" "repository"

enable_ssl "$DD/tomcat/conf/server.xml"
