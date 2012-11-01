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
e.g. `alfresco-community-4.2.a`. If you are likely to have multiple copies of 
the same version you will want to rename this.

Usage
-----

To start Alfresco, use the `alf_start.bat` script. This will start up both
Alfresco and MySQL, each in its own terminal window which you can use to 
monitor the application.

Once started up, the Share application can be accessed by navigating to
the location `http://<servername>:8080/share` in a web browser.

MySQL will start up using port 33061, to avoid conflicts with any existing
MySQL installations you may have.

To stop and restart Alfresco, use the `alf-stop.bat` and `restart_alf.bat` 
scripts. These scripts will operate both Alfresco and MySQL.

AMP files can be installed into the repository or Share WAR files by placing 
them into the appropriate subdirectory in the amps directory. Then, use the 
`apply_amps.bat` script to install the files.

### Wiping the Repository ###

You can return to an initial state by stopping Alfresco and removing the `data`
directory. When the application next starts up it will re-create a blank 
database and bootstrap the repository.

Customising Repository Settings
-------------------------------

You may set up any custom repository settings via the `ALFRESCO_OPTS` environment
variable. These options are automatically passed to Alfresco upon startup and
this method has the advantage that you need only configure your settings once,
which will then apply to all the Tomcat bundle instances on your system.

Alternative you may change repository settings by renaming the file `tomcat/shared/classes/alfresco-global.properties.sample`,
to remove the `.sample` suffix. Inside the file you can then set any 
required properties.

Note that if you use both methods, the settings specified in `ALFRESCO_OPTS` will take priority.

Development Environment Setup
-----------------------------

The default installation is designed to be as small as possible, to start up
and shut down quickly and to perform reasonably well. This means running the
repository and Share in a single Tomcat, configured with production settings.

However, if you are using your installation to develop and test Alfresco
add-ons or customisations you can benefit by moving to a dual-Tomcat setup,
with Share installed in a second Tomcat instance.

To switch your installation to this dual setup, first make sure Alfresco is
not running and then use the `bin\tomcat-sep.bat` script to copy the Tomcat 
instance.

This will copy your Tomcat instance into a new directory named `tomcat-app`,
before moving the Share WAR files into it.

To start up Share, use the script `tomcat-app\bin\startup.bat`

Once started up, the Share application can be accessed by navigating to
the location `http://<servername>:8081/share` in a web browser.

To shutdown Share, use the script `tomcat-app\bin\shutdown.bat`

To restart Share, first shutdown and then start Share.

If you are deploying code for testing and debugging then you may wish to use
the `share-config-custom.xml.dev.sample` supplied inside Tomcat's `shared/classes`
directory. This will turn on Share's client debug mode and switch the Surf
framework into `development` mode.

To apply these setting simply rename the file to remove the `.dev.sample` suffix.
