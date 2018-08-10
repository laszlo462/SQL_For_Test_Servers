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
    $sqlSetupPath = $fullPath.Trim("*") + "setup.exe"
    Write-Host "Setup.exe found at " $sqlSetupPath -ForegroundColor Green
}

Write-Host "Please select SQL setup folder" -ForegroundColor Yellow
GetSQLSource
