using namespace System.Management.Automation
using namespace System.Net

[ServicePointManager]::SecurityProtocol = [SecurityProtocolType]::Tls12
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned 
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

Install-Module -Name 'MSOnline' -Confirm:$false -Force
Install-Module -Name 'AzureADPreview' -Confirm:$false -Force
Install-Module -Name 'MicrosoftTeams' -Confirm:$false -Force

Import-Module -Name 'MSOnline'
Import-Module -Name 'AzureAD'
Import-Module -Name 'MicrosoftTeams'

Connect-MsolService
Connect-AzureAD
Connect-MicrosoftTeams



$Template = Get-AzureADDirectorySettingTemplate | Where-Object {$_.DisplayName -eq "Group.Unified"}
if(!($Setting = Get-AzureADDirectorySetting | Where-Object {$_.TemplateId -eq $Template.Id})) 
{
    $Setting = $Template.CreateDirectorySetting()
}
$Setting["EnableGroupCreation"] = "False"
$Setting["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString "GroupCreators").objectid
$Setting["EnableMIPLabels"] = "True" 
$Setting.Values

#New Tenant
New-AzureADDirectorySetting -DirectorySetting $Setting
#Existing Tenant
Set-AzureADDirectorySetting -DirectorySetting $Setting
