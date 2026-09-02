using JetBrains.Annotations;
using LiteFury.Acquisition.Core;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace LiteFury.Acquisition.Core.Tests;

[TestClass]
[TestSubject(typeof(TemperatureConverter))]
public class TemperatureConverterTest
{
    [TestMethod]
    [DataRow(0x977u, 25f)]
    [DataRow(0x000u, -273.15f)] // Min ADC Code 0 
    [DataRow(0x800u, -21.0f)]   // Negative Tempereture
    [DataRow(0x977u, 25.0f)]    // From UG480 example
    [DataRow(0xFFFu, 230.7f)] // Max 12 Bit value
    public void ToDegreesCelsius(uint input, float expected)
    {
        var actual = TemperatureConverter.ToDegreesCelsius(input);
        
        Assert.AreEqual(expected,actual, 0.2f);
    }

}