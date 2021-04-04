Param(
    $solrVersion = "7.2.1",
    $installFolder = "c:\solr",
    $solrPort = "8983",
    $solrHost = "solr",
    $solrSSL = $true,
    $nssmVersion = "2.24",
    $JREVersion = "1.8.0_211",
    $javafileurl = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=238729_478a62b7d4e34b78b671c754eaaf38ab",
    $certpass = "1"
)

$JREPath = "C:\Program Files\Java\jre$JREVersion" ## Note that if you're running 32bit java, you will need to change this path
$solrName = "solr-$solrVersion"
$solrRoot = "$installFolder\$solrName"
$nssmRoot = "$installFolder\nssm-$nssmVersion"
$solrPackage = "https://archive.apache.org/dist/lucene/solr/$solrVersion/$solrName.zip"
$nssmPackage = "https://nssm.cc/release/nssm-$nssmVersion.zip"
$downloadFolder = "$env:temp"
$switches = @"
"REBOOT=0"
"INSTALL_SILENT=1"
"AUTO_UPDATE=0"
"WEB_JAVA=1"
"WEB_JAVA_SECURITY_LEVEL=M"
"WEB_ANALYTICS=0"
"EULA=0"
"SPONSORS=0"
"REMOVEOUTOFDATEJRES=1"
"@
if (!(Test-Path $JREVersion)) {
    Start-BitsTransfer -Source $javafileurl -Destination ("{0}{1}" -f $downloadFolder, "\java.exe") -Verbose
    Start-Process ("{0}{1}" -f $downloadFolder, "\java.exe") -ArgumentList $switches -NoNewWindow -Wait
}
## Verify elevated
## https://superuser.com/questions/749243/detect-if-powershell-is-running-as-administrator
$elevated = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
if ($elevated -eq $false) {
    throw "In order to install services, please run this script elevated."
}

function downloadAndUnzipIfRequired {
    Param(
        [string]$toolName,
        [string]$toolFolder,
        [string]$toolZip,
        [string]$toolSourceFile,
        [string]$installRoot
    )

    if (!(Test-Path -Path $toolFolder)) {
        if (!(Test-Path -Path $toolZip)) {
            Write-Host "Downloading $toolName..."
            Start-BitsTransfer -Source $toolSourceFile -Destination $toolZip
        }

        Write-Host "Extracting $toolName to $toolFolder..."
        Expand-Archive $toolZip -DestinationPath $installRoot
    }
}
# download & extract the solr archive to the right folder
$solrZip = "$downloadFolder\$solrName.zip"
downloadAndUnzipIfRequired "Solr" $solrRoot $solrZip $solrPackage $installFolder

# download & extract the nssm archive to the right folder
$nssmZip = "$downloadFolder\nssm-$nssmVersion.zip"
downloadAndUnzipIfRequired "NSSM" $nssmRoot $nssmZip $nssmPackage $installFolder

# Ensure Java environment variable
$jreVal = [Environment]::GetEnvironmentVariable("JAVA_HOME", [EnvironmentVariableTarget]::Machine)
if ($jreVal -ne $JREPath) {
    Write-Host "Setting JAVA_HOME environment variable"
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $JREPath, [EnvironmentVariableTarget]::Machine)
}

# if we're using HTTP
if ($solrSSL -eq $false) {
    # Update solr cfg to use right host name
    if (!(Test-Path -Path "$solrRoot\bin\solr.in.cmd.old")) {
        Write-Host "Rewriting solr config"

        $cfg = Get-Content "$solrRoot\bin\solr.in.cmd"
        Rename-Item "$solrRoot\bin\solr.in.cmd" "$solrRoot\bin\solr.in.cmd.old"
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$solrHost" }
        $newCfg | Set-Content "$solrRoot\bin\solr.in.cmd"
    }
}

# Ensure the solr host name is in your hosts file
if ($solrHost -ne "localhost") {
    $hostFileName = "c:\\windows\system32\drivers\etc\hosts"
    $hostFile = [System.Io.File]::ReadAllText($hostFileName)
    if (!($hostFile -like "*$solrHost*")) {
        Write-Host "Updating host file"
        "`r`n127.0.0.1`t$solrHost" | Add-Content $hostFileName
    }
}

# if we're using HTTPS
if ($solrSSL -eq $true) {
    $certStore = "$solrRoot\server\etc\solr-ssl.keystore.pfx"
    Copy-Item -Path $PSScriptRoot\certificates\solr.pfx -Destination $certStore
    # Update solr cfg to use keystore & right host name
    if (!(Test-Path -Path "$solrRoot\bin\solr.in.cmd.old")) {
        Write-Host "Rewriting solr config"
        $cfg = Get-Content "$solrRoot\bin\solr.in.cmd"
        Rename-Item "$solrRoot\bin\solr.in.cmd" "$solrRoot\bin\solr.in.cmd.old"
        $newCfg = $cfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_KEY_STORE=$certStore" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE_PASSWORD=secret", "set SOLR_SSL_KEY_STORE_PASSWORD=$certpass" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_TRUST_STORE=$certStore" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE_PASSWORD=secret", "set SOLR_SSL_TRUST_STORE_PASSWORD=$certpass" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$solrHost" }
        $newCfg | Set-Content "$solrRoot\bin\solr.in.cmd"
    }
}

# install the service & runs
$svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
if (!($svc)) {
    Write-Host "Installing Solr service"
    &"$installFolder\nssm-$nssmVersion\win64\nssm.exe" install "$solrName" "$solrRoot\bin\solr.cmd" "-f" "-p $solrPort"
    $svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
}
if ($svc.Status -ne "Running") {
    Write-Host "Starting Solr service"
    Start-Service "$solrName"
}
# finally prove it's all working
$protocol = "http"
if ($solrSSL -eq $true) {
    $protocol = "https"
}
New-NetFirewallRule -DisplayName "Allow Solr" -Name "Solr" -Direction Inbound -LocalPort "8983" -Protocol TCP -Enabled True
Invoke-Expression "start $($protocol)://$($solrHost):$solrPort/solr/#/"