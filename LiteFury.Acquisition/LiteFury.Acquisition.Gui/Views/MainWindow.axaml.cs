using Avalonia.Controls;

namespace LiteFury.Acquisition.Gui.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        WindowState = WindowState.Maximized;

        TempPlot.Plot.Add.Signal(ScottPlot.Generate.Sin());
        TempPlot.Plot.DataBackground.Color = ScottPlot.Color.FromHex("#F0F8FF"); //   AliceBlue: #F0F8FF
        TempPlot.Plot.FigureBackground.Color = ScottPlot.Color.FromHex("#F0F8FF");
        TempPlot.Plot.XLabel("Samples");
        TempPlot.Plot.YLabel("Temperature (°C)");
        TempPlot.Plot.Axes.AutoScale();
    }
}