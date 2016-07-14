using RGiesecke.DllExport;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace ConfigDumpFileIO
{
    public class DLLEntry
    {
        static StringBuilder sB = new StringBuilder("");
        static ManualResetEvent mre = new ManualResetEvent(false);
        [DllExport("_RVExtension@12", CallingConvention = System.Runtime.InteropServices.CallingConvention.Winapi)]
        public static void RVExtension(StringBuilder output, int outputSize, [MarshalAs(UnmanagedType.LPStr)] string function)
        {
            var colonIndex = function.IndexOf(":");
            var operationType = function.Substring(0, colonIndex);
            var stringToWrite = function.Substring(colonIndex + 1, function.Length - colonIndex - 1);
            if (operationType.Equals("open"))
            {
                output.Append("true");
                return;
            }
            else if(operationType.Equals("write"))
            {
                sB.AppendLine(stringToWrite);
                output.Append("true");
                return;
            }
            else if(operationType.Equals("close"))
            {
                string assemblyFolder = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                string filePath = Path.Combine(assemblyFolder, "ConfigDump.cpp");
                File.WriteAllText(filePath, sB.ToString());
                sB = new StringBuilder("");
                output.Append("true");
                return;
            }

            output.Append("false");
        }
    }
}
