$ScriptRoot = "C:\Scripts\sc-9.1"
$allparameters = Import-PowerShellDataFile $ScriptRoot\parameters.psd1
$certimportpassword = $allparameters.certpassword 
$password = ConvertTo-SecureString -String $certimportpassword -Force -AsPlainText
$certs = Get-ChildItem -Path $PSScriptRoot\certificates -Exclude "ROOT.pfx"
foreach ($cert in $certs) {
    Import-PfxCertificate -FilePath $cert -CertStoreLocation Cert:\LocalMachine\My -Password $password
}
Import-PfxCertificate -FilePath $PSScriptRoot\certificates\ROOT.pfx -CertStoreLocation Cert:\LocalMachine\Root -Password $password