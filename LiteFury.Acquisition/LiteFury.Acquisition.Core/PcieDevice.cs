namespace LiteFury.Acquisition.Core;

public static class PcieDevice
{
//     // Sysfs path to the PCIe BAR2 resource, memory-mapped for register/BRAM access.
// #define PCI_RESOURCE2_PATH "/sys/bus/pci/devices/0000:01:00.0/resource2"
    public const string PCI_RESOURCE2_PATH = "/sys/bus/pci/devices/0000:01:00.0/resource2";

// // use only with mmap xdma0_bypass has no engine! pread, pwrite, ... needs an engine to run otherwise it returns (EINVAL)
// #define CSR_RESOURCE_FILE "/dev/xdma0_bypass"
    public const string CSR_RESOURCE_FILE = "/dev/xdma0_bypass";

// #define USR_IRQ_EVENT_A_FILE "/dev/xdma0_events_0"
    public const string USR_IRQ_EVENT_A_FILE = "/dev/xdma0_events_0";

// #define USR_IRQ_EVENT_B_FILE "/dev/xdma0_events_1"
    public const string USR_IRQ_EVENT_B_FILE = "/dev/xdma0_events_1";


// // When using DMA Engines:
// #define CSR_RESOURCE_FILE_DMA "/dev/xdma0_c2h_0"
    public const string CSR_RESOURCE_FILE_DMA = "/dev/xdma0_c2h_0";

// #define BRAM_RESOURCE_FILE_DMA  "/dev/xdma0_c2h_0"
    public const string BRAM_RESOURCE_FILE_DMA = "/dev/xdma0_c2h_0";

// #define SR_BASE_DMA 0x44A00000 // Address from Vivado Address Edito
    public const long SR_BASE_DMA = 0x44A00000;

// #define BRAM_BASE_DMA 0x44A02000
    public const long BRAM_BASE_DMA = 0x44A02000;

    // /////////////////////////
//
// #define ENABLE_ACQ_BIT           0
    public const int ENABLE_ACQ_BIT = 0;
// #define SOFT_RESET_BIT           1
    public const int SOFT_RESET_BIT = 1;
// #define STATUS_RUNNING_BIT       0
    public const int STATUS_BIT_RUNNING = 0;
// #define STATUS_BUFFER_FULL_BIT   1
    public const int STATUS_BUFFER_FULL_BIT = 1;
// #define STATUS_IRQ_PENDING_A_BIT 2
    public const int STATUS_IRQ_PENDING_A_BIT = 2;
// #define STATUS_IRQ_PENDING_B_BIT 3
    public const int STATUS_IRQ_PENDING_B_BIT = 3;
//
//
// #define XDMA_PCIe_to_AXI_Translation_Offset 0x44A00000 
    public const long XDMA_PCIe_to_AXI_Translation_Offset = 0x44A00000;
// #define SR_OFFSET 0x04
    public const int SR_OFFSET = 0x04;
// #define CR_OFFSET 0x00
    public const int CR_OFFSET = 0x00;
// #define BRAM_OFFSET 0x2000
    public const int BRAM_OFFSET = 0x2000;
//
// #define BRAM_WORDS 2048
    public const int BRAM_WORDS = 2048;


}