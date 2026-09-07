using System;
using CommunityToolkit.Mvvm.ComponentModel;
using LiteFury.Acquisition.Core;

namespace LiteFury.Acquisition.Gui.ViewModels;

public partial class MainViewModel
{
    public static readonly int capacity = 512;
    private uint[] _temp = new uint[capacity]; // Temp buffer to minimize event handler execution time
    public float[] ChartValues => TemperatureHistory.GetLatest(100);

    [ObservableProperty] public partial SampleHistory TemperatureHistory { get; set; } = new SampleHistory(capacity);
    
    private void UpdateChartValues(uint[] values)
    {
        var converted = new float[_temp.Length];
        for (int i = 0; i < _temp.Length; i++)
            converted[i] = TemperatureConverter.ToDegreesCelsius(_temp[i]);
        
        var averaged = SampleAverager.Average(converted, Convert.ToUInt32(AveragingFactor));
        foreach (var value in averaged)
            TemperatureHistory.Add(value);
        
        OnPropertyChanged((nameof(ChartValues)));
    }
}