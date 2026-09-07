using System;
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
        _acqEngine.Stop();
        UpdateStatus(this, EventArgs.Empty);
    }

    [RelayCommand]
    private void SetAvg(int avg)
    {
        AveragingFactor = avg;
    }

}