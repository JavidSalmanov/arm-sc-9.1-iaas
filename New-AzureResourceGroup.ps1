Param(
    [string] $ResourceGroupName,
    [switch] $UploadArtifacts,
    [string] $StorageAccountName,
    [string] $StorageContainerName = 'sc9x',
    [string] $TemplateFile = "$PSScriptRoot\main.json",
    [string] $ArtifactStagingDirectory = '.',
    [string] $DSCSourceFolder = 'DSC',
    [switch] $ValidateOnly
)
$OptionalParameters = New-Object -TypeName Hashtable
$allparameters = Import-PowerShellDataFile $PSScriptRoot\parameters.psd1
$allparameters
$ResourceGroupName = $allparameters.ResourceGroupName
$ResourceGroupLocation = $allparameters.ResourceGroupLocation
$parameters = @{
    sqlType                    = $allparameters.sqlType
    sqlServerName              = $allparameters.sqlServerName
    SqlAdminUser               = $allparameters.SqlAdminUser
    SqlAdminPassword           = $allparameters.SqlAdminPassword
    SqlvmAdminPassword         = $allparameters.SqlvmAdminPassword
    sqlprivateIPAddress        = $allparameters.sqlprivateIPAddress

    cdNSGName                  = $allparameters.cdNSGName
    cmNSGName                  = $allparameters.cmNSGName

    vnetName                   = $allparameters.vnetName
    VnetPrefix                 = $allparameters.VnetPrefix

    cmSubnetName               = $allparameters.cmSubnetName
    cdSubnetName               = $allparameters.cdSubnetName
    cmSubnetPrefix             = $allparameters.cmSubnetPrefix
    cdSubnetPrefix             = $allparameters.cdSubnetPrefix
    cmprivateIPAddress         = $allparameters.cmprivateIPAddress
    cdprivateIPAddress         = $allparameters.cdprivateIPAddress

    loadBalancerName           = $allparameters.loadBalancerName
    lbPipName                  = $allparameters.lbPipName
    lbPipDNSName               = $allparameters.lbPipDNSName

    cmvmPIP                    = $allparameters.cmvmPIP
    cmvmDNSPIP                 = $allparameters.cmvmDNSPIP
    cmvmName                   = $allparameters.cmvmName
    cmvmScriptScriptFileName   = $allparameters.cmvmScriptScriptFileName
    cmvmSize                   = $allparameters.cmvmSize

    cdNodeCount                = $allparameters.cdNodeCount
    cdvmName                   = $allparameters.cdvmName
    cdvmScriptScriptFileName   = $allparameters.cdvmScriptScriptFileName
    availabilitySetName        = $allparameters.availabilitySetName
    AdminUsername              = $allparameters.AdminUsername
    AdminPassword              = $allparameters.AdminPassword

    solrvmName                 = $allparameters.solrvmName
    solrprivateIPAddress       = $allparameters.solrprivateIPAddress
    solrvmScriptScriptFileName = $allparameters.solrvmScriptScriptFileName
}
#Create Zip
if (Test-Path $PSScriptRoot\sc.zip) {
    Remove-Item $PSScriptRoot\sc.zip -Force
    Copy-Item $PSScriptRoot\parameters.psd1 -Destination $PSScriptRoot\sc-9.1\parameters.psd1
    Compress-Archive -Path $PSScriptRoot\sc-9.1 -DestinationPath $PSScriptRoot\sc.zip
    Remove-Item -Path $PSScriptRoot\sc-9.1\parameters.psd1
}
else {
    Copy-Item $PSScriptRoot\parameters.psd1 -Destination $PSScriptRoot\sc-9.1\parameters.psd1
    Compress-Archive -Path $PSScriptRoot\sc-9.1 -DestinationPath $PSScriptRoot\sc.zip
    Remove-Item -Path $PSScriptRoot\sc-9.1\parameters.psd1
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}

if ($UploadArtifacts) {
    # Convert relative paths to absolute paths if needed
    $ArtifactStagingDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $ArtifactStagingDirectory))
    $DSCSourceFolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $DSCSourceFolder))

    # Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present

    $JsonParameters = $parameters
    $ArtifactsLocationName = '_artifactsLocation'
    $ArtifactsLocationSasTokenName = '_artifactsLocationSasToken'
    $OptionalParameters[$ArtifactsLocationName] = $JsonParameters | Select-Object -Expand $ArtifactsLocationName -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore
    $OptionalParameters[$ArtifactsLocationSasTokenName] = $JsonParameters | Select-Object -Expand $ArtifactsLocationSasTokenName -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore
    # Create DSC configuration archive
    if (Test-Path $DSCSourceFolder) {
        $DSCSourceFilePaths = @(Get-ChildItem $DSCSourceFolder -File -Filter '*.ps1' | ForEach-Object -Process { $_.FullName })
        foreach ($DSCSourceFilePath in $DSCSourceFilePaths) {
            $DSCArchiveFilePath = $DSCSourceFilePath.Substring(0, $DSCSourceFilePath.Length - 4) + '.zip'
            Publish-AzureRmVMDscConfiguration $DSCSourceFilePath -OutputArchivePath $DSCArchiveFilePath -Force -Verbose
        }
    }

    # Create a storage account name if none was provided
    if ($StorageAccountName -eq '') {
        $StorageAccountName = 'stage' + ((Get-AzureRmContext).Subscription.SubscriptionId).Replace('-', '').substring(0, 19)
    }

    $StorageAccount = (Get-AzureRmStorageAccount | Where-Object { $_.StorageAccountName -eq $StorageAccountName })

    # Create the storage account if it doesn't already exist
    if ($null -eq $StorageAccount) {
        $StorageResourceGroupName = 'ARM_Deploy_Staging'
        New-AzureRmResourceGroup -Location $ResourceGroupLocation -Name $StorageResourceGroupName -Force
        $StorageAccount = New-AzureRmStorageAccount -StorageAccountName $StorageAccountName -Type 'Standard_LRS' -ResourceGroupName $StorageResourceGroupName -Location $ResourceGroupLocation
    }

    # Generate the value for artifacts location if it is not provided in the parameter file
    if ($null -eq $OptionalParameters[$ArtifactsLocationName]) {
        $OptionalParameters[$ArtifactsLocationName] = $StorageAccount.Context.BlobEndPoint + $StorageContainerName
    }

    # Copy files from the local storage staging location to the storage account container
    New-AzureStorageContainer -Name $StorageContainerName -Context $StorageAccount.Context -ErrorAction SilentlyContinue *>&1

    $ArtifactFilePaths = Get-ChildItem $ArtifactStagingDirectory -Recurse -File | ForEach-Object -Process { $_.FullName }
    foreach ($SourcePath in $ArtifactFilePaths) {
        Set-AzureStorageBlobContent -File $SourcePath -Blob $SourcePath.Substring($ArtifactStagingDirectory.length + 1) `
            -Container $StorageContainerName -Context $StorageAccount.Context -Force
    }

    # Generate a 4 hour SAS token for the artifacts location if one was not provided in the parameters file
    if ($null -eq $OptionalParameters[$ArtifactsLocationSasTokenName]) {
        $OptionalParameters[$ArtifactsLocationSasTokenName] = ConvertTo-SecureString -AsPlainText -Force `
        (New-AzureStorageContainerSASToken -Container $StorageContainerName -Context $StorageAccount.Context -Permission r -ExpiryTime (Get-Date).AddHours(4))
    }
}

# Create the resource group only when it doesn't already exist
if ($null -eq (Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -ErrorAction SilentlyContinue)) {
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force -ErrorAction Stop
}

if ($ValidateOnly) {
    $ErrorMessages = Format-ValidationOutput (Test-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName `
            -TemplateFile $TemplateFile `
            -TemplateParameterObject $parameters `
            @OptionalParameters)
    if ($ErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}
else {
    New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFile `
        -TemplateParameterObject $parameters `
        @OptionalParameters `
        -Force -Verbose `
        -ErrorVariable ErrorMessages
    if ($ErrorMessages) {
        Write-Output '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }
}
Remove-Item $PSScriptRoot\sc.zip
