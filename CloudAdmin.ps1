using namespace System.Management.Automation
using namespace System.Net

[ServicePointManager]::SecurityProtocol = [SecurityProtocolType]::Tls12
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned 
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

Install-Module -Name 'MSOnline' -Confirm:$false -Force
Install-Module -Name 'AzureAD' -Confirm:$false -Force
Install-Module -Name 'AzureADPreview' -Confirm:$false -Force
Install-Module -Name 'Microsoft.Online.SharePoint.PowerShell' -Confirm:$false -Force
Install-Module -Name 'PnP.PowerShell' -Confirm:$false -Force
Install-Module -Name 'MicrosoftTeams' -Confirm:$false -Force
Install-Module -Name 'Microsoft.PowerApps.Administration.PowerShell' -Confirm:$false -Force
Install-Module -Name 'Microsoft.PowerApps.PowerShell' -AllowClobber -Confirm:$false -Force
Install-Module -Name 'Microsoft.Xrm.OnlineManagementAPI' -Confirm:$false -Force
Install-Module -Name 'Microsoft.Xrm.Tooling.CrmConnector.PowerShell' -Confirm:$false -Force

Import-Module -Name 'MSOnline'
Import-Module -Name 'AzureAD'
Import-Module -Name 'Microsoft.Online.SharePoint.PowerShell'
Import-Module -Name 'PnP.PowerShell'
Import-Module -Name 'MicrosoftTeams'
Import-Module -Name 'Microsoft.PowerApps.Administration.PowerShell'
Import-Module -Name 'Microsoft.PowerApps.PowerShell'
Import-Module -Name 'Microsoft.Xrm.OnlineManagementAPI'
Import-Module -Name 'Microsoft.Xrm.Tooling.CrmConnector.PowerShell'

$Tenant = Get-Content .\Config.json  | ConvertFrom-Json -AsHashtable
#$Tenant = Get-Content .\Config.json  | ConvertFrom-Json
$Tenant.AzureAD.Admin.Credential = [PSCredential]::new($Tenant.AzureAD.Admin.UserName, (ConvertTo-SecureString $Tenant.AzureAD.Admin.Password -AsPlainText -Force ))
$Tenant.SharePoint.Admin.Credential = [PSCredential]::new($Tenant.SharePoint.Admin.UserName, (ConvertTo-SecureString $Tenant.SharePoint.Admin.Password -AsPlainText -Force ))
$Tenant.Exchange.Admin.Credential = [PSCredential]::new($Tenant.Exchange.Admin.UserName, (ConvertTo-SecureString $Tenant.Exchange.Admin.Password -AsPlainText -Force ))
$Tenant.Complience.Admin.Credential = [PSCredential]::new($Tenant.Complience.Admin.UserName, (ConvertTo-SecureString $Tenant.Complience.Admin.Password -AsPlainText -Force ))
$Tenant.Teams.Admin.Credential = [PSCredential]::new($Tenant.Teams.Admin.UserName, (ConvertTo-SecureString $Tenant.Teams.Admin.Password -AsPlainText -Force ))
$Tenant.PowerApps.Admin.Credential = [PSCredential]::new($Tenant.PowerApps.Admin.UserName, (ConvertTo-SecureString $Tenant.PowerApps.Admin.Password -AsPlainText -Force ))

Connect-MsolService -Credential $Tenant.AzureAD.Admin.Credential
Connect-AzureAD -Credential $Tenant.AzureAD.Admin.Credential
Connect-SPOService -Credential $Tenant.SharePoint.Admin.Credential -Url $Tenant.SharePoint.Admin.Url
Connect-PnPOnline -Url $Tenant.SharePoint.Admin.Url -UseWebLogin 
Connect-MicrosoftTeams -Credential $Tenant.Teams.Admin.Credential  
Add-PowerAppsAccount -Endpoint prod -Username $Tenant.PowerApps.Admin.UserName -Password (ConvertTo-SecureString $Tenant.PowerApps.Admin.Password -AsPlainText -Force )


<# Microsoft Graph from PowerShell #>
$Tenant.Graph.Token = (Invoke-RestMethod -Method Post -Uri $Tenant.Graph.Url -Body $Tenant.Graph.OAuth).access_token
(Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/groups" -Headers @{Authorization = "Bearer $($Tenant.Graph.Token)"}).value

$Headers = @{
    ContentType="application/json"
    Authorization = "Bearer $($Tenant.Graph.Token)"
}
Invoke-RestMethod -Method POST -Uri "https://graph.microsoft.com/v1.0/teams" -Headers $Headers -ContentType "application/json" -InFile .\Group.json




Get-Team
Get-MsolUser
Get-MsolAccountSku

$Template = Get-AzureADDirectorySettingTemplate | Where-Object {$_.DisplayName -eq "Group.Unified"}
if(!($Setting = Get-AzureADDirectorySetting | Where-Object {$_.TemplateId -eq $Template.Id})) 
{
    $Setting = $Template.CreateDirectorySetting()
}
$Setting["EnableGroupCreation"] = "False"
$Setting["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString "GroupCreators").objectid

$Setting = Get-AzureADDirectorySetting -Id (Get-AzureADDirectorySetting | Where-Object -Property DisplayName -Value "Group.Unified" -EQ).id
$Setting["EnableMIPLabels"] = "True" 
$Setting.Values
#New-AzureADDirectorySetting -DirectorySetting $Setting
Set-AzureADDirectorySetting -DirectorySetting $Setting


New-Team -Displayname "CA-Office" -MailNickName "CA-Office" -Visibility Public
Get-Team -Displayname "CA-Office" | Add-TeamUser -User AlexW@M365x081234.onmicrosoft.com
Get-Team -Displayname "CA-Office" | Add-TeamUser -User AllanD@M365x081234.onmicrosoft.com
Get-Team -Displayname "CA-Office" | New-TeamChannel -DisplayName "Support"
Get-Team -Displayname "CA-Office" | New-TeamChannel -DisplayName "Recruiting"
Get-Team -Displayname "CA-Office" | New-TeamChannel -DisplayName "Administration" -MembershipType Standard

Get-Team
# Use this Instead
$Teams = Get-Content .\Teams.json  | ConvertFrom-Json
$Teams
foreach ($Team in $Teams) {
    $T = New-Team -Displayname $Team.DisplayName -MailNickName $Team.MailNickName -Visibility $Team.Visibility -Description $Team.Description
    foreach ($User in $Team.Users) {
        $T |  Add-TeamUser -User $User.User -Role $User.Role
    }
    foreach ($Channel in $Team.Channels) {
        $T | New-TeamChannel -DisplayName $Channel.DisplayName -MembershipType $Channel.MembershipType -Description $Channel.Description
    }
    $T | Get-TeamChannel
}