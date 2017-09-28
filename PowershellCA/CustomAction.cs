using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.Deployment.WindowsInstaller;

namespace PowershellCA
{
    public partial class CustomActions
    {
        [CustomAction]
        public static ActionResult Function(Session session)
        {
            return ExecPowershell(session, "Function.ps1", "TestFunction");
        }

        [CustomAction]
        public static ActionResult Script(Session session)
        {
            return ExecPowershell(session, "Script.ps1");
        }

        [CustomAction]
        public static ActionResult GenerateUID(Session session)
        {
            return ExecPowershell(session, "AzureFunctions.ps1", "GenerateUID");
        }

        [CustomAction]
        public static ActionResult PublishWebDeploy(Session session)
        {
            return ExecPowershell(session, "AzureFunctions.ps1", "PublishWebDeploy");
        }

        [CustomAction]
        public static ActionResult ValidateAzureTemplate(Session session)
        {
            return ExecPowershell(session, "AzureFunctions.ps1", "ValidateAzureTemplate");
        }

        [CustomAction]
        public static ActionResult UninstallRMResources(Session session)
        {
            return ExecPowershell(session, "AzureFunctions.ps1", "UninstallRMResources");
        }

        [CustomAction]
        public static ActionResult DeployToAzureRMResourceGroup(Session session)
        {
            return ExecPowershell(session, "AzureFunctions.ps1", "DeployToAzureRMResourceGroup");
        }

        [CustomAction]
        public static ActionResult GetAzureRMResourceGroups(Session session)
        {
            return ExecPowershell(session, "AzureFunctions.ps1", "GetAzureRMResourceGroups");
        }

        [CustomAction]
        public static ActionResult ValidateAzureRMAccount(Session session)
        {
            return ExecPowershell(session, "AzureFunctions.ps1", "ValidateAzureRMAccount");
        }
    }
}
