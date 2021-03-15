# Update iLO firmware in Out-of-band mode
  The script enables you to update iLO firmware of servers in iLO where the iLO firmware version is lower than 2.00

## Notes
   * Access iLO from OneView
   * Works only for **iLO5 with Authentication token key**. 


## How to get Support
Simple scripts or tools posted on github are provided AS-IS and support is based on best effort provided by the author. If you encounter problems with the script, please submit an issue.

## Prerequisites
The script requires:
   * the latest OneView PowerShell library on PowerShell gallery
   * the latest HPEiLOCmdelts on PowerShell gallery
   * ImportExcel module from PowerShell gallery
   * Download the latest iLO firmware to a local folder

  

## To install OneView PowerShell library and HPEiLOCmdlets

```
    install-module HPEOneView.5xx  -scope currentuser
    install-Module HPEiLOcmdlets   -scope currentuser
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
    .\OV-update-iLO-firmware.ps1 -hostname <OV-name> -username <OV-admin> -password <OV-password> -iloFWlocation c:\ilo5.bin -minFWversion '2.00'

    # For POSH v 5.2
    .\HPOV-update-iLO-firmware.ps1 -hostname <OV-name> -username <OV-admin> -password <OV-password> -iloFWlocation c:\ilo5.bin -minFWversion '2.00'

```

    
