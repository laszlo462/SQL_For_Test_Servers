[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

$folderObject = New-Object -comObject Shell.Application
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

Write-Host "Please browse to SQL_2012_Standard folder" -ForegroundColor Yellow
GetSQLSource
Write-Host "`n"
Write-Host "`n"
Write-Host "Please browse to SQL_2012_ServicePack3 folder" -ForegroundColor Yellow
GetSP3Source
Write-Host "Testing global variables:" $sqlSetupPath "&" $sqlSp3Path
