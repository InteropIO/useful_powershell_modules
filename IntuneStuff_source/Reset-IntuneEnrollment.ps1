﻿function Reset-IntuneEnrollment {
    <#
    .SYNOPSIS
    Function for resetting device Intune management enrollment.

    .DESCRIPTION
    Function for resetting device Intune management enrollment.

    It will:
     - check actual Intune status on device
     - reset Hybrid AzureAD join
     - remove device records from Intune
     - remove Intune enrollment data and invoke re-enrollment

    .PARAMETER computerName
    (optional) Name of the computer.

    .EXAMPLE
    Reset-IntuneEnrollment

    .EXAMPLE
    Reset-IntuneEnrollment -computerName PC-01

    .NOTES
    # How MDM (Intune) enrollment works https://techcommunity.microsoft.com/t5/intune-customer-success/support-tip-understanding-auto-enrollment-in-a-co-managed/ba-p/834780
    #>

    [CmdletBinding()]
    [Alias("Repair-IntuneEnrollment", "Reset-IntuneJoin", "Invoke-IntuneEnrollmentReset", "Invoke-IntuneEnrollmentRepair")]
    param (
        [string] $computerName = $env:COMPUTERNAME
    )

    $ErrorActionPreference = "Stop"

    if (!(Get-Module "Microsoft.Graph.Intune" -ListAvailable)) {
        throw "Module Microsoft.Graph.Intune is missing (use Install-Module Microsoft.Graph.Intune to get it)"
    }

    #region check Intune enrollment result
    Write-Host "Checking actual Intune enrollment status" -ForegroundColor Cyan
    if (Get-IntuneEnrollmentStatus -computerName $computerName) {
        $choice = ""
        while ($choice -notmatch "^[Y|N]$") {
            $choice = Read-Host "It seems computer $computerName is correctly enrolled to Intune. Continue? (Y|N)"
        }
        if ($choice -eq "N") {
            break
        }
    }
    #endregion check Intune enrollment result

    #region reset Hybrid AzureAD if necessary
    if (!(Get-HybridADJoinStatus -computerName $computerName)) {
        Write-Host "Resetting Hybrid AzureAD connection, because there is some problem" -ForegroundColor Cyan
        Reset-HybridADJoin -computerName $computerName

        Write-Host "Waiting" -ForegroundColor Cyan
        Start-Sleep 10
    } else {
        Write-Verbose "Hybrid Join status of the $computerName is OK"
    }
    #endregion reset Hybrid AzureAD if necessary

    #region remove computer record from Intune
    Write-Host "Removing $computerName records from Intune" -ForegroundColor Cyan
    # to discover cases when device is in Intune named as GUID_date
    if (Get-Command Get-ADComputer -ErrorAction SilentlyContinue) {
        $ADObj = Get-ADComputer -Filter "Name -eq '$computerName'" -Properties Name, ObjectGUID
    } else {
        Write-Verbose "AD module is missing, unable to obtain computer GUID"
    }

    #region get Intune data
    Connect-MSGraph2

    $IntuneObj = @()

    # search device by name
    $IntuneObj += Get-IntuneManagedDevice -Filter "DeviceName eq '$computerName'"

    # search device by GUID
    if ($ADObj.ObjectGUID) {
        # because of bug? computer can be listed under guid_date name in cloud
        $IntuneObj += Get-IntuneManagedDevice -Filter "azureADDeviceId eq '$($ADObj.ObjectGUID)'" | ? DeviceName -NE $computerName
    }
    #endregion get Intune data

    if ($IntuneObj) {
        $IntuneObj | ? { $_ } | % {
            Write-Host "Removing $($_.DeviceName) ($($_.id)) from Intune" -ForegroundColor Cyan
            Remove-IntuneManagedDevice -managedDeviceId $_.id
        }
    } else {
        Write-Host "$computerName nor its guid exists in Intune. Skipping removal." -ForegroundColor DarkCyan
    }
    #endregion remove computer record from Intune

    Write-Host "Invoking re-enrollment of Intune connection" -ForegroundColor Cyan
    Invoke-MDMReenrollment -computerName $computerName -asSystem

    #region check Intune enrollment result
    Write-Host "Waiting 15 seconds before checking the result" -ForegroundColor Cyan
    Start-Sleep 15

    $intuneEnrollmentStatus = Get-IntuneEnrollmentStatus -computerName $computerName -wait 30

    if ($intuneEnrollmentStatus) {
        Write-Host "DONE :)" -ForegroundColor Green
    } else {
        "Opening Intune logs on $computerName"
        Get-IntuneLog -computerName $computerName
    }
    #endregion check Intune enrollment result
}