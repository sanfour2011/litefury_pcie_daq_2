using System;
using CommunityToolkit.Mvvm.ComponentModel;
using LiteFury.Acquisition.Core;

namespace LiteFury.Acquisition.Gui.ViewModels;

public partial class MainViewModel
{
    public static readonly int Capacity = 512;
    public float[] ChartValues => TemperatureHistory.GetLatest(100);

    [ObservableProperty] public partial SampleHistory TemperatureHistory { get; set; } = new SampleHistory(Capacity);
    
    private void UpdateChartValues(uint[] values)
    {
        var converted = new float[values.Length];
        for (int i = 0; i < values.Length; i++)
            converted[i] = TemperatureConverter.ToDegreesCelsius(values[i]);
        
        var averaged = SampleAverager.Average(converted, Convert.ToUInt32(AveragingFactor));
        foreach (var value in averaged)
            TemperatureHistory.Add(value);
        
        OnPropertyChanged((nameof(ChartValues)));
    }
}