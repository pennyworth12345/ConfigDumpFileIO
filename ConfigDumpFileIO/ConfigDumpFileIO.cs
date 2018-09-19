using RGiesecke.DllExport;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;

namespace ConfigDumpFileIO
{
    public class DLLEntry
    {
        static StreamWriter outputFile;
        [DllExport("_RVExtension@12", CallingConvention = CallingConvention.Winapi)]
        public static void RVExtension(StringBuilder output, int outputSize, [MarshalAs(UnmanagedType.LPStr)] string input)
        {
            byte[] bytes = Encoding.Default.GetBytes(input);
            input = Encoding.UTF8.GetString(bytes);
            var colonIndex = input.IndexOf(":");
            var operationType = input.Substring(0, colonIndex);
            var stringToWrite = input.Substring(colonIndex + 1, input.Length - colonIndex - 1);
            if (operationType.Equals("open"))
            {
                string assemblyFolder = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                string filePath = Path.Combine(assemblyFolder, stringToWrite);
                outputFile?.Close();
                try
                {
                    outputFile = new StreamWriter(filePath);
                }
                catch (System.UnauthorizedAccessException ex)
                {
                    output.Append("AccessDenied " + ex.Message);
                    return;
                }
                catch (DirectoryNotFoundException ex)
                {
                    output.Append("DirectoryNotFound " + ex.Message);
                    return;
                }
                catch (IOException ex)
                {
                    output.Append("IOException " + ex.Message);
                    return;
                }
                catch (System.Exception ex)
                {
                    output.Append("Exception " + ex.Message);
                    return;
                }
                output.Append("true");
                return;
            }
            else if(operationType.Equals("write"))
            {
                outputFile?.WriteLine(stringToWrite);
                output.Append("true");
                return;
            }
            else if(operationType.Equals("close"))
            {
                outputFile?.Close();
                outputFile = null;
                output.Append("true");
                return;
            }

            output.Append("false");
        }
    }
}
