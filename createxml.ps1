##  Script runs in WINPE

[CmdletBinding()]
    param (
        [String]$userlocale = "en-US",
        [String]$TimeZone = 'Eastern Standard Time',
        [String]$GeoID = '191'
    )

$SysLocale = "en-US"

write-host "UserLocale:$($userlocale)"
Write-host "SystemLocale:$($SysLocale)"
Write-host "TimeZone:$($TimeZone)"

$auditmodescript = "$($Global:ScriptRootURL)/StartAuditMode.ps1"
$UnattendPath = "c:\windows\panther\unattend\unattend.xml"
$SysprepPath = "c:\windows\panther\unattend\oobe.xml"
$RecoveryPath = "c:\recovery\autoapply\unattend.xml"
$CPLXMLPath = "c:\recovery\test.xml"  # move to LL\Eng\Lang\test.xml in oobe manually 


$result = New-Item c:\windows\panther\unattend -ItemType Directory -Force
$result = New-Item c:\recovery\autoapply -ItemType Directory -Force

$SysprepXml = [xml] @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <ProtectYourPC>3</ProtectYourPC>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideEULAPage>true</HideEULAPage>
            </OOBE>
            <RegisteredOrganization>Linklaters</RegisteredOrganization>
            <RegisteredOwner>Linklaters User</RegisteredOwner>
            <TimeZone>UTC</TimeZone>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:c:/win11-unattend/sources/install.wim#Windows 11 Enterprise" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
'@

$AuditModeXml = [xml] @"
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
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:c:/win11-unattend/sources/install.wim#Windows 11 Enterprise" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
"@

foreach ($setting in $SysprepXml.Unattend.Settings) {
    #Write-host "Checking Setting:$($setting) in Unattend"
    foreach ($component in $setting.Component) {
        if ((($setting.'Pass' -eq 'oobeSystem') -or ($setting.'Pass' -eq 'specialize')) -and ($component.'Name' -eq 'Microsoft-Windows-International-Core')) {
            $component.InputLocale = $userlocale #Specifies the system input locale and the keyboard layout
            #$component.SystemLocale = $SysLocale #Specifies the language for non-Unicode programs
            #$component.UILanguage = $SysLocale #Specifies the system default user interface (UI) language
            #$component.UserLocale = $SysLocale #Specifies the per-user settings used for formatting dates, times, currency, and numbers
        }
        if ((($setting.'Pass' -eq 'oobeSystem') -or ($setting.'Pass' -eq 'specialize')) -and ($component.'Name' -eq 'Microsoft-Windows-Shell-Setup')) {
            $component.Timezone = $Timezone
        }
    } #end foreach setting.Component
} #end foreach unattendXml.Unattend.Settings

$AuditModeXml.save($UnattendPath)
$SysprepXml.Save($SysprepPath)
$SysprepXml.Save($RecoveryPath)

$CPLXML = @"
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
 
<!-- user list --> 
    <gs:UserList>
        <gs:User UserID="Current" CopySettingsToDefaultUserAcct="true" CopySettingsToSystemAcct="true"/> 
    </gs:UserList>

<!-- system locale -->
    <gs:SystemLocale Name="$userlocale"/>

<!--User Locale-->
    <gs:UserLocale> 
        <gs:Locale Name="$userlocale" SetAsCurrent="true" ResetAllSettings="false"/>
    </gs:UserLocale>

<!--location--> 
 <gs:LocationPreferences> 
        <gs:GeoID Value="$GeoID"/> 
    </gs:LocationPreferences>
    
</gs:GlobalizationServices>
"@

$CPLXML.Save($CPLXMLPath)



