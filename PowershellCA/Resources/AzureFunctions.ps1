. ".\Remove-AzureRmResources.ps1"
$ErrorActionPreference = "Stop"

function ValidateAzureRMAccount($session)
{
	try
	{
		Set-PSDebug -Trace 2
		$msi = Add-Type -AssemblyName "Microsoft.Deployment.WindowsInstaller" -PassThru
		[System.Windows.Forms.MessageBox]::Show('Attach now with VS')
		Log($session,"Begin ValidateAzureRMAccount")
		$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
		#iterate through subscriptions present for account, and populate dropdown
		#combine the two ops, b/c we pay a ~3 second performance hit for the privilege of running powershell...
		$azureAccountName = $session["AZURE_USER"]
		$azurePassword = ConvertTo-SecureString $session["AZURE_PASS"] -AsPlainText -Force

		$psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)

		$acct = Login-AzureRmAccount -Credential $psCred

		$hRec = $session.Database.CreateRecord(4)

        Log($session,"Inserting Azure subscriptions into combobox")

        $hView = $session.Database.OpenView("SELECT * FROM ``ComboBox``")

        $nRecords = 0

		foreach($subscription in Get-AzureRmSubscription)
		{
            Log($session,"Inserting: " + $subscription.SubscriptionName)
            #add to drop down box
            $hRec.SetString(1, "AZURE_SUB")
            $hRec.SetInteger(2, $nRecords)
            $hRec.SetString(3, $subscription.SubscriptionName)
            $hRec.SetString(4, $subscription.SubscriptionName)
            $hView.Modify($msi.ViewModifyMode.InsertTemporary, $hRec)
            $nRecords++
		}
	}
	catch [Exception]
	{
		Log($session,"Exception: " + $_.Exception.Message)
		$session["AZURE_ACCT_INVALID"] = "1"
		Log($session,"End ValidateAzureRMAccount")
		return $msi.ActionResult.Success
	}
	$session["AZURE_ACCT_INVALID"] = ""
	Log($session,"End ValidateAzureRMAccount")
	return $msi.ActionResult.Success
}

function GetAzureRMResourceGroups($session)
{
	try
	{
		$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
		#get list of resource groups and populate combobox
		AuthenticateAzureSession($session)

		$hRec = $session.Database.CreateRecord(4)

        Log($session,"Inserting Azure subscriptions into combobox")

        $hView = $session.Database.OpenView("SELECT * FROM ``ComboBox``")

        $nRecords = 0

		foreach($rg in Get-AzureRmResourceGroup)
		{
            Log($session,"Inserting: " + $subscription.SubscriptionName)
            #add to drop down box
            $hRec.SetString(1, "AZURE_RG")
            $hRec.SetInteger(2, $nRecords)
            $hRec.SetString(3, $rg.SubscriptionName)
            $hRec.SetString(4, $rg.SubscriptionName)
            $hView.Modify($msi.ViewModifyMode.InsertTemporary, $hRec)
            $nRecords++
		}
	}
	catch [Exception]
	{
		Log($session,"Exception: " + $_.Exception.Message)
		return $msi.ActionResult.Success
	}
	return $msi.ActionResult.Success
}

function DeployToAzureRMResourceGroup($session)
{
	try
	{
		$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
		#get list of resource groups and populat combobox
		AuthenticateAzureSession($session)

		#OK, now deploy the template with parameters:

		$TemplateFile = Path.Combine($scriptPath, "template.json")
		$TemplateParametersFile = Path.Combine($scriptPath, "template.parameters.json")

		New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
									-ResourceGroupName $ResourceGroupName `
									-TemplateFile $TemplateFile `
									-TemplateParameterFile $TemplateParametersFile `
									-serviceplan_name $session["SERVICEPLAN_NAME"] `
									-site_name $session["SITE_NAME"] `
									-Force -Verbose `
									-ErrorVariable ErrorMessages

	}
	catch [Exception]
	{
		Log($session,"Exception: " + $_.Exception.Message)
		return $msi.ActionResult.Success
	}
	return $msi.ActionResult.Success
}

function RollbackAzureRMResources($session)
{
	try
	{
		AuthenticateAzureSession($session)
		Remove-AzureRmResources -ResourceGroupName GetCADATAProp($session,"AZURE_RG") -Suffix GETCADATAProp($session, "UID")
	}
	catch [Exception]
	{
		Log($session,"Exception: " + $_.Exception.Message)
		return $msi.ActionResult.Success
	}
	return $msi.ActionResult.Success
}

function UninstallRMResources($session)
{
	try
	{
		AuthenticateAzureSession($session)
		$uid = $session["UID"]

		Remove-AzureRmResources -ResourceGroupName $session["AZURE_RG"] -Suffix $session["UID"]

	}
	catch [Exception]
	{
		Log($session,"Exception: " + $_.Exception.Message)
		return $msi.ActionResult.Success
	}
	return $msi.ActionResult.Success
}

function ValidateAzureTemplate($session)
{
	try
	{
		AuthenticateAzureSession($session)
		$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
		#get list of resource groups and populat combobox


		#OK, now deploy the template with parameters:

		$TemplateFile = Path.Combine($scriptPath, "template.json")
		$TemplateParametersFile = Path.Combine($scriptPath, "template.parameters.json")

		$ErrorMessages = Format-ValidationOutput (New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
									-ResourceGroupName $ResourceGroupName `
									-TemplateFile $TemplateFile `
									-TemplateParameterFile $TemplateParametersFile `
									-serviceplan_name $session["SERVICEPLAN_NAME"] `
									-site_name $session["SITE_NAME"] `
									-Force -Verbose `
									-ErrorVariable ErrorMessages)

		if ($ErrorMessages) {
			session.Log( '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.')
			#TODO: Show msgbox via Session.Message to show errors
			#and set property indicating invalidity
			$session["AZURE_TEMPLATE_INVALID"] = "1"
		}
		else {
			session.Log( '', 'Template is valid.')
			$session["AZURE_TEMPLATE_INVALID"] = "0"
		}

	}
	catch [Exception]
	{
		Log($session,"Exception: " + $_.Exception.Message)
		return $msi.ActionResult.Success
	}
	return $msi.ActionResult.Success
}

function PublishWebDeploy($session)
{
	try
	{
		AuthenticateAzureSession($session)
		$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
		#Get some information about the WebDeploy package...
		#Hey, mebbe we write it in C# and make it broadly consumable?
		#Q: Does the web app expose a listening WebDeploy endpoint?
		#Q: If so, can we implement a generic solution to support local web servers as well as Azure endpoints?

		$webDeployPath = $session.Format("[#WebDeployPackage]")

		#do...something?

	}
	catch [Exception]
	{
		Log($session,"Exception: " + $_.Exception.Message)
		return $msi.ActionResult.Success
	}
	return $msi.ActionResult.Success
}

function GenerateUID($session)
{
	try
	{
		$session["UID"] = [guid]::NewGuid().ToString().Substring(28);
	}
	catch [Exception]
	{
		Log($session,"Exception: " + $_.Exception.Message)
		return $msi.ActionResult.Success
	}
	return $msi.ActionResult.Success
}

function AuthenticateAzureSession($session)
{
		$azureAccountName = $session["AZURE_USER"]
		$azurePassword = ConvertTo-SecureString $session["AZURE_PASS"] -AsPlainText -Force

		$psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)

		$acct = Login-AzureRmAccount -Credential $psCred

		Select-AzureRmSubscription -SubscriptionName $session["AZURE_SUB"]
}

function PopulateComboBox($session, $property, $dictionary)
{

}

function GetCADATAProp($session, $property)
{
	$cadata = $session["CustomActionData"]
	foreach($pair in $cadata.Split(";"))
	{
		$prop = $pair.Split("=")[0]
		$val = $pair.Split("=")[1]
		if($property -eq $prop)
		{
			return $val
		}
	}
	return ""
}

function Log($session, $logentry)
{
	#$msi = Add-Type -AssemblyName "Microsoft.Deployment.WindowsInstaller" -PassThru
	#$rec = $session.Database.CreateRecord(1)
    #$rec.SetString(1, $logentry)
    #$result = $session.Message([Microsoft.Deployment.WindowsInstaller.InstallMessage]67108864, $rec)
    #if ($result -eq 0)
    #{
		$guid = "PSCELOG" + [guid]::NewGuid().ToString().Substring(28).ToUpper()
		$session[$guid] = $logentry 

    #}
}


