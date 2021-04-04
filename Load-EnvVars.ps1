param(
    [string] $EnvFilesPath = $PSScriptRoot
)
$variables = @{
    SqlCorePassword                = ${env:SqlCorePassword}
    SqlSecurityPassword            = ${env:SqlSecurityPassword}
    SqlMarketingAutomationPassword = ${env:SqlMarketingAutomationPassword}
    SqlMessagingPassword           = ${env:SqlMessagingPassword}
    SqlProcessingPoolsPassword     = ${env:SqlProcessingPoolsPassword}
    SqlCollectionPassword          = ${env:SqlCollectionPassword}
    SqlReferenceDataPassword       = ${env:SqlReferenceDataPassword}
    SqlProcessingEnginePassword    = ${env:SqlProcessingEnginePassword}
    SqlReportingPassword           = ${env:SqlReportingPassword}
    SqlExmMasterPassword           = ${env:SqlExmMasterPassword}
    SqlFormsPassword               = ${env:SqlFormsPassword}
    SqlMasterPassword              = ${env:SqlMasterPassword}
    SqlWebPassword                 = ${env:SqlWebPassword}
    SqlProcessingTasksPassword     = ${env:SqlProcessingTasksPassword}
    EXMCryptographicKey            = ${env:EXMCryptographicKey}
    EXMAuthenticationKey           = ${env:EXMAuthenticationKey}
    certpassword                   = ${env:certpassword}
    SqlAdminPassword               = ${env:SqlAdminPassword}
    SqlvmAdminPassword             = ${env:SqlvmAdminPassword}
    ResourceGroupLocation          = ${env:ResourceGroupLocation}
    ResourceGroupName              = ${env:ResourceGroupName}
    cdNodeCount                    = ${env:cdNodeCount}
    AdminPassword                  = ${env:AdminPassword}
}
foreach ($var in $variables.Keys) {
    $newvalue = $variables[$var]
    Get-ChildItem -Path $EnvFilesPath -Filter *.pds1 -Recurse | Where-Object { !$PSItem.PSIsContainer } | % { 

        $file = Get-Content $PSItem.FullName
        $containsWord = $file | ForEach-Object { $PSItem -match $var }
        If ($containsWord -contains $true) {
            Add-Content log.txt $PSItem.FullName
            ($file) | ForEach-Object { $PSItem -replace ("{0}{1}{2}" -f '#{', $var, '}#'), $newvalue } | 
            Set-Content $PSItem.FullName
        }
        
    }
}