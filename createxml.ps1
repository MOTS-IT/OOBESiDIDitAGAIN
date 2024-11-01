##  Script runs in WINPE

[CmdletBinding()]
    param (
        [String]$userlocale = "en-US",
        [String]$TimeZone = 'Eastern Standard Time'
    )

$SysLocale = "en-US"

write-host "UserLocale:$($userlocale)"
Write-host "SystemLocale:$($SysLocale)"
Write-host "TimeZone:$($TimeZone)"

$auditmodescript = "$($Global:ScriptRootURL)/startAuditMode.ps1"
$UnattendPath = "c:\windows\panther\unattend\unattend.xml"
$SecondPassFile = "c:\windows\panther\unattend\oobe.xml"
$RecoveryPath = "c:\recovery\autoapply\unattend.xml"

$result = New-Item c:\windows\panther\unattend -ItemType Directory -Force
$result = New-Item c:\recovery\autoapply -ItemType Directory -Force

$auditmode = [xml] @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Reseal>
                <Mode>Audit</Mode>
            </Reseal>
        </component>
    </settings>
    <settings pass="auditUser">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Description>LL:Start Wifi</Description>
                    <Path>PowerShell -executionpolicy bypass -Command "c:\windows\setup\scripts\wificonnect.ps1"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>4</Order>
                    <Description>LL:Execute Audit Mode script</Description>
                    <Path>PowerShell -executionpolicy bypass -Command "c:\windows\setup\scripts\startauditmode.ps1"</Path>
                    <WillReboot>Always</WillReboot>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
    <settings pass="auditSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <AutoLogon>
                <Enabled>true</Enabled>
                <LogonCount>5</LogonCount>
                <Username>administrator</Username>
                <Password>
                    <Value>aABhAC4ANwBmAHoANgApAFAAagB3AHAAIQBxACUAYwA7AFMALQB9AFYANQBQAGEAcwBzAHcAbwByAGQA</Value>
                    <PlainText>false</PlainText>
                </Password>
            </AutoLogon>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>aABhAC4ANwBmAHoANgApAFAAagB3AHAAIQBxACUAYwA7AFMALQB9AFYANQBBAGQAbQBpAG4AaQBzAHQAcgBhAHQAbwByAFAAYQBzAHMAdwBvAHIAZAA=</Value>
                    <PlainText>false</PlainText>
                </AdministratorPassword>
            </UserAccounts>
            <TimeZone></TimeZone>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UILanguageFallback></UILanguageFallback>
            <UserLocale>en-US</UserLocale>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:c:/win11-unattend/sources/install.wim#Windows 11 Enterprise" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
"@


$SecondPassXml = [xml] @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <ProtectYourPC>3</ProtectYourPC>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideEULAPage>true</HideEULAPage>
            </OOBE>
            <RegisteredOrganization>MD</RegisteredOrganization>
            <RegisteredOwner>MD User</RegisteredOwner>
            <TimeZone>UTC</TimeZone>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:c:/win11-unattend/sources/install.wim#Windows 11 Enterprise" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
'@




foreach ($setting in $auditmode.Unattend.Settings) {
    #Write-host "Checking Setting:$($setting) in Unattend"
    foreach ($component in $setting.Component) {
        #write-host "Checking component:$($component) in Unattend"
        if ((($setting.'Pass' -eq 'oobeSystem') -or ($setting.'Pass' -eq 'specialize')) -and ($component.'Name' -eq 'Microsoft-Windows-International-Core')) {
            #Write-Host "Updating Locale settings"
            $component.InputLocale = $userlocale
            $component.SystemLocale = $SysLocale
            $component.UILanguage = $SysLocale
            $component.UserLocale = $userlocale
        }
        if ((($setting.'Pass' -eq 'oobeSystem') -or ($setting.'Pass' -eq 'specialize')) -and ($component.'Name' -eq 'Microsoft-Windows-Shell-Setup')) {
            #Write-Host "Updating Locale settings"
            $component.Timezone = $Timezone
        }
    } #end foreach setting.Component
} #end foreach unattendXml.Unattend.Settings


foreach ($setting in $SecondPassXml.Unattend.Settings) {
    #Write-host "Checking Setting:$($setting) in Unattend"
    foreach ($component in $setting.Component) {
        #write-host "Checking component:$($component) in Unattend"
        if ((($setting.'Pass' -eq 'oobeSystem') -or ($setting.'Pass' -eq 'specialize')) -and ($component.'Name' -eq 'Microsoft-Windows-International-Core')) {
            #Write-Host "Updating Locale settings"
            $component.InputLocale = $userlocale
            $component.SystemLocale = $SysLocale
            $component.UILanguage = $SysLocale
            $component.UserLocale = $userlocale
        }
        if ((($setting.'Pass' -eq 'oobeSystem') -or ($setting.'Pass' -eq 'specialize')) -and ($component.'Name' -eq 'Microsoft-Windows-Shell-Setup')) {
            #Write-Host "Updating Locale settings"
            $component.Timezone = $Timezone
        }
    } #end foreach setting.Component
} #end foreach unattendXml.Unattend.Settings


$SecondPassXml.Save($OOBEPath)
$SecondPassXml.Save($RecoveryPath)
$auditmode.save($UnattendPath)
