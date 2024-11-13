## To update the Boot WIM
## edit-osdcloudwinpe -StartURL https://st2uupbw11seuwq01.blob.core.windows.net/oobe/ll-startup.ps1
## update-osdcloudusb

##  Script runs in WINPE

[decimal]$minimumusb = 1.0
$DateFormat = 'dd-MM-yyyy HH:mm:ss'
$OSDCloud_StartTimeUTC = $(Get-Date ([System.DateTime]::UtcNow) -Format $DateFormat)
## Run from URL
Write-host "LL startup v1.9.2"
Write-Host "Running from [$($Global:ScriptRootURL)]"
start-sleep 5

$USBBootVol = get-volume | where-object {$_.filesystemlabel -match 'WINPE'}
#$USBDataVol = get-volume | where-object {$_.filesystemlabel -match 'OSDCloud' -and $_.DriveType -eq 'Removable'}
$USBDataVol = get-volume | where-object {$_.filesystemlabel -match 'OSDCloud'}

#If (!$USBDataVol) {
#	#Its probably running from an .iso file, so grab the datavol
# 	$USBDataVol = get-volume | where-object {$_.filesystemlabel -match 'OSDCloud' -and $_.DriveType -eq 'CD-ROM'} | select -first 1
#}

## Basic Menu
Clear-Host
Write-Host "1 - Install Windows 11"
Write-Host "Q - quit and restart"
$selection = Read-Host "Enter selection [1,2,Q]"

If ($selection -eq 'q') 
    {
    Write-Host "restarting"
    start-sleep 5
    wpeutil reboot
    }

Write-Host "Continuing to Install Windows..."

## Country 
Clear-Host
Write-Host "Select Country"
Write-Host "13 - Poland"
Write-Host "21 - United Kingdom"
Write-Host "22 - United States"
Write-Host "Q - quit and restart"
while(($CountrySelection -ne 'q') -and ($CountrySelection -notin 1..22))
    {
    $CountrySelection = Read-Host "Enter selection [1..22,q]"
    }
If ($selection -eq 'q') 
    {
    Write-Host "restarting"
    start-sleep 5
    wpeutil reboot
    }
else
    {
    switch($CountrySelection) 
        {
        13    {$Country = "Poland";$Rootkeeby = '0415:00000415';$TimeyWimey = 'Central European Standard Time';$GeoID = '191'} # 191 - Republic of Poland
        21    {$Country = "UK";$Rootkeeby = '0809:00000809';$TimeyWimey = 'GMT Standard Time';$GeoID = '242'} # 242 - United Kingdom
        22    {$Country = "US";$Rootkeeby = '0409:00000409';$TimeyWimey = 'Eastern Standard Time';$GeoID = '244'} # 244 - United States
        }
    }
    

Write-Host "Country is $Country and Keyboard should be $desiredkb"

#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
    Restart = [bool]$False
    RecoveryPartition = [bool]$true
    OEMActivation = [bool]$True
    WindowsUpdate = [bool]$false
    WindowsUpdateDrivers = [bool]$false
    WindowsDefenderUpdate = [bool]$true
    SetTimeZone = [bool]$false
    ClearDiskConfirm = [bool]$False
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$false
    ApplyCatalogFirmware = [bool]$true
    ApplyCatalogDrivers = [bool]$false
    CheckSHA1 = [bool]$false
    OSImageIndex = [int32]3
    ImageFileFullName = [string]"$($USBDataVol.driveletter):\OSDCloud\os\install.wim"
    ImageFileItem = @{fullname = "$($USBDataVol.driveletter):\OSDCloud\os\install.wim"}
    ImageFileName = [string]"install.wim"
    ZTI = [bool]$true
}


invoke-osdcloud


write-host "Windows Restore complete"
start-sleep 5


# Download custom file(s)
Invoke-restmethod -uri "$($Global:ScriptRootURL)/createxml.ps1" | out-file "c:\windows\setup\scripts\createxml.ps1" -force -encoding ascii
invoke-restmethod -uri "$($Global:ScriptRootURL)/wificonnect.ps1" | out-file "c:\windows\setup\scripts\wificonnect.ps1" -force -encoding ascii
Invoke-restmethod -uri "$($Global:ScriptRootURL)/startauditmode.ps1" | out-file "c:\windows\setup\scripts\startauditmode.ps1" -force -encoding ascii

#Custom unattend.xml
New-Item c:\windows\panther\unattend -force -ItemType Directory

#Create the custom unattend.xml
& "c:\windows\setup\scripts\createxml.ps1" -userlocale $desiredKB -TimeZone $TimeyWimey

#Save the wifi profile for use later
netsh wlan export profile key=clear folder=c:\osdcloud\configs



write-host "Startup script completed"
Read-Host -Prompt "Press any key to continue" 
write-host  -foregroundcolor Green "****************************************************"
write-host  -foregroundcolor Green "               Rebooting in 10 seconds"
write-host  -foregroundcolor Green "  You can safely remove the USB after this reboot"
Write-host  -foregroundcolor Green "****************************************************"
start-sleep 10


wpeutil reboot
