Install-PackageProvider -Name NuGet -Force
if (!([bool](Get-Module -Name "SitecoreInstallFramework" -ListAvailable))) {
    Write-Host "Installing 'Sitecore installation framework'..."
    Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2 `
        -InstallationPolicy Trusted
    Install-Module -Name SitecoreInstallFramework -Repository SitecoreGallery
    Update-Module SitecoreInstallFramework -Force -ErrorAction SilentlyContinue
}
else {
    Write-Host "Updating Sitecore Installation Framework module..."
    Update-Module SitecoreInstallFramework -Force -ErrorAction SilentlyContinue
}
Write-Host "Done!" -ForegroundColor "Green"