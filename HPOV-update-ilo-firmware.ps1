# ------------------ Parameters
Param (                    
        [string]$hostName                  = "", 
        [string]$userName                  = "", 
        [string]$password                  = "",
        [string]$authLoginDomain           = "local",
        [string]$minFWversion              = '2.00',
        [string]$iloFWlocation             = "C:\Users\admin\Desktop\Firmware\ilo5.bin",
        [switch]$query                                                                      # if specified , then only list of servers 
      )


class server
{
    [string]$name
    [string]$serialNumber
    [string]$iloIP
    [string]$iloFirmware
}


function writeto-Excel($data, $sheetName, $destWorkbook)
{
	if ($destWorkBook)
	{
		if ($data )
		{
			
			$data | Export-Excel -path $destWorkBook  -StartRow $startRow -WorksheetName $sheetName
		}
	}
}


# --------------------------
# Main Entry
# --------------------------
$sheetName          = "Server with iLO FW"
$destWorkBook       = "Server-with-ilo-FW.xlsx"
$startRow           = 1

if ($hostName -or $userName -or $password)
{
    $ValuesArray    = [System.Collections.ArrayList]::new()
    ### Connect to OneView
    $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
    $cred           = New-Object System.Management.Automation.PSCredential  -ArgumentList $userName, $securePassword


    write-host -ForegroundColor Cyan "---- Connecting to OneView --> $hostName"
    $OVconnection   = Connect-hpovMgmt -Hostname $hostName -loginAcknowledge:$true -AuthLoginDomain $authLoginDomain -Credential $cred



    # ----------------- Get list of servers whose iLO FW  less than 2.00
    $serverList                 = Get-hpovserver 
    if ($serverList)
    {
        if (test-path $destWorkBook)
        {
            remove-item -path $destWorkBook
        }

        foreach ($s in $serverList)
        {
            $serverName                 = $s.Name 
            $iloIP                      = $s.mpHostInfo.mpIpAddresses[1].address
            $iloFW                      = $s.mpFirmwareVersion.Split(' ')[0]
            if ($iloFW -le $minFWversion)
            {

                if ($query)
                {
                    $sObj                   = new-object -type server
                    $sObj.name              = $serverName
                    $sObj.iloIP             = $iloIP
                    $sObj.iloFirmware       = $s.mpFirmwareVersion
                    $sObj.serialNumber      = $s.serialNumber
                    $ValuesArray 	        += $sObj
                    $serverName , $iloFW
                }
                else
                {

                    $iloSession         = $s | Get-hpoviloSso -IloRestSession
                    $authToken          = $iloSession.'X-Auth-Token'
                    
                    

                    write-host -foreground CYAN "Updating iLO firmware of server $serverName...."
                    #### Connect to iLO
                    # Using AuthToken works ONLY for iLO5

                    $iLOConnection      = Connect-HPEiLO -Address $iloIP -XAuthToken $authToken -DisableCertificateAuthentication
                    Update-HPEiLOFirmware -Connection $iLOConnection -Location $iloFWlocation  -UploadTimeout 700
                }
            }
        }

        if ($ValuesArray)
        {
            write-host -foreground Cyan " Generating list of servers to be updated --> $destworkBook "
            writeto-Excel -data $ValuesArray -sheetName $sheetName -destworkBook $destWorkBook
        }
        else
        {
            write-host -foreground YELLOW "No server with iLO firmware lower than $minFWversion. Spkip updating iLO FW....."
        }
            
        
    }


    Disconnect-HPOVMgmt
}
else
{
    write-host -foreground YELLOW "No OneView IP nor userName nor password specified. Exit the script"
}
