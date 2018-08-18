# SQL_For_Test_Servers

LCSToolbox SQL_For_Test_Servers component.  Scripted installation of SQL Server 2012 Express for IBE and/or DLL.

## Requirements
* DynaLync 1.2 Install Files (330149.zip) must be present on the system.
* Complete LCS_Toolbox_RELEASE package must be present for facilitate DotNet3 dependency.

## Instructions for use
1. Run SQLExpressInstall.bat as Administrator.
2. Powershell script will execute and verify .NET 3.5 is present.  If it is not, it will enable this for you.
3. Powershell will then ask you to browse the the SQL_Standard_2012 folder and the SQL_2012_ServicePack3 on the system. (Typically within 330149 install files folder)
4. Powershell can the be left unattended while SQL 2012 Express and SP3 are installed.
5. Post-Install, SQL will be configured for Mixed-Mode auth and TCP ports updated to expected production values.