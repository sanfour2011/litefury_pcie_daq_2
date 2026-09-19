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
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {

        try
        {
            return Int32.Parse(value.ToString());
        }
        catch (Exception e)
        {
            new BindingNotification(e, BindingErrorType.DataValidationError);
        }

        return null;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}