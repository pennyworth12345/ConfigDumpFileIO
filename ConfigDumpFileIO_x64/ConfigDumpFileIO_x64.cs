using RGiesecke.DllExport;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;

namespace ConfigDumpFileIO_x64
{
    public class DLLEntry
    {
        static StreamWriter outputFile;
        [DllExport("RVExtension", CallingConvention = CallingConvention.Winapi)]
        public static void RVExtension(StringBuilder output, int outputSize, [MarshalAs(UnmanagedType.LPStr)] string input)
        {
            var colonIndex = input.IndexOf(":");
            var operationType = input.Substring(0, colonIndex);
            var stringToWrite = input.Substring(colonIndex + 1, input.Length - colonIndex - 1);
            if (operationType.Equals("open"))
            {
                string assemblyFolder = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                string filePath = Path.Combine(assemblyFolder, stringToWrite);
                outputFile = new StreamWriter(filePath);
                output.Append("true");
                return;
            }
            else if (operationType.Equals("write"))
            {
                outputFile.WriteLine(stringToWrite);
                output.Append("true");
                return;
            }
            else if (operationType.Equals("close"))
            {
                outputFile.Close();
                output.Append("true");
                return;
            }

            output.Append("false");
        }
    }
}
