using JetBrains.Annotations;
using LiteFury.Acquisition.Core;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace LiteFury.Acquisition.Core.Tests;

[TestClass]
[TestSubject(typeof(SampleAverager))]
public class SampleAveragerTest
{

    [TestMethod]
    public void Average()
    {
        uint[] inputData = new uint[] { 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 };
        int windowSize = 3;
        
        float[] expected = new float[] { 20, 30, 40, 50, 60, 70, 80, 90 };
        float[] actual = SampleAverager.Average(inputData, windowSize);
        
        Assert.AreEqual(expected.Length, actual.Length);
        CollectionAssert.AreEqual(expected,actual);
    }
}