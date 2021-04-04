param(
    [string] $sitecoreInstanceType,
    [string] $SCInstallRoot = "D:\artifacts"

)
$ScriptRoot = "C:\Scripts\sc-9.1"
$allparameters = Import-PowerShellDataFile $ScriptRoot\parameters.psd1
if ($allparameters.sqlType -eq 'PaaS') {
    $SqlServerFQDN = ("{0}{1}" -f $allparameters.sqlServerName, ".database.windows.net")
    $SqlAdminUser = $allparameters.SqlAdminUser
}
elseif ($allparameters.sqlType -eq 'IaaS') {
    $SqlServerFQDN = $allparameters.sqlServerName
    $SqlAdminUser = "sa"
}

$instancejson = ("{0}{1}" -f $sitecoreInstanceType, ".json")
$LicenseFile = "$ScriptRoot\license\license.xml"
$XConnectCollectionSearchService = ("{0}{1}" -f "https://", $allparameters.XP1CollectionSearchSitename)
$XConnectCollectionService = ("{0}{1}" -f "https://", $allparameters.XP1CollectionSitename)
$XConnectReferenceDataService = ("{0}{1}" -f "https://", $allparameters.ReferenceDateSiteName)
$ProcessingService = ("{0}{1}" -f "https://", $allparameters.ProcessingSiteName)
$ReportingService = ("{0}{1}" -f "https://", $allparameters.ReportingSiteName)
$CortexReportingService = ("{0}{1}" -f "https://", $allparameters.XP1CortexReportingSitename)
$MarketingAutomationOperationsService = ("{0}{1}" -f "https://", $allparameters.XP1MarketingAutomationSiteName)
$MarketingAutomationReportingService = ("{0}{1}" -f "https://", $allparameters.XP1MarketingAutomationReportingSiteName)
$PasswordRecoveryUrl = ("{0}{1}" -f "https://", $allparameters.ContentManagementSiteName)
$SitecoreIdentityAuthority = ("{0}{1}" -f "https://", $allparameters.IdentityServerSiteName)
$MachineLearningServerUrl = ""
$AllowedCorsOrigins = ("{0}{1}" -f "https://", $allparameters.ContentManagementSiteName)
$SitecoreXP1CDPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9* rev. * (OnPrem)_cd.scwdp.zip").FullName
$SitecoreXP1CMPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9* rev. * (OnPrem)_cm.scwdp.zip").FullName
$SitecoreXP1RepPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9* rev. * (OnPrem)_rep.scwdp.zip").FullName
$SitecoreXP1PrcPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9* rev. * (OnPrem)_prc.scwdp.zip").FullName
$XP1CollectionPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9* rev. * (OnPrem)_xp1collection.scwdp.zip").FullName
$XP1CollectionSearchPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9* rev. * (OnPrem)_xp1collectionsearch.scwdp.zip").FullName
$XP1MarketingAutomationPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9* rev. * (OnPrem)_xp1marketingautomation.scwdp.zip").FullName
$XP1MarketingAutomationReportingPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9* rev. * (OnPrem)_xp1marketingautomationreporting.scwdp.zip").FullName
$XP1ReferenceDataPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9* rev. * (OnPrem)_xp1referencedata.scwdp.zip").FullName
$XP1CortexReportingPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9* rev. * (OnPrem)_xp1cortexreporting.scwdp.zip").FullName
$XP1CortexProcessingPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9* rev. * (OnPrem)_xp1cortexprocessing.scwdp.zip").FullName
$IdentityServerPackage = (Get-ChildItem "$SCInstallRoot\Sitecore.IdentityServer * rev. * (OnPrem)_identityserver.scwdp.zip").FullName

# Parameter Object
$parameters = @{
    XConnectCert                            = $allparameters.XConnectCert
    IdentityServerCertificateName           = $allparameters.IdentityServerSiteName
    CollectionCert                          = $allparameters.CollectionCert
    Path                                    = "$ScriptRoot\JSON\$instancejson"
    CertificateName                         = $allparameters.XP1ClientCertificateName
    SitecoreAdminPassword                   = $allparameters.SitecoreAdminPassword
    LicenseFile                             = $LicenseFile
    SolrUrl                                 = $allparameters.SolrUrl
    SolrRoot                                = $allparameters.SolrRoot
    SolrService                             = $allparameters.SolrService
    Prefix                                  = $allparameters.Prefix
    SqlServer                               = $SqlServerFQDN
    SqlAdminUser                            = $SqlAdminUser
    SqlAdminPassword                        = $allparameters.SqlAdminPassword
    IdentityServerSiteName                  = $allparameters.IdentityServerSiteName
    XP1CollectionSearchSitename             = $allparameters.XP1CollectionSearchSitename
    XP1MarketingAutomationSitename          = $allparameters.XP1MarketingAutomationSiteName
    XP1MarketingAutomationReportingSitename = $allparameters.XP1MarketingAutomationReportingSiteName
    XP1ReferenceDataSitename                = $allparameters.ReferenceDateSiteName
    XP1CortexProcessingSitename             = $allparameters.XP1CortexProcessingSitename
    XP1CortexReportingSitename              = $allparameters.XP1CortexReportingSitename
    XP1CollectionSitename                   = $allparameters.XP1CollectionSitename
    SitecoreXP1CDSitename                   = $allparameters.ContentDeliverySiteName
    SitecoreXP1CMSitename                   = $allparameters.ContentManagementSiteName
    SitecoreXP1RepSitename                  = $allparameters.ReportingSiteName
    SitecoreXP1PrcSitename                  = $allparameters.ProcessingSiteName
    XConnectCollectionService               = $XConnectCollectionService
    XConnectReferenceDataService            = $XConnectReferenceDataService
    XConnectCollectionSearchService         = $XConnectCollectionSearchService
    MarketingAutomationOperationsService    = $MarketingAutomationOperationsService
    MarketingAutomationReportingService     = $MarketingAutomationReportingService
    CortexReportingService                  = $CortexReportingService
    MachineLearningServerUrl                = $MachineLearningServerUrl
    SitecoreIdentityAuthority               = $SitecoreIdentityAuthority
    ProcessingService                       = $ProcessingService
    ReportingService                        = $ReportingService
    XP1CollectionPackage                    = $XP1CollectionPackage
    XP1CollectionSearchPackage              = $XP1CollectionSearchPackage
    XP1CortexProcessingPackage              = $XP1CortexProcessingPackage
    XP1MarketingAutomationPackage           = $XP1MarketingAutomationPackage
    XP1MarketingAutomationReportingPackage  = $XP1MarketingAutomationReportingPackage
    XP1ReferenceDataPackage                 = $XP1ReferenceDataPackage
    XP1CortexReportingPackage               = $XP1CortexReportingPackage
    SitecoreXP1CDPackage                    = $SitecoreXP1CDPackage
    SitecoreXP1CMPackage                    = $SitecoreXP1CMPackage
    SitecoreXP1RepPackage                   = $SitecoreXP1RepPackage
    SitecoreXP1PrcPackage                   = $SitecoreXP1PrcPackage
    IdentityServerPackage                   = $IdentityServerPackage
    PasswordRecoveryUrl                     = $PasswordRecoveryUrl
    ClientSecret                            = $allparameters.ClientSecret
    AllowedCorsOrigins                      = $AllowedCorsOrigins
    CollectionSearchCert                    = $allparameters.CollectionSearchCert
    ReferenceDataCert                       = $allparameters.ReferenceDataCert
    MarketingAutomationCert                 = $allparameters.MarketingAutomationCert
    MarketingAutomationReportingCert        = $allparameters.MarketingAutomationReportingCert
    CMCert                                  = $allparameters.CMCert
    CDCert                                  = $allparameters.CDCert
    CortexProcessingCert                    = $allparameters.CortexProcessingCert
    CortexReportingCert                     = $allparameters.CortexReportingCert
    SitecoreXP1PrcCert                      = $allparameters.SitecoreXP1PrcCert
    SitecoreXP1RepCert                      = $allparameters.SitecoreXP1RepCert
    #### PasswordS
    SqlCorePassword                         = $allparameters.SqlCorePassword
    SqlSecurityPassword                     = $allparameters.SqlSecurityPassword
    SqlMarketingAutomationPassword          = $allparameters.SqlMarketingAutomationPassword
    SqlMessagingPassword                    = $allparameters.SqlMessagingPassword
    SqlProcessingPoolsPassword              = $allparameters.SqlProcessingPoolsPassword
    SqlCollectionPassword                   = $allparameters.SqlCollectionPassword
    SqlReferenceDataPassword                = $allparameters.SqlReferenceDataPassword
    SqlProcessingEnginePassword             = $allparameters.SqlProcessingEnginePassword
    SqlReportingPassword                    = $allparameters.SqlReportingPassword
    SqlExmMasterPassword                    = $allparameters.SqlExmMasterPassword
    SqlFormsPassword                        = $allparameters.SqlFormsPassword
    SqlMasterPassword                       = $allparameters.SqlMasterPassword
    SqlWebPassword                          = $allparameters.SqlWebPassword
    SqlProcessingTasksPassword              = $allparameters.SqlProcessingTasksPassword
    EXMCryptographicKey                     = $allparameters.EXMCryptographicKey
    EXMAuthenticationKey                    = $allparameters.EXMAuthenticationKey
}

Install-SitecoreConfiguration @parameters 
