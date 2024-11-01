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
Write-Host "1 - Belgium"
Write-Host "2 - Brazil"
Write-Host "3 - China"
Write-Host "4 - France"
Write-Host "5 - Germany"
Write-Host "6 - Hong Kong"
Write-Host "7 - Indonesia"
Write-Host "8 - Italy"
Write-Host "9 - Japan"
Write-Host "10 - Korea"
Write-Host "11 - Luxembourg"
Write-Host "12 - Netherlands"
Write-Host "13 - Poland"
Write-Host "14 - Portugal"
Write-Host "15 - Russia"
Write-Host "16 - Singapore"
Write-Host "17 - Spain"
Write-Host "18 - Sweden"
Write-Host "19 - United Arab Emirates"
Write-Host "20 - Thailand"
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
        1     {$Country = "Belgium";$TimeyWimey = 'Romance Standard Time'} # 21 - Kingdom of Belgium 
        2     {$Country = "Brazil";$TimeyWimey = 'E. South America Standard Time'} # 32 - Federative Republic of Brazil
        3     {$Country = "China";$TimeyWimey = 'China Standard Time'} # 45 - People's Republic of China 
        4     {$Country = "France";$TimeyWimey = 'Romance Standard Time'} # 84 - French Republic 
        5     {$Country = "Germany";$TimeyWimey = 'W. Europe Standard Time'} # 94 - Federal Republic of Germany
        6     {$Country = "Hong Kong";$TimeyWimey = 'China Standard Time'} # 104 - Hong Kong Special Administrative Region
        7     {$Country = "Indonesia";$TimeyWimey = 'SE Asia Standard Time';$CCulture = 'id-ID'} # 111 - Republic of Indonesia
        8     {$Country = "Italy";$TimeyWimey = 'W. Europe Standard Time'} # 118 - Italian Republic
        9     {$Country = "Japan";$TimeyWimey = 'Tokyo Standard Time'} # 122 - Japan
        10    {$Country = "Korea";$TimeyWimey = 'Korea Standard Time'} # 134 - Republic of Korea
        11    {$Country = "Luxembourg";$TimeyWimey = 'W. Europe Standard Time'} # 147 - Grand Duchy of Luxembourg
        12    {$Country = "Netherlands";$TimeyWimey = 'W. Europe Standard Time'} # 176 - Kingdom of the Netherlands
        13    {$Country = "Poland";$TimeyWimey = 'Central European Standard Time';$desiredkb = 'pl-PL'} # 191 - Republic of Poland
        14    {$Country = "Portugal";$TimeyWimey = 'GMT Standard Time'} # 193 - Portuguese Republic
        15    {$Country = "Russia";$TimeyWimey = 'Russian Standard Time'} # 203 - Russian Federation
        16    {$Country = "Singapore";$TimeyWimey = 'Singapore Standard Time';$CCulture = 'en-SG'} # 215 - Republic of Singapore
        17    {$Country = "Spain";$TimeyWimey = 'Romance Standard Time'} # 217 - Kingdom of Spain
        18    {$Country = "Sweden";$TimeyWimey = 'W. Europe Standard Time'} # 221 - Kingdom of Sweden
        19    {$Country = "UAE";$TimeyWimey = 'Arabian Standard Time';$CCulture = 'ar-AE'} # 224 - United Arab Emirates
        20    {$Country = "Thailand";$TimeyWimey = 'SE Asia Standard Time'} # 227 - Kingdom of Thailand
        21    {$Country = "UK";$TimeyWimey = 'GMT Standard Time';$desiredkb = 'en-GB'} # 242 - United Kingdom
        22    {$Country = "US";$TimeyWimey = 'Eastern Standard Time'} # 244 - United States
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
    SetTimeZone = [bool]$true
    ClearDiskConfirm = [bool]$False
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$false
    ApplyCatalogFirmware = [bool]$true
    ApplyCatalogDrivers = [bool]$false
    Logs = [string]"C:\Windows\System32\Micadun\Logfiles"
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




# Load the offline registry hive from the OS volume
Write-Host "writing to offline registry"
$HivePath = "c:\Windows\System32\config\SOFTWARE"
reg load "HKLM\NewOS" $HivePath 
Start-Sleep -Seconds 5

# Set ScriptRootURL
$RegistryKey = "HKLM:\NewOS\Linklaters" 
$Result = New-Item -Path $RegistryKey -ItemType Directory -Force
$Result.Handle.Close()
$RegistryValue = "LLScriptRootURL"
$RegistryValueType = "String"
$RegistryValueData = $ScriptRootURL
$Result = New-ItemProperty -Path $RegistryKey -Name $RegistryValue -PropertyType $RegistryValueType -Value $RegistryValueData -Force
    
# Cleanup (to prevent access denied issue unloading the registry hive)
Remove-Variable Result
Get-Variable Registry* | Remove-Variable
Start-Sleep -Seconds 5

# Unload the registry hive
Set-Location X:\
reg unload "HKLM\NewOS"


# Download custom file(s)
Invoke-restmethod -uri "$($Global:ScriptRootURL)/MDcreatexml.ps1" | out-file "c:\windows\setup\scripts\createxml.ps1" -force -encoding ascii
invoke-restmethod -uri "$($Global:ScriptRootURL)/MDwificonnect.ps1" | out-file "c:\windows\setup\scripts\wificonnect.ps1" -force -encoding ascii
Invoke-restmethod -uri "$($Global:ScriptRootURL)/MDstartauditmode.ps1" | out-file "c:\windows\setup\scripts\startauditmode.ps1" -force -encoding ascii

#Custom unattend.xml
New-Item c:\windows\panther\unattend -force -ItemType Directory

#Create the custom unattend.xml
& "c:\windows\setup\scripts\createxml.ps1" -userlocale $desiredKB -TimeZone $TimeyWimey

#Save the wifi profile for use later
netsh wlan export profile key=clear folder=c:\osdcloud\configs

cls

write-host "Startup script completed"

write-host  -foregroundcolor Green "****************************************************"
write-host  -foregroundcolor Green "               Rebooting in 10 seconds"
write-host  -foregroundcolor Green "  You can safely remove the USB after this reboot"
Write-host  -foregroundcolor Green "****************************************************"
start-sleep 10


wpeutil reboot
