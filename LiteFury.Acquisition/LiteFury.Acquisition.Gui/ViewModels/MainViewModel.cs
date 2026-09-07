using System;
using System.Collections.Generic;
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
   
    public MainViewModel()
    {
        _pollTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(100) };
        _pollTimer.Tick += UpdateStatus;
        _pollTimer.Start();
        _acqEngine.SamplesReady += (values, channel) =>
        {
            //Post is non Blocking: Fire and Forget: https://docs.avaloniaui.net/docs/app-development/threading#post-fire-and-forget
            Dispatcher.UIThread.Post(() => 
            {
                UpdateStatus(this, EventArgs.Empty);
                UpdateChartValues(values);
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

    // private void UpdateChartValues()
    // {
    //     var converted = new float[_temp.Length];
    //     for (int i = 0; i < _temp.Length; i++)
    //         converted[i] = TemperatureConverter.ToDegreesCelsius(_temp[i]);
    //
    //     var averaged = SampleAverager.Average(converted, Convert.ToUInt32(AveragingFactor));
    //     foreach (var value in averaged)
    //         TemperatureHistory.Add(value);
    //
    //     OnPropertyChanged((nameof(ChartValues)));
    // }
}