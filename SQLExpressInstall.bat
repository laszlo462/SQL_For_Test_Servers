:: Author: Steve Szabo
:: Date: 7/16/2018
:: SQL Server 2012 Express Install Script
:: Installs SQL Server 2012 Express for IBE B.08 and DynaLync 1.2 Test Servers.

@echo off

title SQL 2012 Express Deployment
cls

echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo:
echo This script will install SQL Server 2012 Express for IBE B.08 or DynaLync 1.2 Test Servers.
echo:
echo Please ensure the following folders from the DynaLync 330149 install files are present on this server.
echo - SQL_2012_Standard
echo - SQL_2012_ServicePack3
echo:
echo Default test server install location is on C:\.  Please update '\_scriptFiles\2012ExpressConfigurationFile.ini' if other location is required.
echo:
echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo Press CTRL-C to quit, or ENTER to continue...
echo:
pause

powershell -ExecutionPolicy Bypass -Noexit -Command "Start-Process PowerShell -Verb RunAs -WorkingDirectory %~dp0_scriptFiles -ArgumentList '-file %~dp0_scriptFiles\_SQLExpressInstall.ps1'"
