# Update iLO firmware in Out-of-band mode
  The script enables you to update iLO firmware of Gen 10 servers when the firmware version is lower than 2.00



## How to get Support
Simple scripts or tools posted on github are provided AS-IS and support is based on best effort provided by the author. If you encounter problems with the script, please submit an issue.

## Prerequisites
The script requires:
   * the latest OneView PowerShell library on PowerShell gallery
   * ImportExcel module from PowerShell gallery
   * Download the latest iLO firmware to a web location

 ## Notes
   * The ilo FW binaries should be located in a http virtual directory for instance http://<webIP>/iloFW 
   * The script uses the Uri to locate the FW Image, for instance http://<webIP>/iloFW/il5.bin

## To install OneView PowerShell library

```
    install-module HPEOneView.5xx  -scope currentuser
    install-module ImportExcel     -scope CurrentUser
    

```

## To get list of servers with ilo Firmware
```
    # For POSH version greater than 5.3
    .\OV-update-iLO-firmware.ps1 -hostname <OV-name> -username <OV-admin> -password <OV-password> -minFWversion '2.00' -query

    # For POSH v 5.2
    .\HPOV-update-iLO-firmware.ps1 -hostname <OV-name> -username <OV-admin> -password <OV-password> -minFWversion '2.00' -query

```
## To update iLO firmware on list of servers

```
    # For POSH version greater than 5.3
    .\OV-update-iLO-firmware.ps1 -hostname <OV-name> -username <OV-admin> -password <OV-password>       -iloFWlocationUri http://<iloIP>/iloFW/ilo5.bin -minFWversion '2.00'

    # For POSH v 5.2
    .\HPOV-update-iLO-firmware.ps1 -hostname <OV-name> -username <OV-admin> -password <OV-password>     -iloFWlocationUri http://<iloIP>/iloFW/ilo5.bin -minFWversion '2.00'

```

    
