using CommunityToolkit.Mvvm.ComponentModel;

namespace LiteFury.Acquisition.Gui.ViewModels;

public partial class MainViewModel
{
    [ObservableProperty] public partial string StatusText { get; set; } = "0x000000";
    [ObservableProperty] public partial string ControlText { get; set; } = "0x000000";
    [ObservableProperty] public partial bool IsBufferFull { get; set; } = true;
    [ObservableProperty] public partial bool IsRunning { get; set; } = false;
    [ObservableProperty] public partial int XadcAveragingFactor { get; set; }
    [ObservableProperty] public partial int SoftAveragingFactor { get; set; } = 1;
    
    partial void OnXadcAveragingFactorChanged(int value) => _acqEngine.SetXadcAverage(value);

    [ObservableProperty] 
    [NotifyPropertyChangedFor(nameof(AnyIrqPending))]
    public partial bool IrqPendingA { get; set; } = false;
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(AnyIrqPending))]
    public partial bool IrqPendingB { get; set; } = false;
    public  bool AnyIrqPending =>  IrqPendingA || IrqPendingB;
}