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

## -------- Workaround for diabling Security certificate
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3, [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12

## -------- End Workaround for diabling Security certificate


function writeto-Excel($data, $sheetName, $destWorkbook)
{
    if ($destWorkBook -and $data)
    {
            
        $data | Export-Excel -path $destWorkBook  -WorksheetName $sheetName
    }
}

function update_firmware($authToken, $iloIP, $iloFWlocationUri)
{

    # ---- Build headers
    $headers = @{}
    $headers.Add('X-Auth-Token', $authToken)
    $headers.add('Content-Type','application/json')
    $headers.add('OData-Version','4.0')

    # ----- Build fw location
    $fwJSON             = "{ `n  `"ImageURI`" : `"$iloFWlocationUri`" `n} `n "
    
    # Locate the FW simpleUpdate Action
    $updateService      = Invoke-RestMethod -Method GET -Headers $headers -uri "http://$iloIP/redfish/v1/UpdateService"
    $target             = $updateService.actions.'#UpdateService.SimpleUpdate'.target
    $targetUri          = "http://$iloIP$target"

    # ---- Perform FW update by POST
    $ret                = Invoke-RestMethod -Method POST -Uri $targetUri -Headers $headers -Body $fwJSON
    $msg                = $ret.error.'@Message.ExtendedInfo'.MessageId

    write-host -ForegroundColor CYAN " Update FW on ilo $iloIP ----> status is $msg"



}


# --------------------------
# Main Entry
# --------------------------
$sheetName          = "Server with iLO FW"
$destWorkBook       = "Server-with-ilo-FW.xlsx"

$ipv4Format         = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

if ($hostName -or $userName -or $password)
{
    $ValuesArray    = [System.Collections.ArrayList]::new()
    ### Connect to OneView
    $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
    $cred           = New-Object System.Management.Automation.PSCredential  -ArgumentList $userName, $securePassword


    write-host -ForegroundColor Cyan "---- Connecting to OneView --> $hostName"
    $OVconnection   = Connect-HPOVMgmt -Hostname $hostName -loginAcknowledge:$true -AuthLoginDomain $authLoginDomain -Credential $cred



    # ----------------- Get list of servers whose iLO FW  less than 2.00
    $serverList                 = Get-HPOVserver  | where generation -eq 'Gen10'
    if ($serverList)
    {
        if (test-path $destWorkBook)
        {
            remove-item -path $destWorkBook
        }

        foreach ($s in $serverList)
        {
            $serverName                 = $s.Name 
            foreach ($a in $s.mpHostInfo.mpIpAddresses)
            {
                $iloIP                  = if ($a.address -match $ipv4Format) {$a.address} else {''}
            }

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
                }
                else
                {

                    $iloSession         = $s | Get-HPOViloSso -IloRestSession
                    $authToken          = $iloSession.'X-Auth-Token'
        
                    if ( ($iloIP) -and ($iloFWlocationUri -like 'http*'))
                    {
                        write-host -foreground CYAN "Updating iLO firmware of server $serverName ...."
                        update_firmware -authToken $authToken -iloIP $iloIP -iloFWlocationUri $iloFWlocationUri
                    }
                    else 
                    {
                        write-host -foreground YELLOW "check ilo IP ---> $iloIP or fw Location URi ---> $iloFWlocationUri"
                    }
                    
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
