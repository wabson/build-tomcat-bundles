@echo off

set alfdir=..

if exist "%alfdir%\tomcat-app" goto exists

:separate
mkdir "%alfdir%\tomcat-app"
for %%f in (LICENSE NOTICE RELEASE-NOTES RUNNING.txt) do copy "%alfdir%\tomcat\%%f" "%alfdir%\tomcat-app" /Y
for %%f in (bin conf endorsed lib shared) do xcopy "%alfdir%\tomcat\%%f" "%alfdir%\tomcat-app\%%f" /Q /E /I
for %%f in (logs temp webapps work) do mkdir "%alfdir%\tomcat-app\%%f"
rem Copy webapps
move %alfdir%\tomcat\webapps\share.war* "%alfdir%\tomcat-app\webapps"
move %alfdir%\tomcat\webapps\share "%alfdir%\tomcat-app\webapps"
xcopy "%alfdir%\tomcat\webapps\ROOT" "%alfdir%\tomcat-app\webapps\ROOT" /E /Q /I
rem Remove webapp context files
if exist "%alfdir%\tomcat-app\conf\Catalina\localhost\solr.xml" del "%alfdir%\tomcat-app\conf\Catalina\localhost\solr.xml"
if exist "%alfdir%\tomcat-app\conf\Catalina\localhost\alfresco.xml" del "%alfdir%\tomcat-app\conf\Catalina\localhost\alfresco.xml"
rem Configure ports
copy /Y "server.xml.tomcat-app" "%alfdir%\tomcat-app\conf\server.xml"
goto end

:exists
echo "Web-tier Tomcat exists already"
pause
goto end

:end

