# ------------------ Parameters
Param (                    
        [string]$hostName                  = "", 
        [string]$userName                  = "", 
        [string]$password                  = "",
        [string]$authLoginDomain           = "local",
        [string]$minFWversion              = '2.00',
        [string]$iloFWlocation             = "C:\Users\admin\Desktop\Firmware\ilo5.bin"
      )





if ($hostName -or $userName -or $password)
{
    ### Connect to OneView
    $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
    $cred           = New-Object System.Management.Automation.PSCredential  -ArgumentList $userName, $securePassword


    write-host -ForegroundColor Cyan "---- Connecting to OneView --> $hostName"
    $OVconnection   = Connect-OVMgmt -Hostname $hostName -loginAcknowledge:$true -AuthLoginDomain $authLoginDomain -Credential $cred



    # ----------------- Get list of servers whose iLO FW  less than 2.00
    $serverList                 = Get-OVserver | where mpFirmwareVersion -le $minFWversion
    if ($serverList)
    {
        foreach ($s in $serverList)
        {
            $serverName         = $s.Name 
            $iloSession         = $s | Get-OViloSso -IloRestSession
            $authToken          = $iloSession.'X-Auth-Token'
            $iloIP              = $s.mpHostInfo.mpIpAddresses[0].address
            

            write-host -foreground CYAN "Updating iLO firmware of server $serverName...."
            #### Connect to iLO
            # Using AuthToken works ONLY for iLO5

            $iLOConnection      = Connect-HPEiLO -Address $iloIP -XAuthToken $authToken -DisableCertificateAuthentication
            Update-HPEiLOFirmware -Connection $iLOConnection -Location $iloFWlocation  -UploadTimeout 700
            
        }
    }
    else
    {
        write-host -foreground YELLOW "No server with iLO firmware lower than $minFWversion. Spkip updating iLO FW....."
    }
}
else
{
    write-host -foreground YELLOW "No OneView IP nor userName nor password specified. Exit the script"
}
