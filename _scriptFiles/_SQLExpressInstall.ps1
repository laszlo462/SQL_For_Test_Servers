# Author: Steve Szabo
# Date: 07/18/2018
# Installs SQL Server 2012 Express as per IBE defaults + Service Pack 3, for IBE test server deployment.

$scriptFile = $MyInvocation.MyCommand.Definition
$scriptPath = Split-Path -Parent $scriptFile
Set-Location -Path $scriptPath
$configLocation = $scriptPath + "\2012ExpressConfigurationFile.ini"
$folderCheck1 = Test-Path '..\SQL_2012_Standard\'
$folderCheck2 = Test-Path '..\SQL_2012_ServicePack3\'
$separator = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

If ($folderCheck1 -eq $false -Or $folderCheck2 -eq $false){
    Write-Host "SQL 2012 Standard and/or SQL 2012 SP3 folders not found."
    Write-Host "Please paste those folders from the DynaLync Install Files to the _PLACEHOLDER locations"
    throw
}
Else{
Write-Host $separator
Write-Host "Beginning SQL 2012 Express Installation..."
Write-Host $separator

Set-Location -Path ..\SQL_2012_Standard\
Start-Process .\Setup.exe /QS /ConfigurationFile=$configLocation /PID="11111-00000-00000-00000-00000"
Write-Host "SQL Express installation complete"
Write-Host $separator

Write-Host "Installing SQL 2012 Service Pack 3"
Set-Location -Path ..\SQL_2012_ServicePack3\
Start-Process msiexec.exe -ArgumentList '/I SQLServer2012SP3-KB3072779-x64-ENU.exe /qs /IAcceptSQLServerLicenseTerms' -Wait
Write-Host "SP3 for SQL 2012 installation complete"
Write-Host $separator
}
