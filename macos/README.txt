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

Use an archive extractor to extract the files to a directory of your choice, 
or from the command line run:

  tar xzf alfresco-community-tomcat7-4.2.a-macos-x86_64.tar.gz

The files will be extracted to a new directory named according to the version,
e.g. 'alfresco-community-4.2.a'. If you are likely to have multiple copies of 
the same version you will want to rename this.

Usage
-----

# Starting, Stopping, Restarting

To start Tomcat and MySQL, type the following at the command line

  ./alfresco.sh start

You can start Tomcat or MySQL individually using the start-tomcat and 
start-mysql options.

To stop Tomcat and MySQL, use the following command

  ./alfresco.sh stop

As you might guess, the stop-tomcat and stop-mysql commands can be used for
more fine-grained control.

To restart Tomcat and MySQL, use the following command

  ./alfresco.sh restart

# Debugging

To start Tomcat in debug mode using JPDA, use the following

  ./alfresco.sh start-tomcat-jpda

Or to start MySQL as well, use

  ./alfresco.sh start-jpda

# Installing Solr

The install-solr.sh script in the bin directory can be used to install Solr
support into the installation.

From the Alfresco installation directory, run

  ./bin/install-solr.sh alfresco-community-solr.<version>.zip

Or from another directory,

  ./bin/install-solr.sh alfresco-community-solr.<version>.zip <alfresco_install_dir>

The Solr ZIP file can be downloaded from the Alfresco web site and must match
the version of your Alfresco installation.

Development Environment Setup
-----------------------------

The default installation is designed to be as small as possible, to start up 
and shut down quickly and to perform reasonably well. This means running the
repository and Share in a single Tomcat, configured with production settings.

However, if you are using your installation to develop and test Alfresco 
add-ons or customisations you can benefit by moving to a dual-Tomcat setup, 
with Share installed in a second Tomcat instance.

To switch your installation to this dual setup, first make sure Alfresco is
not running and then use the following command to copy the Tomcat instance

  ./bin/tomcat-sep.sh

Or, to run this on a directory other than the current location,

  ./bin/tomcat-sep.sh <alfresco_install_dir>

This will copy your Tomcat instance into a new directory named tomcat-app,
before copying the Share WAR files into it.

Once the tomcat-app directory is created, you can use the shell script 
share.sh to manage it

To start up Share, type

  ./share.sh start

To stop Share, type

  ./share.sh stop

To restart Share, type

  ./share.sh restart

To start up Share using JPDA debugging, type

  ./share.sh start-jpda

To enable JPDA to coexist with the repository, port 8001 is used rather than
the default port 8000.
