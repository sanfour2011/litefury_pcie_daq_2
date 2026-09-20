using System.Collections.Concurrent;
using System.Data;
using System.Diagnostics;

namespace LiteFury.Acquisition.Core;

public class AcquisitionEngine : IDisposable
{
    private readonly Csr _csr;
    private readonly Irq _irq;

    private readonly BramData _bramData;

    public event Action<uint[], BramChannel>? SamplesReady;
    public event Action<Exception>? ErrorOccured;

    public uint ReadStatus => _csr.ReadStatus();
    public uint ReadControl => _csr.ReadControl();
    public void Start() => _csr.SetAcquisitionEnabled(true);
    public void Stop() => _csr.SetAcquisitionEnabled(false);

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
        _csr.TriggerSoftReset();
        Thread.Sleep(10);
    }

    public void Dispose()
    {
        _irq.IrqReceived -= OnIrqRceived;
        _csr.Dispose();
        _irq.Dispose();
        _bramData.Dispose();
    }

    public void SetXadcAverage(int avg) => _csr.SetXadcAvg(avg);
    
}