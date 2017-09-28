function TestFunction($session)
{
	$session.Log("This is a test of the Powershell function support")
	return $msi.ActionResult.Success
}
