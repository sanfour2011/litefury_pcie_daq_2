using System;
using System.Linq;
using CommunityToolkit.Mvvm.ComponentModel;
using LiteFury.Acquisition.Core;
using ScottPlot.Avalonia;
using ScottPlot.Plottables;

namespace LiteFury.Acquisition.Gui.ViewModels;

public partial class MainViewModel
{
    public static readonly int Capacity = 512;

    public float[] ChartValues => TemperatureHistory.GetLatest(100);

    //https://scottplot.net/cookbook/5/LiveData/DataStreamerQuickstart/  under Others
    public AvaPlot PlotControl { get; } = new AvaPlot();
    private DataStreamer _streamer;

    [ObservableProperty] public partial SampleHistory TemperatureHistory { get; set; } = new SampleHistory(Capacity);

    private void InitializeChart()
    {
        PlotControl.Plot.DataBackground.Color = ScottPlot.Color.FromHex("#F0F8FF");
        PlotControl.Plot.FigureBackground.Color = ScottPlot.Color.FromHex("#F0F8FF");
        PlotControl.Plot.XLabel("Samples");
        PlotControl.Plot.YLabel("Temperature (°C)");
        PlotControl.Plot.Axes.DateTimeTicksBottom();
        _streamer = PlotControl.Plot.Add.DataStreamer(100);
    }

    private double ymin = float.MaxValue, ymax = float.MinValue;

    private void UpdateChartValues(uint[] values)
    {
        var converted = new float[values.Length];
        for (int i = 0; i < values.Length; i++)
            converted[i] = TemperatureConverter.ToDegreesCelsius(values[i]);

        var averaged = SampleAverager.Average(converted, Convert.ToUInt32(AveragingFactor));
        foreach (var value in averaged)
            TemperatureHistory.Add(value);

        OnPropertyChanged((nameof(ChartValues)));

        // ymin = Double.Round(ChartValues.Min(),MidpointRounding.ToNegativeInfinity) >  Double.Round(ChartValues.Min(),MidpointRounding.ToNegativeInfinity)? 
        ymin = ymin > Math.Floor(ChartValues.Min()) ? Math.Floor(ChartValues.Min()) : ymin;
        ymax = ymax < Math.Ceiling(ChartValues.Max()) ? Math.Ceiling(ChartValues.Max()) : ymax;

        // PlotControl.Plot.Clear();
        // PlotControl.Plot.Add.Signal(ChartValues);
        _streamer.Add(ChartValues);
        PlotControl.Plot.Axes.AutoScale();
        PlotControl.Plot.Axes.SetLimitsY(ymin, ymax);
        _streamer.ViewWipeRight();

        PlotControl.Refresh();
    }
}