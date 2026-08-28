namespace LiteFury.Acquisition.Core;

public static class PcieDevice
{
    public const int BRAM_WORDS = 2048;

//   Sysfs path to the PCIe BAR2 resource, memory-mapped for register/BRAM access.
    public const string PCI_RESOURCE2_PATH = "/sys/bus/pci/devices/0000:01:00.0/resource2";

// use only with mmap xdma0_bypass has no engine! pread, pwrite, ... needs an engine to run otherwise it returns (EINVAL)
    public const string CSR_RESOURCE_FILE = "/dev/xdma0_bypass";
    public const string USR_IRQ_EVENT_A_FILE = "/dev/xdma0_events_0";
    public const string USR_IRQ_EVENT_B_FILE = "/dev/xdma0_events_1";

// // When using DMA Engines:
    public const string CSR_RESOURCE_FILE_DMA = "/dev/xdma0_c2h_0";
    public const string BRAM_RESOURCE_FILE_DMA = "/dev/xdma0_c2h_0";
    public const long SR_BASE_DMA = 0x44A00000;
    public const long BRAM_BASE_DMA = 0x44A02000;
    
    public const long BRAM_A_BASE_DMA = BRAM_BASE_DMA;
    public const long BRAM_B_BASE_DMA = BRAM_BASE_DMA + (BRAM_WORDS/2 * sizeof(uint));
    // /////////////////////////
    public const int ENABLE_ACQ_BIT = 0;
    public const int SOFT_RESET_BIT = 1;
    public const int STATUS_BIT_RUNNING = 0;
    public const int STATUS_BUFFER_FULL_BIT = 1;
    public const int STATUS_IRQ_PENDING_A_BIT = 2;
    public const int STATUS_IRQ_PENDING_B_BIT = 3;

    public const long XDMA_PCIe_to_AXI_Translation_Offset = 0x44A00000;
    public const int SR_OFFSET = 0x04;
    public const int CR_OFFSET = 0x00;
    public const int BRAM_OFFSET = 0x2000;



}