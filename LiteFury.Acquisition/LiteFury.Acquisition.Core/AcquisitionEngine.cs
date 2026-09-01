using System.Collections.Concurrent;
using System.Diagnostics;

namespace LiteFury.Acquisition.Core;

public class AcquisitionEngine : IDisposable
{
    private readonly Csr _csr;
    private readonly Irq _irq;

    private readonly BramData _bramData;

    //save the entire array instead of single elements in a loop to make it faster
    //private readonly BlockingCollection<uint[]> _bramDataQueue = new BlockingCollection<uint[]>(boundedCapacity: 2);

    public event Action<uint[], BramChannel>? SamplesReady;
    public event Action<Exception>? ErrorOccured;

    public uint ReadStatus => _csr.ReadStatus();
    public uint ReadControl => _csr.ReadControl();
    public void Start() => _csr.WriteControl(1 << PcieDevice.ENABLE_ACQ_BIT);
    public void Stop() => _csr.WriteControl(0);

    public AcquisitionEngine()
    {
        _csr = new Csr();
        _irq = new Irq();
        _bramData = new BramData();
        _irq.IrqReceived += OnIrqRceived;
        _irq.ErrorOccured += ex => { ErrorOccured?.Invoke(ex); };
    }

    private void OnIrqRceived(IrqChannel channel)
    {
        try
        {
            uint[]? data = null;
            var bramChannel = channel switch
            {
                IrqChannel.A => BramChannel.A,
                IrqChannel.B => BramChannel.B,
                _ => throw new ArgumentOutOfRangeException(nameof(channel), channel, null),
            };

            data = _bramData.ReadBramData(bramChannel);

            if (data != null)
                SamplesReady?.Invoke(data, bramChannel);

            // A bottle neck: Invoke blocks until subscriber-Method returns/finish,
            // Subscriber must return before the next buffer fills up
            //todo add stopwatch to measure entire processing time to adapt 
            // XADC sampling rate/Averaging (may be dynamically with drp)
        }
        catch (Exception e)
        {
            ErrorOccured?.Invoke(e);
        }
        finally //make sure irq-bits are cleared even if subscribers fails to prevent buffer overflows and keeping acquisition running.
        {
            switch (channel)
            {
                case IrqChannel.A: _csr.ClearIrqPendingA(); break;
                case IrqChannel.B: _csr.ClearIrqPendingB(); break;
            }
        }
    }

    public void Reset()
    {
        uint controlReg = _csr.ReadControl();
        _csr.WriteControl(controlReg | (1<<PcieDevice.SOFT_RESET_BIT));
        Thread.Sleep(10);
        _csr.WriteControl(controlReg); 
    }

    public void Dispose()
    {
        _irq.IrqReceived -= OnIrqRceived;
        _csr.Dispose();
        _irq.Dispose();
        _bramData.Dispose();
    }
}