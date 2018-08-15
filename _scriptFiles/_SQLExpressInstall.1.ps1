# Author: Steve Szabo
# Date: 07/18/2018
# Installs SQL Server 2012 Express as per IBE defaults + Service Pack 3, for IBE test server deployment.
# Version 2.0 - 081018

# Loading assemblies for Windows Forms
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

# Instantiate shell object for explorer folder interaction
$folderObject = New-Object -comObject Shell.Application

# Initializing variables
$ErrorActionPreference = Stop
$scriptFile = $MyInvocation.MyCommand.Definition
$scriptPath = Split-Path -Parent $scriptFile
Set-Location -Path $scriptPath
$configLocation = $scriptPath + "\2012ExpressConfigurationFile.ini"
$sqlArguments = '/PID="11111-00000-00000-00000-00000" /ConfigurationFile=' + $configLocation
$sqlSP3Arguments = '/qs /IAcceptSQLServerLicenseTerms /Action=Patch'
$separator = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

#dot-sourcing external functions
."$scriptPath\Reset-DbaAdmin.ps1"
."$scriptPath\Set-DbaTcpPort.ps1"

# Functions
function GetSQLSource
{
    $pathCheck = $false
    while($pathCheck -eq $false)
    {
        $sqlStandardSource = $folderObject.BrowseForFolder(0, "Please select SQL_2012_Standard folder", 0)
        if ($sqlStandardSource -ne $null)
        {
            $fullPath = $sqlStandardSource.self.Path + "\*"
            Write-Host "Checking..." $fullPath.Trim("*")
            $pathCheck = Test-Path -Path $fullPath -Include setup.exe
        }
    }
    $global:sqlSetupPath = $fullPath.Trim("*") + "setup.exe"
    Write-Host "SQL 2012 Setup.exe found at " $sqlSetupPath -ForegroundColor Green
}

function GetSP3Source
{
    $pathCheck = $false
    while($pathCheck -eq $false)
    {
        $sqlSp3Source = $folderObject.BrowseForFolder(0, "Please select SQL_2012_ServicePack3 folder", 0)
        if ($sqlSp3Source -ne $null)
        {
            $fullPath = $sqlSp3Source.self.Path + "\*"
            Write-Host "Checking..." $fullPath.Trim("*")
            $pathCheck = Test-Path -Path $fullPath -Include SQLServer2012SP3-KB3072779-x64-ENU.exe
        }
    }
    $global:sqlSp3Path = $fullPath.Trim("*") + "SQLServer2012SP3-KB3072779-x64-ENU.exe"
    Write-Host "SQL 2012 SP3 installer found at " $sqlSp3Path -ForegroundColor Green
}

function DotNet3Install
{
    Write-Host "Installing 7-zip..." -ForegroundColor Green
    Start-Process msiexec.exe -ArgumentList '/i 7z1805-x64.msi /qn' -Wait -NoNewWindow
    Set-Alias 7z "C:\Program Files\7-Zip\7z.exe"
    Write-Host "`n"
    Write-Host "Extracting Server 2012 sxs source files..." -ForegroundColor Green
    7z x .\sxs.zip -y
    $sxsPath = $PWD.Path + "\sxs"

    Write-Host "`n"
    Write-Host "Enabling .NET 3.5 features..." -ForegroundColor Green
    Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All -Source "$sxsPath" -LimitAccess

    Write-Host "`n"
    Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    Write-Host "Complete.  If any errors occured, you may try installation via the Add Features GUI and adding the source sxs directory, found here:"
    Write-Host $sxsPath -ForegroundColor Yellow
    Write-Host "`n"
}

Write-Host ".NET 3.5 Prerequisite Check..."
$netFX3dir = "C:\Windows\Microsoft.NET\Framework\v3.5"
$exists = Test-Path -Path $netFX3dir
if ($exists)
{
    Write-Host "Success! .NET 3.5 already installed" -ForegroundColor Green
}else{
    Write-Host ".Net 3.5 not found, performing automatic install..."
    DotNet3Install
}

Write-Host "Please browse to SQL_2012_Standard folder" -ForegroundColor Yellow
GetSQLSource
Write-Host "`n"
Write-Host "Please browse to SQL_2012_ServicePack3 folder" -ForegroundColor Yellow
GetSP3Source

#Checking that SQL install folder functions defined variables correctly before attempting install.
If ($sqlSetupPath -eq $null -Or $sqlSp3Path -eq $null)
{
    Write-Host "SQL 2012 Standard and/or SQL 2012 SP3 folders not found or something went wrong.  Please exit the script and try again."
    throw
}Else{
    Write-Host $separator
    Write-Host "Beginning SQL 2012 Express Installation..."
    Write-Host $separator

    Set-Location -Path $sqlSetupPath.Trim("setup.exe")
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $sqlSetupPath
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $sqlArguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    Write-Host "stdout: $stdout"
    Write-Host "stderr: $stderr"
    Write-Host "exit code: " + $p.ExitCode

    Write-Host $separator
    Write-Host "SQL Express installation complete.  Error handling is still WIP!"
    Write-Host "Exit code of 0 is good"
    Write-Host "Please reference stderr output above to troubleshoot any potential errors."
    Write-Host $separator

    Write-Host "Installing SQL 2012 Service Pack 3"
    Set-Location -Path $sqlSp3Path.Trim("SQLServer2012SP3-KB3072779-x64-ENU.exe")
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $sqlSp3Path
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $sqlSP3Arguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    Write-Host "stdout: $stdout"
    Write-Host "stderr: $stderr"
    Write-Host "exit code: " + $p.ExitCode

    Write-Host $separator
    Write-Host "SP3 for SQL 2012 installation complete.  Error handling is still WIP!"
    Write-Host "Exit code of 3010 is good"
    Read-Host "Reboot required, press enter to reboot now..."
    Restart-Computer
    exit
}
