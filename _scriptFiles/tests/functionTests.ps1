#dot-sourcing external functions
."$scriptPath\Reset-DbaAdmin.ps1"
."$scriptPath\Set-DbaTcpPort.ps1"

function SetSQLMixedMode
{
    #### Registry key change to switch SQL to mixed-mode auth after install.
    #### This is done to prevent insecure passing of /SAPWD parameter during install script arguments.
    $registryPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQLServer"
    $name = LoginMode
    $value = "2"

    if (Test-Path $registryPath)
    {
        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
        Write-Host "Complete!" -ForegroundColor Green
        Write-Host "`n"
    }else{
        Write-Host "Unable to find registry key to set SQL Login mode, please do so manually via GUI after rebooting..." -ForegroundColor Red
    }
}

    Write-Host $separator
    Write-Host "SP3 for SQL 2012 installation complete.  Error handling is still WIP!"
    Write-Host "Exit code of 3010 is good"
    #Read-Host "Reboot required, press enter to reboot now..."
    Write-Host $separator
    Read-Host "SP3 install complete.  Forgoing required reboot for testing purposes."

    Read-Host "Setting SQL Auth to mixed mode..." -ForegroundColor Green
    SetSQLMixedMode

    Read-Host "Calling external function to enable SA and reset password..."
    Reset-DbaAdmin -SqlInstance .\SQLEXPRESS
    Write-Host "`n"

    Read-Host "Configuring correct default TCP ports" -ForegroundColor Green
    Set-DbaTcpPort -SqlInstance .\SQLEXPRESS -Port 1433
    Write-Host "`n"