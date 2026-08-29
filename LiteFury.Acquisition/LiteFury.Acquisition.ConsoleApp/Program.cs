using System.IO.MemoryMappedFiles;
using System.Runtime.InteropServices;
using LiteFury.Acquisition.Core;
using LiteFury.Acquisition.Core.Interop;

namespace LiteFury.Acquisition.ConsoleApp;

internal class Program
{
    private static void Main(string[] args)
    {
        Console.WriteLine("Hello, World!");

        var myCsr = new Csr();
        Console.WriteLine("Status: " + myCsr.ReadStatus());
        myCsr.WriteControl(1);
        Console.WriteLine("Status: " + myCsr.ReadStatus());
        
        myCsr.WriteControl(0);
        Console.WriteLine("Status: " + myCsr.ReadStatus());


    }
}