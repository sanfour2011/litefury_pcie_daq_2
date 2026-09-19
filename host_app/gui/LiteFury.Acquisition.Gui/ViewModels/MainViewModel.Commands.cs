using System;
using System.Diagnostics;
using CommunityToolkit.Mvvm.Input;

namespace LiteFury.Acquisition.Gui.ViewModels;

public partial class MainViewModel : ViewModelBase
{
    [RelayCommand]
    private void Start()
    {
        _acqEngine.Start();
        UpdateStatus(this, EventArgs.Empty);
    }

    [RelayCommand]
    private void Stop()
    {
        _acqEngine.Stop();
        UpdateStatus(this, EventArgs.Empty);
    }

    [RelayCommand]
    private void Reset()
    {
        _acqEngine.Reset();
        UpdateStatus(this, EventArgs.Empty);
    }

    [RelayCommand]
    private void SetAvg(string avgStr)
    {
        //int.Parse(avgStr);

        var avg = avgStr switch
        {
            "1" => 0,
            "16" => 1,
            "64" => 2,
            "256" => 3
        };
        SetAvg(avg);
    }

    private void SetAvg(int value) => AveragingFactor = value;
 
}