Param([Microsoft.Deployment.WindowsInstaller.Session]$session)


$msi = Add-Type -AssemblyName "Microsoft.Deployment.WindowsInstaller"
$session.Log("This is a test of the Powershell Script support")

return $msi.ActionResult.Success




