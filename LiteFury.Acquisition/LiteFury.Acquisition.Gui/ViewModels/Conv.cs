using Avalonia.Data.Converters;

namespace LiteFury.Acquisition.Gui.ViewModels;

public static class Conv 
{
    public static readonly FuncValueConverter<bool, string> Bit = new(x => x ? "1" : "0");
}