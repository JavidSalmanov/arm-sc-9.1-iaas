$allparameters = Import-PowerShellDataFile $PSScriptRoot\parameters.psd1
$parameters = @{
    CollectionCert                   = $allparameters.CollectionCert
    CollectionSearchCert             = $allparameters.CollectionSearchCert
    ReferenceDataCert                = $allparameters.ReferenceDataCert
    MarketingAutomationCert          = $allparameters.MarketingAutomationCert
    MarketingAutomationReportingCert = $allparameters.MarketingAutomationReportingCert
    XConnectCert                     = $allparameters.XConnectCert
    CMCert                           = $allparameters.CMCert
    CortexProcessingCert             = $allparameters.CortexProcessingCert
    CortexReportingCert              = $allparameters.CortexReportingCert
    SitecoreXP1PrcCert               = $allparameters.SitecoreXP1PrcCert
    SitecoreXP1RepCert               = $allparameters.SitecoreXP1RepCert
    Solr                             = $allparameters.Solr
    CertPath                         = "$PSScriptRoot\certificates"
    ExportPassword                   = "1"
    Path                             = "$PSScriptRoot\JSON\createcert.json"
}

Write-Host "Start to create Sitecore and Solr certificates..."
Install-SitecoreConfiguration @parameters
Write-Host "All created certificates:"
Get-ChildItem $parameters.CertPath
Write-Host "`nDone!" -BackgroundColor Black -ForegroundColor Green
#Get-ChildItem Cert:\LocalMachine\my | where FriendlyName -Like "sc91*" |Remove-Item
#Get-ChildItem Cert:\LocalMachine\Root | where FriendlyName -Like "Sitecore Install Framework" |Remove-Item