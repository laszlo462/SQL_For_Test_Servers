# Author: Steve Szabo
# Date: 07/18/2018
# Installs SQL Server 2012 Express as per IBE defaults + Service Pack 3, for IBE test server deployment.
# Version 2.0 - 081018

# Loading assemblies for Windows Forms
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

#dot-sourcing external functions
.".\_scriptFiles\Reset-DbaAdmin.ps1"
.".\_scriptFiles\Set-DbaTcpPort.ps1"

# Instantiate shell object for explorer folder interaction
$folderObject = New-Object -comObject Shell.Application

# Initializing initial variables
$scriptFile = $MyInvocation.MyCommand.Definition
$scriptPath = Split-Path -Parent $scriptFile
Set-Location -Path $scriptPath
$configLocation = $scriptPath + "\2012ExpressConfigurationFile.ini"
$folderCheck1 = Test-Path '..\SQL_2012_Standard\'
$folderCheck2 = Test-Path '..\SQL_2012_ServicePack3\'
$sqlArguments = '/PID="11111-00000-00000-00000-00000" /ConfigurationFile=' + $configLocation
$sqlSP3Arguments = '/qs /IAcceptSQLServerLicenseTerms /Action=Patch'
$separator = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

function SourceFileLocation()
{
    Write-Host "Please select SQL_2012_Standard folder location"
    $sqlSetup = $null
    while ($sqlSetup -eq $null)
    {
        try
        {
            $sqlStandardSource = $folderObject.BrowseForFolder(0, "Please select SQL_2012_Standard folder", 0)
            if ($sqlStandardSource -ne $null)
            {
                if (Test-Path -Path $sqlStandardSource.self.Path -Include setup.exe -eq $true)
                {
                    Write-Host "SQL Server 2012 Setup.exe found"
                    $sqlSetup = $sqlStandardSource.self.Path
                }
                else {Write-Host "Setup.exe not found in " $sqlStandardSource.self.Path ", please try again"}
            }
        }
        catch {}
    }
}


#Checking that SQL install folders exist
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
#Start-Process -FilePath "\.setup.exe" -NoNewWindow -PassThru -ArgumentList $sqlArguments -Wait
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = $PWD.Path + "\setup.exe"
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
Set-Location -Path ..\SQL_2012_ServicePack3\
#Start-Process -FilePath "msiexec.exe" -Verb runas -ArgumentList $sqlSP3Arguments -Wait
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = $PWD.Path + "\SQLServer2012SP3-KB3072779-x64-ENU.exe"
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
