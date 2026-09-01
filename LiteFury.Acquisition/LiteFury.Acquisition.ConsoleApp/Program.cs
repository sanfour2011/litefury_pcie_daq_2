using System.Collections.Concurrent;
using System.IO.MemoryMappedFiles;
using System.Runtime.InteropServices;
using LiteFury.Acquisition.Core;
using LiteFury.Acquisition.Core.Interop;
using Microsoft.Win32.SafeHandles;

namespace LiteFury.Acquisition.ConsoleApp;

internal class Program
{
    private static readonly SemaphoreSlim _semaphoreSlim = new SemaphoreSlim(1, 1);

    private static void Main(string[] args)
    {
        Console.WriteLine("Hello, World!");

        var myAcqEng = new AcquisitionEngine();
        myAcqEng.ErrorOccured += exception => Console.WriteLine($" {exception.Message}");
        ConcurrentQueue<uint> queueA = new ConcurrentQueue<uint>();
        ConcurrentQueue<uint> queueB = new ConcurrentQueue<uint>();

        myAcqEng.SamplesReady += (data, channel) =>
        {
            var target = channel == BramChannel.A ? queueA : queueB;
            foreach (var value in data)
                target.Enqueue(value);
        };

        myAcqEng.Start();

        while (!Console.KeyAvailable)
        {
            if (queueB.IsEmpty && queueA.IsEmpty)
                myAcqEng.Start();
            else
                myAcqEng.Stop();
            
            ConcurrentQueue<uint> target;
            if (!queueA.IsEmpty)
                target = queueA;
            else if (!queueB.IsEmpty)
                target = queueB;
            else
                continue;

            if (!target.IsEmpty)
            {
                Console.ForegroundColor = target == queueA ? ConsoleColor.DarkRed : ConsoleColor.Cyan;
                Console.WriteLine($"======= DATA {(target == queueA ? "A" : "B")}({target.Count}) =======");
           
                while (target.TryDequeue(out uint value))
                    Console.Write($"{value:X8}\t");

                Console.WriteLine("\n");
                Console.ResetColor();
            }


            Thread.Sleep(22);
        }

        Console.ReadKey();

        myAcqEng.Stop();

        myAcqEng.Dispose();
    }
}