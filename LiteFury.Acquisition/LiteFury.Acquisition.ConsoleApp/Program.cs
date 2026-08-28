using LiteFury.Acquisition.Core;
namespace LiteFury.Acquisition.ConsoleApp;

class Program
{
    static void Main(string[] args)
    {
        Console.WriteLine("Hello, World!");
        using (var handle = File.OpenHandle(PcieDevice.BRAM_RESOURCE_FILE_DMA, FileMode.Open, FileAccess.Read))
        {
            var buffer = new byte[4];
            RandomAccess.Read(handle, buffer, PcieDevice.BRAM_BASE_DMA);
           
            Console.WriteLine($"{BitConverter.ToUInt32(buffer, 0):X8}");
            
        }
    }
}