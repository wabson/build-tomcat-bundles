@echo off
rem ---------------------------------------------------------------------------
rem Start script for the Alfresco Server
rem ---------------------------------------------------------------------------

rem set Alfresco home (includes trailing \  e.g. c:\alfresco\)
set ALF_HOME=%~dps0
set ALF_DATA_HOME=%ALF_HOME%alf_data
set CATALINA_HOME=%ALF_HOME%tomcat
set CATALINA_PID=%CATALINA_HOME%\tomcat.pid

rem MySQL directories
set MYSQL_DATA_DIR=%ALF_DATA_HOME%\mysql
set MYSQL_HOME=%ALF_HOME%mysql
set MYSQL_PID=%MYSQL_HOME%\mysql.pid
set MYSQL_TMP_DIR=%MYSQL_HOME%\tmp
set MYSQL_PORT=33061
set MYSQL_DB=alfresco
set MYSQL_USER=alfresco
set MYSQL_PASS=alfresco

rem Set any default JVM options
set JAVA_OPTS=-Xms512m -Xmx1024m -Xss1024k -XX:MaxPermSize=256m -XX:NewSize=256m -server
set JAVA_OPTS=%JAVA_OPTS% -Dalfresco.home=%ALF_HOME% -Dcom.sun.management.jmxremote=true
set JAVA_OPTS=%JAVA_OPTS% -Ddir.root=%ALF_DATA_HOME% -Dimg.root=.
if not exist "%MYSQL_HOME%" goto postgres
set JAVA_OPTS=%JAVA_OPTS% -Ddb.driver=org.gjt.mm.mysql.Driver -Ddb.url=jdbc:mysql://localhost:%MYSQL_PORT%/%MYSQL_DB% -Ddb.username=%MYSQL_USER% -Ddb.password=%MYSQL_PASS%
:postgres
rem TODO Support Postgres

:setpaths
rem --- If SetPaths.bat already exists - assume set by hand and use as is
set PATH=%ALF_HOME%bin;%PATH%
if not exist "SetPaths.bat" goto getpaths 
call SetPaths.bat
goto start

:getpaths
call RegPaths.exe
call SetPaths.bat
del SetPaths.bat

:start
rem --- Test for Java settings
set BASEDIR=%CATALINA_HOME%
rem --- Reset errorlevel hack
verify >nul
call "%CATALINA_HOME%\bin\setclasspath.bat"
if errorlevel 1 goto error
set PATH=%JAVA_HOME%\bin;%PATH%

rem ---------------------------------------
rem Start Components
rem ---------------------------------------

if not ""%1"" == ""start"" goto stop

rem ---------------------------------------
rem Create alf_data directory if it does not exist
rem ---------------------------------------
if exist "%ALF_DATA_HOME%" goto mysqlprepare
mkdir "%ALF_DATA_HOME%"

:mysqlprepare
if exist "%MYSQL_DATA_DIR%" goto mysqlstart
xcopy "%MYSQL_HOME%\data" "%MYSQL_DATA_DIR%\" /E /Q

:mysqlstart
if not exist "%MYSQL_HOME%" goto tomcat
rem ---------------------------------------
rem Start MySQL
rem ---------------------------------------
echo Starting MySQL...
start "MySQL" %MYSQL_HOME%\bin\mysqld --no-defaults --port=%MYSQL_PORT% --pid-file=%MYSQL_PID% --character-set-server=utf8 --collation-server=utf8_general_ci --default-storage-engine=INNODB --basedir=%MYSQL_HOME% --datadir=%MYSQL_DATA_DIR% --console

rem Uncomment below to pause for some seconds before starting Tomcat
rem Change 5 to the number of seconds delay required
rem ping 1.0.0.0 -n 5 -w 1000 >NUL

rem ---------------------------------------
rem Create Alfresco Database
rem ---------------------------------------
if exist "%MYSQL_DATA_DIR%\alfresco" goto tomcat
ping 1.0.0.0 -n 5 -w 1000 >NUL
call "%MYSQL_HOME%\bin\mysql" -u root -P "%MYSQL_PORT%" -e "CREATE DATABASE %MYSQL_DB%; GRANT ALL PRIVILEGES ON %MYSQL_DB%.* TO %MYSQL_USER%@localhost IDENTIFIED BY '%MYSQL_PASS%';"
rem call "%MYSQL_HOME%\bin\mysql" -u root -P "%MYSQL_PORT%" < "%ALF_HOME%bin\create_db.sql"

:tomcat
rem ---------------------------------------
rem Start Tomcat
rem ---------------------------------------

echo Starting Tomcat...
call "%CATALINA_HOME%\bin\startup.bat"

rem ---------------------------------
rem Start Virtualization if available
rem ---------------------------------
rem if exist "~dp0virtual_start.bat" call "~dp0virtual_start.bat" 

goto end

:stop

rem ---------------------------------------
rem Stop Components
rem ---------------------------------------

if not ""%1"" == ""stop"" goto nostop

echo Shutting down Tomcat...
call "%CATALINA_HOME%\bin\shutdown.bat" 

if not exist "%MYSQL_HOME%" goto nextstop
rem if ""%2"" == ""nouser"" goto tomcatwait
rem set /P pause="Please wait until Tomcat has shut down, then press ENTER to continue..."
rem goto stopmysql
:tomcatwait
rem Change 10 to the number of seconds delay required
rem ping 1.0.0.0 -n 10 -w 1000 >NUL

rem We can use the presence of the org.alfresco.cache.ticketsCache.data file to detect when the repo has shut down
rem as this file is removed when Tomcat is shutting down
for %%a in (0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9) do if exist "%CATALINA_HOME%\temp\org.alfresco.cache.ticketsCache.data" ping 1.0.0.0 -n 1 -w 1000 >NUL
rem if the temp file still exists then it's likely Tomcat is still running
if exist "%CATALINA_HOME%\temp\org.alfresco.cache.ticketsCache.data" set /P pause="Please wait until Tomcat has shut down, then press ENTER to continue..."

:stopmysql
echo Stopping MySQL...
call "%MYSQL_HOME%\bin\mysqladmin" -u root -P "%MYSQL_PORT%" shutdown

:nextstop
rem if exist "virtual_start.bat" call virtual_stop.bat 

goto end

:error
echo Error encountered.
if ""%2"" == ""nouser"" goto end
set /P pause="Press ENTER to continue..."

:end
