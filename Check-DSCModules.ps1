$moduleList = @('xPSDesiredStateConfiguration', 'NetworkingDsc')
foreach ($module in $moduleList) {
    if (!(Get-Module $module -ListAvailable)) {
        Write-Host "Installing module: $module"
        Install-Module $module -Force
    }
}