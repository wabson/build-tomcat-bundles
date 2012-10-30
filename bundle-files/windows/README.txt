Tomcat Bundle for Alfresco 4.2.a
================================

This package provides a compact installation of Alfresco suitable for testing
and development purposes. It is intended to be easy to install and start up, 
these being important considerations where multiple installations are 
required.

This package bundles the Alfresco webapps and sample configuration files 
inside a Tomcat 7 servlet container and provides a MySQL 5.5 instance for
data storage.

By default both the repository and Share webapps are installed in the same 
Tomcat instance and Solr support is not installed. Utility scripts are provided
for easily splitting Share into a separate webapp and for installing Solr.

Installation
------------

Use an archive extractor to extract the files to a directory of your choice.

The files will be extracted to a new directory named according to the version,
e.g. 'alfresco-community-4.2.a'. If you are likely to have multiple copies of 
the same version you will want to rename this.

Usage
-----

TODO

