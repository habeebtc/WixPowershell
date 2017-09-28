#
# Remove_AzureRMResources.ps1
#Requires -Version 3.0
#Requires -Module AzureRM.Resources
#Requires -Module Azure.Storage
#
Param(
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
	[string] [Parameter(Mandatory=$false)] $Prefix,
	[string] [Parameter(Mandatory=$false)] $Suffix,
	[string] [Parameter(Mandatory=$false)] $TagName,
	[string] [Parameter(Mandatory=$false)] $TagValue,
    [Parameter(Mandatory=$false)] $restypes = ('Microsoft.Compute/virtualMachines', 'Microsoft.Network/networkInterfaces', 'Microsoft.Network/publicIPAddresses', 'Microsoft.Storage/storageAccounts','Microsoft.Web/sites', 'Microsoft.Web/serverfarms' )
)

$res = Get-AzureRmResource


	
	foreach($resourceType in $restypes.Split(','))
	{
		Write-Host "Clean up resources branded with our ID and type:  " $resourceType
		foreach($obj in $res) 
		{
			try
			{
				if($resourceType -eq $obj.ResourceType.ToString() -and $ResourceGroupName -eq $obj.ResourceGroupName)
				{
					if($Prefix -eq $null -and -$Suffix -eq $null -and $TagName -eq $null)
					{
						Write-Host "Removing Resource due to Resource Group membership and no flags specified"  $obj.ResourceName
						Remove-AzureRmResource -ResourceId $obj.ResourceId -Force
					}
					elseif(![string]::IsNullOrEmpty($Prefix) -and $obj.ResourceName.StartsWith($Prefix))
					{
						Write-Host "Removing Resource due to matching Prefix:" $Prefix " Resource Name: " $obj.ResourceName
						Remove-AzureRmResource -ResourceId $obj.ResourceId -Force
					}
					elseif(![string]::IsNullOrEmpty($Suffix) -and $obj.ResourceName.EndsWith($Suffix))
					{
						Write-Host "Removing Resource due to matching Suffix:" $Suffix ", Resource Name: " $obj.ResourceName
						Remove-AzureRmResource -ResourceId $obj.ResourceId -Force
					}
					elseif(![string]::IsNullOrEmpty($TagName) )
					{
						#Find tag specified for resource
					
						if(![string]::IsNullOrEmpty($TagName) -and [string]::IsNullOrEmpty($TagValue))
						{
							Write-Host "Removing Resource due to having tagname: " $TagName " Resource Name: " $obj.ResourceName
							Remove-AzureRmResource -ResourceId $obj.ResourceId -Force
						}
						elseif(![string]::IsNullOrEmpty($TagValue) -and $TagValue -eq $obj.Tags[$TagName])
						{
							Write-Host "Removing Resource due to having tag name: $TagName and value $TagValue Resource Name: $obj.ResourceName"
							Remove-AzureRmResource -ResourceId $obj.ResourceId -Force
						}

					}
					elseif([string]::IsNullOrEmpty($Prefix) -and [string]::IsNullOrEmpty($Suffix) -and [string]::IsNullOrEmpty($TagName))
					{
						#Just resource group is specified, so nuke everything.
						Write-Host "Removing resource " $obj.ResourceName "due to no filter flags being set for ResourceGroup $ResourceGroupName"
						Remove-AzureRmResource -ResourceId $obj.ResourceId -Force
					}
				}
			}
			catch
			{
				Write-Host "Failed to remove resource " + $obj.ResourceName
				Write-Host "Caught exception in script" + $_.Exception.Message
			}
		}
	}