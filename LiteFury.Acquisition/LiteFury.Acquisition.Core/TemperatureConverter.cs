namespace LiteFury.Acquisition.Core;

public static class TemperatureConverter
{        // To measure the die temperature, a bipolar diode is used inside the FPGA.
    // The Basic thermal voltage equation for the diode is:  Vt = (k * T) / q
    // In Analog-to-Digital Converter User Guide (UG480) these physical constants k, q, and a ln(10) into the factor 503.975
    // C° = K - 273.15.
    // 7 Series FPGAs and Zynq-7000 SoC XADC Dual 12-Bit 1 MSPS Analog-to-Digital Converter User Guide (UG480):
    // https://docs.amd.com/r/qOeib0vlzXa1isUAfuFzOQ/k~CVcrTI5YXEUXVL5p8leQ?section=XREF_93944_Equation1_1
    
    private const float ScaleFactor = 0.12304077f; // precalculated: 503.975f / 4096.0f
    private const float KelvinOffset = 273.15f;
    public static float ToDegreesCelsius(uint raw)
    {
        return raw * ScaleFactor - KelvinOffset;
    }
}