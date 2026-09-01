using System.Collections.Concurrent;
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


        var myAcqEng = new AcquisitionEngine();
        myAcqEng.ErrorOccured += exception => Console.WriteLine($" {exception.Message}");
        BlockingCollection<uint> A = new BlockingCollection<uint>(1024);
        BlockingCollection<uint> B = new BlockingCollection<uint>(1024);
        
        myAcqEng.SamplesReady += (data, channel) =>
        {
            Console.WriteLine($"======= DATA {channel.ToString()} =======");
            foreach (var batch in data.Chunk(8))
            {
                if (channel == BramChannel.A)
                    Console.ForegroundColor = ConsoleColor.DarkRed;
                else
                    Console.ForegroundColor = ConsoleColor.Cyan;
                foreach (var value in batch)
                    Console.Write($"{value:X8}\t");
                Console.WriteLine();
            }

        };

        myAcqEng.Start();

        Console.ReadKey();

        myAcqEng.Stop();
        myAcqEng.Dispose();
    }
}