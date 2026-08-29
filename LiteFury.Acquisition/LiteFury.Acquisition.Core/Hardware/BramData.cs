using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles; // Strange but works also with linux

namespace LiteFury.Acquisition.Core;

public enum BramChannel {A,B}
public class BramData:IDisposable
{
    private SafeFileHandle _fhandle;

    public BramData()
    {
        // _fhandle = File.OpenHandle(PcieDevice.BRAM_RESOURCE_FILE_DMA);
        _fhandle = File.OpenHandle(
            PcieDevice.BRAM_RESOURCE_FILE_DMA,
            FileMode.Open,
            FileAccess.Read,
            FileShare.ReadWrite,
            FileOptions.WriteThrough
        );
        if (_fhandle.IsInvalid)
            Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
        
    }

    public void Dispose()
{
    _fhandle.Dispose();
}

public uint[] ReadBramDatga(BramChannel channel)
{
    // var buffer = new byte[PcieDevice.BRAM_WORDS * 4 / 2]; 
    var buffer = new uint[PcieDevice.BRAM_WORDS /  2]; 

    Span<byte> byteBuffer = MemoryMarshal.AsBytes(buffer.AsSpan());
        
    var baseAddr = channel switch
    {
        BramChannel.A => PcieDevice.BRAM_A_BASE_DMA,
        BramChannel.B => PcieDevice.BRAM_B_BASE_DMA,
        _ => throw new ArgumentOutOfRangeException(nameof(channel), channel, null),

    };
    RandomAccess.Read(_fhandle, byteBuffer, baseAddr);

    return buffer;
}
}