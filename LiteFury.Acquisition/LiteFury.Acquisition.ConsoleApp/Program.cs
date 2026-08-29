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
        using (var handle = File.OpenHandle(PcieDevice.BRAM_RESOURCE_FILE_DMA))
        {
            var buffer = new byte[2048 * 4 / 2];
            RandomAccess.Read(handle, buffer, PcieDevice.BRAM_A_BASE_DMA);
            Console.WriteLine("--- Buffer A ---");
            for (var i = 0; i < buffer.Length; i = i + 4)
                Console.WriteLine($"{BitConverter.ToUInt32(buffer, i):X8}");

            Console.WriteLine("--- Buffer B ---");
            RandomAccess.Read(handle, buffer, PcieDevice.BRAM_B_BASE_DMA);
            for (var i = 0; i < buffer.Length; i = i + 4)
                Console.WriteLine($"{BitConverter.ToUInt32(buffer, i):X8}");
        }

        var fd = Libc.open(PcieDevice.CSR_RESOURCE_FILE, Libc.O_RDONLY | Libc.O_SYNC);
        if (fd < 0)
            Console.WriteLine($"Error fd={fd}!");
        var map = Libc.mmap(IntPtr.Zero, 8, Libc.PROT_READ, Libc.MAP_SHARED, fd, 0);
        Libc.close(fd);
        if (map == Libc.MAP_FAILED)
            Console.WriteLine("MAP FAILED");

        var status_reg = (uint)Marshal.ReadInt32(map, 4);
        Libc.munmap(map, 8);
        Console.WriteLine($"status_reg: {status_reg}");

        using var fs = new FileStream(
            PcieDevice.USR_IRQ_EVENT_A_FILE,
            FileMode.Open,
            FileAccess.Read,
            FileShare.ReadWrite);

         var irq = new byte[4];
        var count = fs.Read(irq, 0, 4); // blockiert, bis IRQ kommt
        Console.WriteLine($"IRQ count: {BitConverter.ToUInt32(irq)}");


    }
}