:: Copyright (c) E5R Development Team. All rights reserved.
:: Licensed under the Apache License, Version 2.0. More license information in LICENSE.txt.

:: Get and install a C language family frontend for LLVM version 3.8.0

:: Prerequisites
:: * powershell.exe >= 2.0
:: * msiexec.exe

@echo off

:: --------------------------------------------------------------------------------------
:: Checking
:: --------------------------------------------------------------------------------------
where powershell >nul 2>&1
if "%ERRORLEVEL%" neq "0"; goto :nopowershell

powershell -command "if($psversiontable.psversion.major -lt 2){exit(1)}"
if "%ERRORLEVEL%" neq "0"; goto :powershelldeprecated

where msiexec >nul 2>&1
if "%ERRORLEVEL%" neq "0"; goto :nomsiexec

where findstr >nul 2>&1
if "%ERRORLEVEL%" neq "0"; goto :nofindstr

:: --------------------------------------------------------------------------------------
:: Preparing installation
:: --------------------------------------------------------------------------------------
:preinstall

set ARCH=x86
set INSTALLDIR=C:\CLang

set TEMPFOLDER=E5RGETCLANG%RANDOM%%DATE%%RANDOM%
set TEMPFOLDER=%TEMPFOLDER: =%
set TEMPFOLDER=%TEMPFOLDER:/=%

set TEMPPATH=%TEMP%\%TEMPFOLDER%

where wmic >nul 2>&1
if "%ERRORLEVEL%" neq "0"; goto :detectarchbyenv

wmic OS get OSArchitecture | findstr "64" >nul 2>&1
if "%ERRORLEVEL%" neq "0"; goto :preinstallnext
set ARCH=x64;
goto :preinstallnext

:detectarchbyenv
echo "%PROCESSOR_ARCHITECTURE%" | findstr "64" >nul 2>&1
if "%ERRORLEVEL%" neq "0"; goto :preinstallnext
set ARCH=x64

:preinstallnext
set URL7ZIP=http://www.7-zip.org/a/7z1602.msi
set FILE7ZIP=7z1602.msi
set URLCLANG=http://llvm.org/releases/3.8.0/LLVM-3.8.0-win32.exe
set FILECLANG=LLVM-3.8.0-win32.exe

if "%ARCH%" == "x64" (
    set URL7ZIP=http://www.7-zip.org/a/7z1602-x64.msi
    set FILE7ZIP=7z1602-x64.msi
    set URLCLANG=http://llvm.org/releases/3.8.0/LLVM-3.8.0-win64.exe
    set FILECLANG=LLVM-3.8.0-win64.exe
)

:: --------------------------------------------------------------------------------------
:: Installing
:: --------------------------------------------------------------------------------------
:install

if not exist %TEMPPATH%; mkdir %TEMPPATH%

echo Downloading 7-Zip...
powershell -NoProfile -ExecutionPolicy unrestricted -Command ^
  "$w=New-Object System.Net.WebClient;$w.Proxy=[System.Net.WebRequest]::DefaultWebProxy;$w.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials;$w.DownloadFile('%URL7ZIP%','%TEMPPATH%\%FILE7ZIP%')" ^
  >nul 2>&1

echo Downloading LLVM CLang...
powershell -NoProfile -ExecutionPolicy unrestricted -Command ^
  "$w=New-Object System.Net.WebClient;$w.Proxy=[System.Net.WebRequest]::DefaultWebProxy;$w.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials;$w.DownloadFile('%URLCLANG%','%TEMPPATH%\%FILECLANG%')" ^
  >nul 2>&1

echo Extracting %FILE7ZIP%...
msiexec /a "%TEMPPATH%\%FILE7ZIP%" /qn TARGETDIR="%TEMPPATH%\7Zip" /norestart /quiet >nul 2>&1

echo Extracting %FILECLANG%...
set ZIPPER=%TEMPPATH%\7Zip\Files\7-Zip\7z.exe
%ZIPPER% x -bd -o"%TEMPPATH%\CLang" "%TEMPPATH%\%FILECLANG%" >nul 2>&1

echo Removing CLang $PLUGINSDIR...
rmdir /S /Q "%TEMPPATH%\CLang\$PLUGINSDIR" >nul 2>&1

if exist %INSTALLDIR%; rmdir /S /Q %INSTALLDIR%
if "%ERRORLEVEL%" neq "0"; goto :noremoveold

echo Copying files to %INSTALLDIR%...
mkdir "%INSTALLDIR%"
xcopy /Y /E /Q "%TEMPPATH%\CLang" "%INSTALLDIR%\" >nul 2>&1

set PATH=%INSTALLDIR%\bin;%PATH%
echo.
echo #NOTE: Add "%INSTALLDIR%" on you PATH variable.

goto :success

:: --------------------------------------------------------------------------------------
:: Showing messages
:: --------------------------------------------------------------------------------------
:nopowershell
echo Requires PowerShell 2.0 or later
goto :error

:powershelldeprecated
echo Requires PowerShell 2.0 or later
goto :error

:nomsiexec
echo Requires msiexec.exe tool
goto :error

:nofindstr
echo Requires findstr.exe tool
goto :error

:noremoveold
echo Error on remove old instalation
goto :error

:success
echo.
echo C language family frontend for LLVM successfully installed
goto :finish

:error
endlocal
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:exitSetErrorLevel
exit /b 1

:exitFromFunction
()

:finish
endlocal

if exist %TEMPPATH%; rmdir /S /Q %TEMPPATH%
