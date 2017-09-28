using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Reflection;
using System.Xml;
using System.Xml.Schema;
using Microsoft.Tools.WindowsInstallerXml;

namespace PowershellExtension
{
    
    public class PowershellCompiler : CompilerExtension
    {
        private XmlSchema schema;

        public PowershellCompiler()
        {
            this.schema =
               CompilerExtension.LoadXmlSchemaHelper(
                  Assembly.GetExecutingAssembly(),
                  "PowershellExtension.PowershellSchema.xsd");
        }

        public override XmlSchema Schema
        {
            get
            {
                return this.schema;
            }
        }
    }
}
