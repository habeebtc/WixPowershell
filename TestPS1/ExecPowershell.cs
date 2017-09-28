using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Reflection;
using System.IO;
using Microsoft.Deployment.WindowsInstaller;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Diagnostics;
using System.Resources;
using System.Collections;

namespace TestPS1
{
    public partial class CustomActions
    {
        public static ActionResult ExecPowershell(Session session, string scriptName, string functionName = "")
        {
            PowerShell powerShell = PowerShell.Create();

            //disable powershell restrictions for the CA session
            SetProcessExecution(session, "Unrestricted");

            session.Log("Start Exec Powershell script {0}, function {1}", scriptName, functionName);
            string include = string.Format(". \".\\{0}\"", scriptName);
            string param = "Param([Microsoft.Deployment.WindowsInstaller.Session]$session)";
            string callFunc = string.Format("{0}($session)", functionName);
            string loadInterop = String.Format("$msi = Add-Type -AssemblyName \"Microsoft.Deployment.WindowsInstaller\"");



            //if no function name specified, create a small script to bootstrap the script to be executed and pass the $session
            string scriptPath = Path.Combine(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location), scriptName);
            string scriptbody = string.Empty;
            if (functionName == string.Empty)
            {
                scriptbody += new StreamReader(scriptPath).ReadToEnd();
                powerShell.AddScript(scriptbody);
                powerShell.AddArgument(session);
            }
            else
            {
                scriptbody += param + Environment.NewLine;
                scriptbody += include + Environment.NewLine;
                scriptbody += loadInterop + Environment.NewLine;
                scriptbody += callFunc + Environment.NewLine;
                powerShell.AddScript(scriptbody);
                powerShell.AddArgument(session);
            }
            System.Collections.ObjectModel.Collection<PSObject> results = powerShell.Invoke();

            foreach (InformationRecord rec in powerShell.Streams.Information.ReadAll())
            {
                session.Log(rec.MessageData.ToString());
            }

            if (powerShell.Streams.Error.Count > 0)
            {
                session.Log("Script Failed!  Begin error section.");
                foreach (ErrorRecord rec in powerShell.Streams.Error.ReadAll())
                {
                    session.Log(rec.Exception.Message);
                    return ActionResult.Failure;
                }
            }

            return ActionResult.Success;
        }

        static void SetProcessExecution(Session session, string level)
        {
            string byPass = string.Format("set-executionpolicy {0} -Scope Process -Force", level);
            PowerShell pwInst = PowerShell.Create();
            pwInst.AddScript(byPass);
            pwInst.Invoke();
        }
    }
}
