using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Management.Automation;
using System.Diagnostics;
using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;

namespace HostPowershell
{
    class Program
    {
        static void Main(string[] args)
        {

            ExecPowershell("mySession","test.ps1");

        }

        public static void ExecPowershell(string session, string scriptName, string functionName = "")
        {
            PowerShell powerShell = PowerShell.Create();

            Console.WriteLine("Start Exec Powershell script {0}, function {1}", scriptName, functionName);
            string include = string.Format(". \".\\{0}\"", scriptName);
            string param = "param=($session)";
            string callFunc = string.Format("{0}($session)", functionName);


            //if function name = string.empty just call the script with $session as add parameter.
            string scriptPath = Path.Combine(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location), scriptName);
            string scriptbody = string.Empty;
            if (functionName == string.Empty)
            {
                scriptbody = new StreamReader(scriptPath).ReadToEnd();
                powerShell.AddScript(scriptbody);
                powerShell.AddArgument(session);
            }
            else
            {
                scriptbody += include + Environment.NewLine;
                scriptbody += param + Environment.NewLine;
                scriptbody += callFunc + Environment.NewLine;
                powerShell.AddScript(scriptbody);
                powerShell.AddArgument(session);
            }
            System.Collections.ObjectModel.Collection<PSObject> results = powerShell.Invoke();

            foreach (InformationRecord rec in powerShell.Streams.Information.ReadAll())
            {
                Console.WriteLine(rec.MessageData.ToString());
            }

            if (powerShell.Streams.Error.Count > 0)
            {
                Console.WriteLine("Script Failed!  Begin error section.");
                foreach (ErrorRecord rec in powerShell.Streams.Error.ReadAll())
                {
                    Console.WriteLine(rec.Exception.Message);
                    return;
                }
            }

            return;
        }
    }
}
