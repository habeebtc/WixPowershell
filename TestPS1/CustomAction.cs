using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.Deployment.WindowsInstaller;

namespace TestPS1
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
    }
}
