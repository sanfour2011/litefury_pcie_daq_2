using LiteFury.Acquisition.Core;
using System.IO.MemoryMappedFiles;

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

        using (var mmf = MemoryMappedFile.CreateFromFile(PcieDevice.CSR_RESOURCE_FILE, FileMode.Open, null,8 ))
        {
            using (var accessor = mmf.CreateViewAccessor(PcieDevice.SR_OFFSET, 4))
            {
                uint statusReg  = accessor.ReadUInt32(0);
                Console.WriteLine($"STATUS: {statusReg:X8}");
                
            }
        }
    }
}