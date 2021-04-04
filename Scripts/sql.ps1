$folderpath = "C:\Scripts"
$sqlServerMsiUrl = "https://go.microsoft.com/fwlink/?linkid=853016"
$inifile = "$folderpath\ConfigurationFile.ini"
$ScriptRoot = "C:\Scripts\sc-9.1"
$allparameters = Import-PowerShellDataFile $ScriptRoot\parameters.psd1
$sqlInstacePassword = $allparameters.SqlAdminPassword
$yourusername = ("{0}{1}{2}" -f $allparameters.sqlServerName, "\", $allparameters.SqlAdminUser)
#############################################
#SQL Server
#############################################
$configuration = @"
[OPTIONS]
Action="Install"
ErrorReporting="False"
Quiet="True"
Features="SQLENGINE"
InstanceName="MSSQLSERVER"
InstanceDir="C:\Program Files\Microsoft SQL Server"
SQLSVCAccount="NT AUTHORITY\System"
PBENGSVCACCOUNT = "Authority\NETWORK SERVICE"
SQLSysAdminAccounts="$yourusername"
SECURITYMODE="SQL"
SQLSVCStartupType="Automatic"
AGTSVCACCOUNT="NT AUTHORITY\SYSTEM"
AGTSVCSTARTUPTYPE="Automatic"
RSSVCACCOUNT="NT AUTHORITY\System"
RSSVCSTARTUPTYPE="Automatic"
ISSVCACCOUNT="NT AUTHORITY\System"
ISSVCSTARTUPTYPE="Disabled"
ASCOLLATION="Latin1_General_CI_AS"
SQLCOLLATION="SQL_Latin1_General_CP1_CI_AS"
TCPENABLED="1"
NPENABLED="1"
IAcceptSQLServerLicenseTerms="True"
SAPWD = "$sqlInstacePassword"
"@

Install-PackageProvider -Name NuGet -Force
Install-Module -Name SqlServer -AllowClobber -Force

# Check for Script Directory & file
if (Test-Path "$folderpath") {
    Write-Host "The folder '$folderpath' already exists, will not recreate it."
}
else {
    mkdir "$folderpath"
}
if (Test-Path "$folderpath\ConfigurationFile.ini") {
    Write-Host "The file '$folderpath\ConfigurationFile.ini' already exists, removing..."
    Remove-Item -Path "$folderpath\ConfigurationFile.ini" -Force
}
else {

}
# Create file:
Write-Host "Creating '$folderpath\ConfigurationFile.ini'..."
New-Item -Path "$folderpath\ConfigurationFile.ini" -ItemType File -Value $configuration

Write-Host "Downloading SQL Server 2017..."
Start-BitsTransfer -Source $sqlServerMsiUrl -Destination "$folderpath\setup.exe" -Verbose
Start-Process -FilePath "$folderpath\setup.exe" `
    -ArgumentList "/Action=Download /MediaType=ISO /MediaPath=$folderpath /Verbose /Quiet" `
    -NoNewWindow `
    -Wait
Write-Host "Extracting SQL server files..."
$iso = Get-ChildItem $folderpath\* -Include "*.iso"
$mount = Mount-DiskImage -ImagePath $iso.FullName -PassThru
$volume = ($mount | Get-Volume).DriveLetter
Try {
    if (Test-Path ("{0}{1}" -f $volume, ":\")) {
        Write-Host "about to install SQL Server 2017..." -nonewline
        $fileExe = ("{0}{1}" -f $volume, ":\setup.exe")
        $CONFIGURATIONFILE = "$inifile"
        & $fileExe  /CONFIGURATIONFILE=$CONFIGURATIONFILE
        Write-Host "Done!" -ForegroundColor Green

    }
    else {
        Write-Host "Could not find the media for SQL Server 2017..."
        break
    }
}
catch {
    Write-Host "Something went wrong with the installation of SQL Server 2017, aborting."
    break
}
Dismount-DiskImage -ImagePath $iso.FullName -PassThru
Write-Host "Enable the Contained Database Authentication..."
Invoke-Sqlcmd -ServerInstance "$env:COMPUTERNAME" `
    -Username "sa" `
    -Password $sqlInstacePassword `
    -Query "sp_configure 'contained database authentication', 1; 
GO
RECONFIGURE;
GO" `
    -Verbose
# Configure Firewall settings for SQL
Write-Host "Configuring SQL Server 2017 Firewall settings..."
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound –Protocol TCP –LocalPort 1433 -Action allow
New-NetFirewallRule -DisplayName "SQL Database Management" -Direction Inbound –Protocol UDP –LocalPort 1434 -Action allow
Write-Host "done!" -ForegroundColor Green
#############################################
#SSMS
#############################################
$filepath = "$folderpath\SSMS-Setup-ENU.exe"
if (!(Test-Path $filepath)) {
    Write-Host "Downloading SQL Server 2017 SSMS..."
    $URL = "https://go.microsoft.com/fwlink/?linkid=870039"
    Start-BitsTransfer -Source $URL -Destination $filepath -Verbose
    Write-Host "Done!" -ForegroundColor Green
}
else {
    Write-Host "found the SQL SSMS Installer, no need to download it..."
}
# start the SQL SSMS installer
Write-Host "about to install SQL Server 2017 SSMS..."
$Parms = " /Install /Quiet /Norestart /Logs SQLServerSSMSlog.txt"
$Prms = $Parms.Split(" ")
& "$filepath" $Prms | Out-Null
Write-Host "done!" -ForegroundColor Green
Remove-Item $ScriptRoot\parameters.psd1 -Force
Remove-Item C:\Scripts\sc.zip -Force
