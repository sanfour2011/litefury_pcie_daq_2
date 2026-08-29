using System.Runtime.InteropServices;
using LiteFury.Acquisition.Core.Interop;

namespace LiteFury.Acquisition.Core;

public class Csr : IDisposable
{
    private const UIntPtr MEM_2_MAP = 8; //Memory to map in byte (size of CSR
    private int _fd = -1;
    private IntPtr _map;

    public Csr()
    {
        _fd = Libc.open(PcieDevice.CSR_RESOURCE_FILE, Libc.O_RDWR | Libc.O_SYNC);
        if (_fd < 0)
        {
            int errno = Marshal.GetLastPInvokeError();
            var errMsg = $"[{errno}]: {Marshal.GetPInvokeErrorMessage(errno)} {PcieDevice.CSR_RESOURCE_FILE}";
            throw errno switch
            {
                2 => new FileNotFoundException(errMsg),
                13 => new UnauthorizedAccessException(errMsg),
                _ => new InvalidOperationException(errMsg)
            };
        }

        _map = Libc.mmap(IntPtr.Zero, MEM_2_MAP, Libc.PROT_READ | Libc.PROT_WRITE, Libc.MAP_SHARED, _fd, 0);
        if (_map == Libc.MAP_FAILED)
        {
            int errno = Marshal.GetLastPInvokeError();// call before close! saves headache 
            var errMsg = $"[{errno}]: {Marshal.GetPInvokeErrorMessage(errno)} {PcieDevice.CSR_RESOURCE_FILE}";
            
            Libc.close(_fd); // when _map error, no need to keep _fd open
            _fd = -1;
            throw errno switch
            {
                13 => new UnauthorizedAccessException(errMsg),
                _ => new InvalidOperationException(errMsg)
            };        }
    }

    private void ReleaseUnmanagedResources()
    {
        if (_map != Libc.MAP_FAILED && _map != IntPtr.Zero)
        {
            Libc.munmap(_map, MEM_2_MAP);
        }
        if (_fd >= 0)
        {
            Libc.close(_fd);
            _fd = -1;
        }
    }

    public void Dispose()
    {
        ReleaseUnmanagedResources();
        GC.SuppressFinalize(this);
    }

    ~Csr()
    {
        ReleaseUnmanagedResources();
    }

    private uint ReadRegister(int offset)
    {
        return (uint)Marshal.ReadInt32(_map, offset);
    }

    private void WriteRegister(int offset, uint value)
    {
        Marshal.WriteInt32(_map,offset, (int)value);
    }
    public uint ReadStatus()
    {
        return ReadRegister(PcieDevice.SR_OFFSET);
    }

    public void WriteControl(uint value)
    {
        WriteRegister(PcieDevice.CR_OFFSET,value);
    }

    public void ClearIrqPendingA()
    {
        WriteRegister(PcieDevice.SR_OFFSET, 1<<PcieDevice.STATUS_IRQ_PENDING_A_BIT);
    }

    public void ClearIrqPendingB()
    {
        WriteRegister(PcieDevice.SR_OFFSET, 1 << PcieDevice.STATUS_IRQ_PENDING_B_BIT);
    }
    public uint ReadControl()
    {
        return ReadRegister(PcieDevice.SR_OFFSET);
    }
}