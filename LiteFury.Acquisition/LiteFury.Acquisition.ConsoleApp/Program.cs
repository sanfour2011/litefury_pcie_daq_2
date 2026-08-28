using LiteFury.Acquisition.Core;
using System.IO.MemoryMappedFiles;
using System.Runtime.InteropServices;
using LiteFury.Acquisition.Core.Interop;

namespace LiteFury.Acquisition.ConsoleApp;

class Program
{
    static void Main(string[] args)
    {
        Console.WriteLine("Hello, World!");
        using (var handle = File.OpenHandle(PcieDevice.BRAM_RESOURCE_FILE_DMA, FileMode.Open, FileAccess.Read))
        {
            var buffer = new byte[2048 * 4 / 2];
            RandomAccess.Read(handle, buffer, PcieDevice.BRAM_A_BASE_DMA);
            Console.WriteLine("--- Buffer A ---");
            for (int i = 0; i < buffer.Length; i = i + 4)
                Console.WriteLine($"{BitConverter.ToUInt32(buffer, i):X8}");

            Console.WriteLine("--- Buffer B ---");
            RandomAccess.Read(handle, buffer, PcieDevice.BRAM_B_BASE_DMA);
            for (int i = 0; i < buffer.Length; i = i + 4)
                Console.WriteLine($"{BitConverter.ToUInt32(buffer, i):X8}");
        }

        int fd = Libc.open(PcieDevice.CSR_RESOURCE_FILE, Libc.O_RDONLY | Libc.O_SYNC);
        if (fd<0) 
            Console.WriteLine($"Error fd={fd}!");
        IntPtr map = Libc.mmap(IntPtr.Zero, (UIntPtr)8, Libc.PROT_READ, Libc.MAP_SHARED, fd, 0);
        Libc.close(fd);
        if (map == Libc.MAP_FAILED) 
            Console.WriteLine("MAP FAILED");

        uint status_reg = (uint)Marshal.ReadInt32(map, 4);
        Libc.munmap(map, (UIntPtr)8);
        Console.WriteLine($"status_reg: {status_reg}");
        // using (var mmf = MemoryMappedFile.CreateFromFile(PcieDevice.CSR_RESOURCE_FILE, FileMode.Open, null,8 ))
        // {
        //     using (var accessor = mmf.CreateViewAccessor(PcieDevice.SR_OFFSET, 4))
        //     {
        //         uint statusReg  = accessor.ReadUInt32(0);
        //         Console.WriteLine($"STATUS: {statusReg:X8}");
        //     }
        // }
    }
}