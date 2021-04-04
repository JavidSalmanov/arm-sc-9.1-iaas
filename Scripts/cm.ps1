$ScriptRoot = "C:\Scripts\sc-9.1"
Set-Location $ScriptRoot
$allparameters = Import-PowerShellDataFile $ScriptRoot\parameters.psd1
if ($allparameters.sqlType -eq "PaaS") {
    $url = $allparameters.scSqlPaaS  
}
elseif ($allparameters.sqlType -eq "IaaS") {
    $url = $allparameters.scSqlIaaS  
}
Write-Host "Installing SIF..."
& $ScriptRoot\install-sif.ps1
Write-Host "Download Sitecore 9.1 ..."
Write-Host "Update hosts..."
& $ScriptRoot\Update-Hosts.ps1
New-Item D:\artifacts -ItemType Directory 
Start-BitsTransfer -Source $url -Destination "D:\artifacts\Sitecore 9.1.1rev.002459.zip"
Write-Host "Expanding SC archive file..."
Expand-Archive -Path 'D:\artifacts\Sitecore 9.1.1rev.002459.zip' -DestinationPath D:\artifacts\
Write-Host "Installing certificates..."
& $ScriptRoot\Install-Certificates.ps1
Set-Location -Path $ScriptRoot
Write-Host "Installing prerequisites..."
Install-SitecoreConfiguration -Path $ScriptRoot\JSON\Prerequisites.json
$env:Path += ";C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\"
Write-Host "Installing Sitecore..."
powershell -c "$ScriptRoot\Install-Sitecore.ps1 -sitecoreInstanceType 'cm'"
Remove-Item $ScriptRoot\parameters.psd1 -Force
Remove-Item C:\Scripts\sc.zip -Force