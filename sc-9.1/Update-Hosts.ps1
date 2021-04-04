$ScriptRoot = "C:\Scripts\sc-9.1"
$allparameters = Import-PowerShellDataFile $ScriptRoot\parameters.psd1
$instancessitecore = @(
    $allparameters.ContentManagementSiteName,             
    $allparameters.ReportingSiteName,                       
    $allparameters.ProcessingSiteName,                
    $allparameters.ReferenceDateSiteName,                  
    $allparameters.IdentityServerSiteName,                 
    $allparameters.XP1MarketingAutomationSiteName,          
    $allparameters.XP1MarketingAutomationReportingSiteName, 
    $allparameters.XP1ClientCertificateName,               
    $allparameters.XP1CollectionSitename,                   
    $allparameters.XP1CollectionSearchSitename,             
    $allparameters.XP1CortexProcessingSitename,            
    $allparameters.XP1CortexReportingSitename
)
$IpSitecore = $allparameters.cmprivateIPAddress
$solrip = $allparameters.solrprivateIPAddress
$solrhostname = $allparameters.solrvmName
$hostFileName = "c:\\windows\system32\drivers\etc\hosts"
$vmname = (Get-ComputerInfo).CsDNSHostName
if ($vmname -like "cd*") {
    foreach ($instance in $instancessitecore) {
        Write-Host "Updating host file"
        "`r`n$IpSitecore`t$instance" | Add-Content $hostFileName
    }
    Write-Host "Adding Solr host"
    "`r`n$solrip`t$solrhostname" | Add-Content $hostFileName
}
elseif ($vmname -eq $allparameters.cmvmName) {
    Write-Host "Adding Solr host"
    "`r`n$solrip`t$solrhostname" | Add-Content $hostFileName
}