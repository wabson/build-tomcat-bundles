Alfresco Tomcat Bundle Build Scripts
====================================

This project provides a Bash build script and supporting files for creating
generic Alfresco packages which supply the repository and Share WARs inside 
Tomcat, along with a dedicated MySQL instance.

The scripts are capable of building ZIP and TAR format packages suitable 
for use on Linux, Mac OS X or Windows. These were originally based on the
Tomcat bundles formerly provided by Alfresco, but now support a range of 
different configurations such as installing Solr support and additional 
options for developers.

You can download the bundles for recent version of Alfresco from 
[Will's blog](http://blogs.alfresco.com/wp/wabson/alfresco-tomcat-bundles/).

Or, for more information on what the bundles provide and how to use them, 
check out the README for the relevant platform

 * [Linux](/wabson/build-tomcat-bundles/blob/master/bundle-files/linux/README.md)
 * [Mac OS X](/wabson/build-tomcat-bundles/blob/master/bundle-files/osx/README.md)
 * [Windows](/wabson/build-tomcat-bundles/blob/master/bundle-files/win32/README.md)

Using the Scripts
-----------------

You can use the scripts provided by this project to build your own custom 
Tomcat bundles.

The main script is the `make-tomcat-bundle.sh` script. This takes a source 
Alfresco ZIP package (available from the Alfresco download pages), as well
as the name of the Tomcat bundle package to create. The third parameter is
the target platform, one of `linux`, `osx` or `win32`.

    ./make-tomcat-bundle.sh alfresco-community-4.2.a.zip alfresco-community-tomcat-4.2.a-linux-i686.tar.gz linux
    ./make-tomcat-bundle.sh alfresco-community-4.2.a.zip alfresco-community-tomcat-4.2.a-osx-x86_64.tar.gz osx
    ./make-tomcat-bundle.sh alfresco-community-4.2.a.zip alfresco-community-tomcat-4.2.a-win32.tar.gz win32

Contributing
------------

Push requests are welcome if you have additional contributions to the scripts.
