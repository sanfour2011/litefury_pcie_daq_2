namespace LiteFury.Acquisition.Core;

public enum IrqChannel
{
    A,
    B
};

public class Irq : IDisposable
{
    public event Action<IrqChannel> IrqReceived;
    public event Action<Exception> ErrorOccured;
    private Stream _fsA;
    private Stream _fsB;

    public Irq()
    {
        _fsA = new FileStream(
            PcieDevice.USR_IRQ_EVENT_A_FILE,
            FileMode.Open,
            FileAccess.Read,
            FileShare.ReadWrite);
        _fsB = new FileStream(
            PcieDevice.USR_IRQ_EVENT_B_FILE,
            FileMode.Open,
            FileAccess.Read,
            FileShare.ReadWrite);

        new Thread(MonitorChannelA) { IsBackground = true }.Start();
        new Thread(MonitorChannelB) { IsBackground = true }.Start();
    }

    public void MonitorChannelA()
    {
        var buffer = new byte[4];
        try
        {
            while (true)
            {
                _fsA.Read(buffer, 0, 4);
                IrqReceived?.Invoke(IrqChannel.A);
            }
        }
        catch (Exception e)
        {
            ErrorOccured?.Invoke(e);
        }
    }

    public void MonitorChannelB()
    {
        var buffer = new byte[4];
        try
        {
            while (true)
            {
                _fsB.Read(buffer, 0, 4);
                IrqReceived?.Invoke(IrqChannel.B);
            }
        }
        catch (Exception e)
        {
            ErrorOccured?.Invoke(e);
        }
    }

    public void Dispose()
    {
        _fsA.Dispose();
        _fsB.Dispose();
    }
}