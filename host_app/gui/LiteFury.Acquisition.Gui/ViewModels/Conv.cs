using System;
using System.Globalization;
using Avalonia.Data;
using Avalonia.Data.Converters;

namespace LiteFury.Acquisition.Gui.ViewModels;

public static class Conv
{
    public static readonly FuncValueConverter<bool, string> Bit = new(x => x ? "1" : "0");
}

public class IsEqualConverter : IValueConverter
{
    public static readonly IsEqualConverter Instance = new IsEqualConverter();
    
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int i && int.TryParse(parameter as string, out var result))
            return i == result;
        return false;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is bool b)
            if (b && int.TryParse(parameter as string, out int result))
                return result;
        
        return BindingOperations.DoNothing;
    }
}