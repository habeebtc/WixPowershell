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

namespace PowershellCA
{
    public partial class CustomActions
    {
        public static ActionResult ExecPowershell(Session session, string scriptName, string functionName = "")
        {
            //System.Diagnostics.Debugger.Launch();
            PowerShell powerShell = PowerShell.Create();
            

            //disable powershell restrictions for the CA session
            SetProcessExecution(session, "Unrestricted");

            Log(session,string.Format("Start Exec Powershell script {0}, function {1}", scriptName, functionName) );
            string include = string.Format(". \".\\{0}\"", scriptName);
            string param = "Param([Microsoft.Deployment.WindowsInstaller.Session]$session)";
            string callFunc = string.Format("{0}($session)",functionName);
            string loadInterop = String.Format("$msi = Add-Type -AssemblyName \"Microsoft.Deployment.WindowsInstaller\" -PassThru");

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
                //scriptbody += loadInterop + Environment.NewLine;
                scriptbody += callFunc + Environment.NewLine;
                powerShell.AddScript(scriptbody);
                powerShell.AddArgument(session);
            }

            try
            { 
                System.Collections.ObjectModel.Collection<PSObject> results = powerShell.Invoke();

                foreach (InformationRecord rec in powerShell.Streams.Information.ReadAll())
                {
                    Log(session,rec.MessageData.ToString());
                }

                if (powerShell.Streams.Error.Count > 0)
                {
                    Log(session,string.Format("Script Failed with {0} errors", powerShell.Streams.Error.Count));
                    foreach (ErrorRecord rec in powerShell.Streams.Error.ReadAll())
                    {
                        Log(session,rec.Exception.Message);
                        Log(session, rec.ScriptStackTrace);
                        Log(session, rec.ToString());
                    }
                    return ActionResult.Failure;
                }
            }
            catch(Exception ex)
            {
                Log(session, "Powershell Execution failed!");
                Log(session, ex.Message);
                Log(session, ex.StackTrace);
            }

            return ActionResult.Success;
        }

        static void SetProcessExecution(Session session,string level)
        {
            string byPass = string.Format("set-executionpolicy {0} -Scope Process -Force",level);
            PowerShell pwInst = PowerShell.Create();
            pwInst.AddScript(byPass);
            pwInst.Invoke();
        }

        static void Log(Session session, string msg)
        {
            Record rec = new Record(1);
            rec.SetString(1, msg);
            MessageResult result = session.Message(InstallMessage.Info, rec);
            if (result == 0)
            {
                CELog(session, msg);
            }
        }

        public static ActionResult CELog(Session session, string Message)
        {
            string LogProp = Guid.NewGuid().ToString();
            session["CELog-" + LogProp.Substring(0, 5)] = Message;
            return ActionResult.Success;
        }
    }

}
