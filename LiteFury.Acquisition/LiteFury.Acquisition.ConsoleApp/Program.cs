using System.IO.MemoryMappedFiles;
using System.Runtime.InteropServices;
using LiteFury.Acquisition.Core;
using LiteFury.Acquisition.Core.Interop;
using Microsoft.Win32.SafeHandles;

namespace LiteFury.Acquisition.ConsoleApp;

internal class Program
{
    private static void Main(string[] args)
    {
        Console.WriteLine("Hello, World!");
        
        var myCsr = new Csr();
        var myIrq = new Irq();
        myIrq.ErrorOccured += exception => Console.WriteLine($"IRQ Exception: {exception.Message}");
        myIrq.IrqReceived += channel =>
        {
            if (channel == IrqChannel.A)
                Console.WriteLine("A da!");
            else
                Console.WriteLine("B da!");
        };
        
        Console.WriteLine("Status: " + myCsr.ReadStatus());
        myCsr.WriteControl(1);
        Console.WriteLine("Status: " + myCsr.ReadStatus());
        Console.WriteLine("Wait for irq");
        Console.ReadLine();
        
        myCsr.WriteControl(0);
        Console.WriteLine("Status: " + myCsr.ReadStatus());
        
        var myBram = new BramData();
        var dataA = myBram.ReadBramData(BramChannel.A);
        var dataB = myBram.ReadBramData(BramChannel.B);
        Console.WriteLine("======= DATA A =======");
        foreach (var value in dataA)
            Console.WriteLine($"{value:X8}");       
        
        Console.WriteLine("======= DATA B =======");
        foreach (var value in dataB)
            Console.WriteLine($"{value:X8}");
        


    
    }
}