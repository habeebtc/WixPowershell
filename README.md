# WixPowershell
A sample project for WixPowershell support

This uses Wix 3.11 DTF support.

So, on the path to hosting the Powershell code in the installer:

Msiexec.exe > PowershellCA.CA.dll (native) > Extracts > PowershellCA.dll (Managed) > calls > AzureFunctions.ps1
