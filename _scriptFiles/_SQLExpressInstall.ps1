# Author: Steve Szabo
# Date: 07/18/2018
# Installs SQL Server 2012 Express as per IBE defaults + Service Pack 3, for IBE test server deployment.
# Version 2.0 - 081018
[CmdletBinding()]
Param()
# Loading assemblies for Windows Forms
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

# Instantiate shell object for explorer folder interaction
$folderObject = New-Object -comObject Shell.Application

# Initializing variables
$scriptPath = $PSScriptRoot
Set-Location -Path $scriptPath
$configLocation = $scriptPath + "\2012ExpressConfigurationFile.ini"
$sqlArguments = '/PID="11111-00000-00000-00000-00000" /ConfigurationFile=' + $configLocation
$sqlSP3Arguments = '/qs /IAcceptSQLServerLicenseTerms /Action=Patch'
$separator = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
$logfile = "C:\Service\SQL-Test-Server-Install-$(get-date -f yyyyMMddTHHmmss).txt"
$productType

# Import ps-menu module
Import-Module -DisableNameChecking -Name .\ps-menu.psm1

# Functions
function Set-ProductType{
    [CmdletBinding()]
    Param($productType)
    $productType = menu @("DynaLync Lung", "Incidental", "IBE B.08")
}
function GetSQLSource{
    $pathCheck = $false
    while($pathCheck -eq $false){
        $sqlStandardSource = $folderObject.BrowseForFolder(0, "Please select SQL_2012_Standard folder", 0)
        if ($sqlStandardSource -eq $null){
            throw "User pressed cancel..."
        }
        elseif ($sqlStandardSource -ne $null){
            $fullPath = $sqlStandardSource.self.Path + "\*"
            Write-Host "Checking..." $fullPath.Trim("*")
            $pathCheck = Test-Path -Path $fullPath -Include setup.exe
        }
    }
    $global:sqlSetupPath = $fullPath.Trim("*") + "setup.exe"
    Write-Host "SQL 2012 Setup.exe found at " $sqlSetupPath -ForegroundColor Green
}

function GetSP3Source{
    $pathCheck = $false
    while($pathCheck -eq $false){
        $sqlSp3Source = $folderObject.BrowseForFolder(0, "Please select SQL_2012_ServicePack3 folder", 0)
        if ($sqlSp3Source -eq $null){
            throw "User pressed cancel..."
        }
        elseif ($sqlSp3Source -ne $null){
            $fullPath = $sqlSp3Source.self.Path + "\*"
            Write-Host "Checking..." $fullPath.Trim("*")
            $pathCheck = Test-Path -Path $fullPath -Include SQLServer2012SP3-KB3072779-x64-ENU.exe
        }
    }
    $global:sqlSp3Path = $fullPath.Trim("*") + "SQLServer2012SP3-KB3072779-x64-ENU.exe"
    Write-Host "SQL 2012 SP3 installer found at " $sqlSp3Path -ForegroundColor Green
}

function DotNet3Install{
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

function SetSQLMixedMode{
    #### Registry key change to switch SQL to mixed-mode auth after install.
    #### This is done to prevent insecure passing of /SAPWD parameter during install script arguments.
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQLServer"
    $name = "LoginMode"
    $value = "2"

    if (Test-Path $registryPath){
        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
        Write-Host "Complete!" -ForegroundColor Green
        Write-Host "`n"
    }else{
        Write-Host "Unable to find registry key to set SQL Login mode, please do so manually via GUI after rebooting..." -ForegroundColor Red
    }
}

function SetSQLTCPPort{
    #### Reconfigure TCP port to that of the typical 2012 standard install.
    # Needed to reload current Powershell profile to make the sqlps module available, as it was installed with SQL within the same session.
    Start-Transcript -Path $logfile -Append
    Import-Module -DisableNameChecking sqlps
    $MachineObject = New-Object ('Microsoft.SqlServer.Management.Smo.WMI.ManagedComputer') "localhost"
    $instance = $MachineObject.getSmoObject(
        "ManagedComputer[@Name='localhost']/" +
        "ServerInstance[@Name='SQLEXPRESS']"
    )

    $instance.ServerProtocols['Tcp'].IPAddresses['IPALL'].IPAddressProperties['TcpPort'].Value = "1433"
    $instance.ServerProtocols['Tcp'].IPAddresses['IPALL'].IPAddressProperties['TcpDynamicPorts'].Value = ""
    $instance.ServerProtocols['Tcp'].Alter()

    $tcpPort = $instance.ServerProtocols['Tcp'].IPAddresses['IPALL'].IPAddressProperties['TcpPort'].Value
    Write-Host "TCP Port for IPALL set to" $tcpPort -ForegroundColor Green
    Stop-Transcript
}

function InstallSQL{
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
}

function InstallSP3{
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
    Write-Host $separator
}

function ScriptLoad{
    Write-Host "#"
    Write-Host "##"
    Write-Host "###"
    Write-Host "####"
}

function Set-DLLDatabases{
    Invoke-Sqlcmd -InputFile ".\create_DLL_Databases.sql" -Verbose
}

function Set-DLIDatabases{
    Invoke-Sqlcmd -InputFile ".\create_DLI_Databases.sql" -Verbose
}

# Begin Script
Start-Transcript -Path $logfile
ScriptLoad
Write-Host "`n"
Write-Host "Please select the product that this test server will be used for:" -ForegroundColor Yellow
Set-ProductType
Write-Host "`n"
Write-Host "Please browse to SQL_2012_Standard folder" -ForegroundColor Yellow
GetSQLSource
Write-Host "`n"
Write-Host "Please browse to SQL_2012_ServicePack3 folder" -ForegroundColor Yellow
GetSP3Source
Write-Host "`n"

Write-Host ".NET 3.5 Prerequisite Check..." -ForegroundColor Yellow
$netFX3dir = "C:\Windows\Microsoft.NET\Framework\v3.5"
$exists = Test-Path -Path $netFX3dir
if ($exists){
    Write-Host "Success! .NET 3.5 already installed" -ForegroundColor Green
}else{
    Write-Host ".Net 3.5 not found, performing automatic install..."
    if (Test-Path -Path ..\..\DotNet3){
        Set-Location ..\..\DotNet3\_scriptFiles
        DotNet3Install
    }else{
        Write-Host "DotNet3 folder not found.  Please make sure you've downloaded the latest version of the LCS Toolbox release!" -ForegroundColor Red
        throw "Error, check source files"
        Stop-Transcript
    }
}

#Checking that SQL install folder functions defined variables correctly before attempting install.
If ($sqlSetupPath -eq $null -Or $sqlSp3Path -eq $null){
    Write-Host "SQL 2012 Standard and/or SQL 2012 SP3 folders not found or something went wrong.  Please exit the script and try again."
    Stop-Transcript
    throw
}Else{
    Write-Host $separator
    Write-Host "Beginning SQL 2012 Express Installation..."
    Write-Host $separator
    InstallSQL

    Write-Host "Installing SQL 2012 Service Pack 3..."
    Write-Host $separator
    InstallSP3

    # Create New PSSession locally so SetSQLTCPPort function is able to Import-Module that's not available within this session.
    $session = New-PSSession
    Write-Host "Configuring correct TCP Port number"
    Stop-Transcript
    Invoke-Command -Session $session -ScriptBlock ${function:SetSQLTCPPort}
    Write-Host "`n"

    Start-Transcript -Path $logfile -Append
    Write-Host "Configuring databases for product type..."
    Write-Host "`n"
    switch ($productType){
        "DynaLync Lung" {Set-DLLDatabases; break}
        "Incidental" {Set-DLIDatabases; break}
        "IBE B.08"{Write-Host "Setting SQL Auth to mixed mode..."
        SetSQLMixedMode
        Write-Host "`n"
        }
    }

    Stop-Transcript
    Write-Host "*********" -ForegroundColor Green
    Read-Host "SQL Express Test Server installation complete.  Reboot required....press Enter to reboot"
    Restart-Computer
    exit
}
