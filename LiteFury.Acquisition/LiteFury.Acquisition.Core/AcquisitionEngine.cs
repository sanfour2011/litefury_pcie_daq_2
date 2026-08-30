using System.Collections.Concurrent;

namespace LiteFury.Acquisition.Core;

public class AcquisitionEngine : IDisposable
{
    private readonly Csr _csr;
    private readonly Irq _irq;

    private readonly BramData _bramData;

    //save the entire array instead of single elements in a loop to make it faster
    //private readonly BlockingCollection<uint[]> _bramDataQueue = new BlockingCollection<uint[]>(boundedCapacity: 2);

    public event Action<uint[]> SamplesReady;

    public AcquisitionEngine()
    {
        _csr = new Csr();
        _irq = new Irq();
        _bramData = new BramData();
    }

    private void OnIrqRceived(IrqChannel channel)
    {
        uint[] data = null;
        switch (channel)
        {
            case IrqChannel.A:
                _bramData.ReadBramData(BramChannel.A);
                _csr.ClearIrqPendingA();
                break;
            case IrqChannel.B:
                _bramData.ReadBramData(BramChannel.B);
                _csr.ClearIrqPendingA();
                break;
            default:
                break;
        }

        if (data != null)
            SamplesReady?.Invoke(data);
    }

    public void Dispose()
    {
        _csr.Dispose();
        _irq.Dispose();
        _bramData.Dispose();
    }
}