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
    private double _ymin = 20, _ymax = 50; 

    public float[] ChartValues => TemperatureHistory.GetLatest(100);

    public string LastChartValue => $"{ChartValues.Last():F1}°C";
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
        PlotControl.Plot.Axes.Bottom.TickLabelStyle.IsVisible = false;
        PlotControl.Plot.Axes.Bottom.MajorTickStyle.Length = 0;
        PlotControl.Plot.Axes.Bottom.MinorTickStyle.Length = 0;
        
        
        _streamer = PlotControl.Plot.Add.DataStreamer(100);
        _streamer.ViewScrollLeft();
        
        // _streamer.Data.SamplePeriod = 1.0 / (24 * 60 * 60); 
        // _streamer.Data.OffsetX = DateTime.Now.ToOADate();
        //
        // PlotControl.Plot.Axes.DateTimeTicksBottom();
        PlotControl.Plot.Axes.SetLimitsY(30,60);
        // PlotControl.Plot.Axes.ContinuouslyAutoscale = true;
        
        _streamer.Add(0); // Workaround: otherwise it looks ugly ylabel collides with yaxis
        PlotControl.Refresh();
    }

    // private double ymin = float.MaxValue, ymax = float.MinValue;

    private void UpdateChartValues(uint[] values)
    {
        var converted = new float[values.Length];
        for (int i = 0; i < values.Length; i++)
            converted[i] = TemperatureConverter.ToDegreesCelsius(values[i]);

        var averaged = SampleAverager.Average(converted, Convert.ToUInt32(AveragingFactor));
        foreach (var value in averaged)
            TemperatureHistory.Add(value);

        OnPropertyChanged((nameof(ChartValues)));
        OnPropertyChanged(nameof(LastChartValue));

        // ymin = Double.Round(ChartValues.Min(),MidpointRounding.ToNegativeInfinity) >  Double.Round(ChartValues.Min(),MidpointRounding.ToNegativeInfinity)? 
        // ymin = ymin > Math.Floor(ChartValues.Min()) ? Math.Floor(ChartValues.Min()) : ymin;
        // ymax = ymax < Math.Ceiling(ChartValues.Max()) ? Math.Ceiling(ChartValues.Max()) : ymax;

        // PlotControl.Plot.Clear();
        // PlotControl.Plot.Add.Signal(ChartValues);
        _streamer.Add(averaged.Select(value => (double)value).ToArray());
        // PlotControl.Plot.Axes.AutoScale();
        // PlotControl.Plot.Axes.AutoScaleY();
        _ymin = Math.Min(_ymin, Math.Floor(averaged.Min()));
        _ymax = Math.Max(_ymax, Math.Ceiling(averaged.Max()));
        PlotControl.Plot.Axes.SetLimitsY(_ymin+10, _ymax+10);
        PlotControl.Refresh();
    }
}