param(
    [string] $sitecoreInstanceType,
    [string] $SCInstallRoot = "D:\artifacts"

)
$ScriptRoot = "C:\Scripts\sc-9.1"
Set-Location $ScriptRoot
$allparameters = Import-PowerShellDataFile $ScriptRoot\parameters.psd1

# Parameter Object
$parameters = @{
    Path                                    = "$ScriptRoot\JSON\solr.json"
    SolrUrl                                 = $allparameters.SolrUrl
    SolrRoot                                = $allparameters.SolrRoot
    SolrService                             = $allparameters.SolrService
    Prefix                                  = $allparameters.Prefix
}

Install-SitecoreConfiguration @parameters