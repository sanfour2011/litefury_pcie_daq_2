using System;
using Avalonia.Media;
using Avalonia.Threading;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using LiteFury.Acquisition.Core;
using Tmds.DBus.Protocol;


namespace LiteFury.Acquisition.Gui.ViewModels;

public partial class MainViewModel : ViewModelBase
{
    private readonly AcquisitionEngine _acqEngine = new AcquisitionEngine();
    private readonly DispatcherTimer _pollTimer;
    [ObservableProperty] public partial string StatusText { get; set; } = "0x000000";
    [ObservableProperty] public partial string ControlText { get; set; } = "0x000000";
    [ObservableProperty] public partial int AveragingFactor  { get; set; } = 1;
    [ObservableProperty] public partial bool IsBufferFull { get; set; } = false;
    [ObservableProperty] public partial bool IsRunning { get; set; } = false;
    [ObservableProperty] public partial bool IrqPendingA { get; set; } = false;
    [ObservableProperty] public partial bool IrqPendingB { get; set; } = false;
    [ObservableProperty] public partial float[] TemperatureHistory { get; set; } = new float[512];

    [RelayCommand] private void Start() { _acqEngine.Start(); UpdateStatus(this, EventArgs.Empty); }
    [RelayCommand] private void Stop() { _acqEngine.Stop(); UpdateStatus(this, EventArgs.Empty); }
    [RelayCommand] private void Reset() { _acqEngine.Stop(); UpdateStatus(this, EventArgs.Empty); }

    [RelayCommand] private void SetAvg(int avg) { AveragingFactor = avg; }
    
    
    //[ObservableProperty] public partial string Greeting { get; set; } = "Welcome to Avalonia!";

    public MainViewModel()
    {
        _pollTimer = new DispatcherTimer { Interval =  TimeSpan.FromMilliseconds(100)};
        _pollTimer.Tick += UpdateStatus;
        _pollTimer.Start();
        _acqEngine.SamplesReady += (uints, channel) => 
        {
            Dispatcher.UIThread.Post(() =>
            {
                // Update graph 
                UpdateStatus(this,EventArgs.Empty);
            });
        };
   
        _acqEngine.ErrorOccured += exception =>
        {
            Dispatcher.UIThread.InvokeAsync(async () =>
            {
                // Error Message box
            });
        };
    }
    
    private void UpdateStatus(object? sender, EventArgs e)
    {
        var status = _acqEngine.ReadStatus;
        ControlText = $"0x{_acqEngine.ReadControl:X8}";
        StatusText = $"0x{status:X8}";
        IsRunning = (status & (1 << PcieDevice.STATUS_BIT_RUNNING)) != 0;
        IsBufferFull = (status & (1 << PcieDevice.STATUS_BUFFER_FULL_BIT)) != 0;
        IrqPendingA = (status & (1 << PcieDevice.STATUS_IRQ_PENDING_A_BIT)) != 0;
        IrqPendingB = (status & (1 << PcieDevice.STATUS_IRQ_PENDING_B_BIT)) != 0;
    }
}