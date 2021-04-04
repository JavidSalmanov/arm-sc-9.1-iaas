Configuration Main
{

    Param ( 
        [string] $nodeName,
        [string] $scpackage,
        [string] $nodeType

    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DSCResource -ModuleName NetworkingDsc

    Node $nodeName
    {
        File createfolder {
            Type            = 'Directory'
            DestinationPath = 'C:\Scripts'
            Ensure          = "Present"
        }
        xRemoteFile scfiles {
            Uri             = "$scpackage"
            DestinationPath = "C:\Scripts\sc.zip"
            MatchSource     = $true
        }
        archive ZipFile {
            Path        = "C:\Scripts\sc.zip"
            Destination = "C:\Scripts"
            Ensure      = 'Present'
        }
        if ($nodeType -eq 'solr') {
            Firewall AddRule1 {
                Name        = 'Solr'
                DisplayName = 'Solr Port'
                Ensure      = 'Present'
                Enabled     = 'True'
                Profile     = ('Domain', 'Private', 'Public')
                Direction   = 'Inbound'
                LocalPort   = ('8983')
                Protocol    = 'TCP'
            }
        }
        if ($nodeType -eq 'sql') {
            Firewall AddRule1 {
                Name        = 'SQL Server'
                DisplayName = 'SQL Server'
                Ensure      = 'Present'
                Enabled     = 'True'
                Profile     = ('Domain', 'Private', 'Public')
                Direction   = 'Inbound'
                LocalPort   = ('1433')
                Protocol    = 'TCP'
            }
            Firewall AddRule2 {
                Name        = 'SQL Database Management'
                DisplayName = 'SQL Database Management'
                Ensure      = 'Present'
                Enabled     = 'True'
                Profile     = ('Domain', 'Private', 'Public')
                Direction   = 'Inbound'
                LocalPort   = ('1434')
                Protocol    = 'UDP'
            }
        }
    }
}