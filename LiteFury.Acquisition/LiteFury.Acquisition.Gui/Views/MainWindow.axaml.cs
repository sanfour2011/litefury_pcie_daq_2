using Avalonia.Controls;

namespace LiteFury.Acquisition.Gui.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        WindowState = WindowState.Maximized;

            
        
            // https://scottplot.net/quickstart/wpf/
            // <ContentControl Content="{Binding PlotControl, Mode=OneTime}"/>
    }
    
    
}