using CommunityToolkit.Mvvm.ComponentModel;

namespace LiteFury.Acquisition.Gui.ViewModels;



public partial class MainViewModel
{
    // MainViewModel.cs           – Hauptlogik, Hardware-Anbindung
    //     MainViewModel.Flags.cs     – nur die Flag-Properties (IsRunning, RunningBitText, etc.)
    // MainViewModel.Chart.cs     – nur ChartValues + zugehörige Logik
    [ObservableProperty] public partial string StatusText { get; set; } = "0x000000";
    [ObservableProperty] public partial string ControlText { get; set; } = "0x000000";
    [ObservableProperty] public partial int AveragingFactor { get; set; } = 1;
    [ObservableProperty]
    public partial bool IsBufferFull { get; set; } = true;
    [ObservableProperty] public partial bool IsRunning { get; set; } = false;
   
    [ObservableProperty] 
    [NotifyPropertyChangedFor(nameof(AnyIrqPending))]
    public partial bool IrqPendingA { get; set; } = false;
    
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(AnyIrqPending))]
    public partial bool IrqPendingB { get; set; } = false;

    public  bool AnyIrqPending =>  IrqPendingA || IrqPendingB;
}