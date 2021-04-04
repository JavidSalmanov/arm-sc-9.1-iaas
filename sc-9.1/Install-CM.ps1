#$url = "https://scartifact001.blob.core.windows.net/sc91/Sitecore%209.1.1rev.002459.zip?st=2019-07-23T09%3A02%3A47Z&se=2020-07-24T09%3A02%3A00Z&sp=rl&sv=2018-03-28&sr=b&sig=81o5M6qgaPpsdjYPFLI2oDGOxMdq1PSvyJdWCzyt1FA%3D"
$url = "https://scartifact001.blob.core.windows.net/sc91/new-sc.zip?st=2019-08-13T15%3A57%3A18Z&se=2020-08-14T15%3A57%3A00Z&sp=rl&sv=2018-03-28&sr=b&sig=aeJY3FGuohZOXt3c75ajR4FuE%2B8l%2Fgw9kP6I9l8m9us%3D"
Write-Host "Installing SIF..."
& $PSScriptRoot\install-sif.ps1
Write-Host "Download Sitecore 9.1 ..."
New-Item D:\artifacts -ItemType Directory 
Start-BitsTransfer -Source $url -Destination "D:\artifacts\Sitecore 9.1.1rev.002459.zip"
Write-Host "Expanding SC archive file..."
Expand-Archive -Path 'D:\artifacts\Sitecore 9.1.1rev.002459.zip' -DestinationPath D:\artifacts\
Write-Host "Installing certificates..."
& $PSScriptRoot\Install-Certificates.ps1
Write-Host "Installing Solr service..."
& $PSScriptRoot\Install-Solr.ps1
Set-Location -Path $PSScriptRoot
Write-Host "Installing prerequisites..."
Install-SitecoreConfiguration -Path $PSScriptRoot\JSON\Prerequisites.json
$env:Path += ";C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\"
Write-Host "Installing Sitecore..."
powershell -c "$PSScriptRoot\Install-Sitecore.ps1 -sitecoreInstanceType 'cm'"