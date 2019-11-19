::========================================================================================
::========================================================================================
::
:: This tool builds ReportGenerator
::
::========================================================================================
::========================================================================================

@if not defined LOGDEBUG set LOGDEBUG=off
@echo %LOGDEBUG%
SetLocal EnableDelayedExpansion
for /f "delims=/" %%a in ('cd') do set CURRENTPWD=%%a
for %%a in (%0) do set CMDDIR=%%~dpa
for %%a in (%0) do set TOOLNAME=%%~na
set CMDPATH=%0
set RETCODE=1

set BUILDNO=
set RESDIR=
set SRCDIR=
set BUILDDIR=
set WORKSPACE=
:LOOP_ARG
    set option=%1
    if not defined option goto CHECK_ARGS
    shift
    set value=%1
    if defined value set value=%value:"=%
    call set %option%=%%value%%
    shift
goto LOOP_ARG

:CHECK_ARGS
if not defined BUILDNO (
	echo.
	echo No "buildno" defined !
	goto Usage
)
if not defined SRCDIR (
	echo.
	echo No "srcdir" defined !
	goto Usage
)
if not defined WORKSPACE (
	echo.
	echo No "workspace" defined !
	goto Usage
)
if not defined RESDIR (
	echo.
	echo No "resdir" defined !
	goto Usage
)
if not defined BUILDDIR (
	echo.
	echo No "builddir" defined !
	goto Usage
)

set NOPUB=false
set FILESRV=\\productfs01
if not defined ENGTOOLS set ENGTOOLS=%FILESRV%\EngTools
set SIGNDIR=%ENGTOOLS%\certificates
set PATH=%PATH%;C:\CAST-Caches\Win64
set INNODIR=%WORKSPACE%\InnoSetup5

set VERSION=1.12.1
set ID=com.castsoftware.aip.reportgeneratorfordashboard

for /f "delims=. tokens=1,2" %%a in ('echo %VERSION%') do set SHORT_VERSION=%%a.%%b
echo.
echo Current version is %VERSION%
echo Current short version is %SHORT_VERSION%

cd %WORKSPACE%
if errorlevel 1 (
	echo.
	echo ERROR: cannot find folder %WORKSPACE%
	goto endclean
)
if not exist %SRCDIR% (
	echo.
	echo ERROR: cannot find folder %SRCDIR%
	goto endclean
)
set WORK=%WORKSPACE%\work

echo.
echo ====================================
echo Get externals tools
echo ====================================

echo.
echo ==============================================
echo Cleaning ...
echo ==============================================
if exist %RESDIR% (
    echo Cleaning %RESDIR%
    rmdir /q /s %RESDIR%
    sleep 3
)
mkdir %RESDIR%
if errorlevel 1 goto endclean
pushd %RESDIR%
for /f "delims=/" %%a in ('cd') do set RESDIR=%%a
popd
if exist %WORK% (
    echo Cleaning %WORK%
    rmdir /q /s %WORK%
    sleep 3
)
mkdir %WORK%

cd %SRCDIR%
echo.
echo ==============================================
echo Compiling main and tests ...
echo ==============================================

@echo %LOGDEBUG%
if errorlevel 1 goto endclean
call dotnet build -c Release
if errorlevel 1 (
	echo.
	echo ERROR: Main compilation failed
	goto endclean
)

call dotnet test -l trx
if errorlevel 1 (
	echo.
	echo ERROR: Tests compilation failed
	goto endclean
)

echo.
echo ==============================================
echo Preparing package ...
echo ==============================================
pushd %WORKSPACE%
set REPORTINGDIR=%SRCDIR%/CastReporting.Reporting.Core
set CONSOLEDIR=%SRCDIR%/CastReporting.Console.Core/bin/Release/netcoreapp3.0

robocopy /njh /s %CONSOLEDIR% %WORK% *.dll
if errorlevel 8 exit /b 1
robocopy /njh %CONSOLEDIR% %WORK% *.config CastReporting.Console.Core.runtimeconfig.json CastReporting.Console.Core.deps.json
if errorlevel 8 exit /b 1
robocopy /njh %CONSOLEDIR%\Parameters %WORK%\Parameters Parameters.xml
if errorlevel 8 exit /b 1

::create the log folder
mkdir %WORK%\Logs
if errorlevel 1 exit /b 1

::put the templates in the right places
robocopy /njh /mir %REPORTINGDIR%\Templates %WORK%\Templates
if errorlevel 8 exit /b 1

::copy the settings file
robocopy /njh %SRCDIR%\CastReporting.Repositories.Core %WORK% CastReportingSetting.xml
if errorlevel 8 exit /b 1
robocopy %SRCDIR%\_build %WORK% License.rtf
if errorlevel 8 exit /b 1

set ZIPPATH=%RESDIR%\%ID%.%VERSION%.zip
pushd %WORK%
7z.exe a -y -r %ZIPPATH% .
if errorlevel 1 goto endclean

echo.
echo Package path is: %ZIPPATH%

pushd %WORKSPACE%
echo.
echo ==============================================
echo Nuget packaging ...
echo ==============================================
echo F|xcopy /f /y %SRCDIR%\_build\plugin_for_dashboard.nuspec %RESDIR%\plugin.nuspec
if errorlevel 1 goto endclean

sed -i 's/_THE_VERSION_/%VERSION%/' %RESDIR%/plugin.nuspec
if errorlevel 1 goto endclean
sed -i 's/_THE_SHORT_VERSION_/%SHORT_VERSION%/' %RESDIR%/plugin.nuspec
if errorlevel 1 goto endclean
sed -i 's/_THE_ID_/%ID%/' %RESDIR%/plugin.nuspec
if errorlevel 1 goto endclean

cd %WORKSPACE%
set CMD=%BUILDDIR%\nuget_package_basics.bat outdir=%RESDIR% pkgdir=%RESDIR% buildno=%BUILDNO% nopub=%NOPUB% is_component=true
echo Executing command:
echo %CMD%
call %CMD%
if errorlevel 1 goto endclean

for /f "tokens=*" %%a in ('dir /b %RESDIR%\com.castsoftware.*.nupkg') do set PACKPATH=%RESDIR%\%%a
if not defined PACKPATH (
	echo .
	echo ERROR: No package was created : file not found %RESDIR%\com.castsoftware.*.nupkg ...
	goto endclean
)
if not exist %PACKPATH% (
	echo .
	echo ERROR: File not found %PACKPATH% ...
	goto endclean
)

set GROOVYEXE=groovy
%GROOVYEXE% --version 2>nul
if errorlevel 1 set GROOVYEXE="%GROOVY_HOME%\bin\groovy"
%GROOVYEXE% --version 2>nul
if errorlevel 1 (
	echo ERROR: no groovy executable available, need one!
	goto endclean
)

:: ========================================================================================
:: Nuget checking
:: ========================================================================================
set CMD=%GROOVYEXE% %BUILDDIR%\nuget_package_verification.groovy --packpath=%PACKPATH%
echo Executing command:
echo %CMD%
call %CMD%
if errorlevel 1 goto endclean

echo End of build with success.
set RETCODE=0

:endclean
cd /d %CURRENTPWD%
exit /b %RETCODE%


:Usage
    echo usage:
    echo %0 workspace=^<path^> srcdir=^<path^> builddir=^<path^> RESDIR=^<path^> buildno=^<number^>
    echo.
    echo workspace: full path to the workspace dir
    echo srcdir: sources directory full path
    echo builddir: extension build directory full path
    echo RESDIR: output directory full path
    echo buildno: build number: build number for this package
    echo.
    goto endclean
goto:eof
