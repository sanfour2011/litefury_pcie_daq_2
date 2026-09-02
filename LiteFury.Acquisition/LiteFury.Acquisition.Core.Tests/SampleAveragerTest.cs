using JetBrains.Annotations;
using LiteFury.Acquisition.Core;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace LiteFury.Acquisition.Core.Tests;

[TestClass]
[TestSubject(typeof(SampleAverager))]
public class SampleAveragerTest
{

    [TestMethod]
    [DataRow(new uint[] { 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 },3u,new float[] {20, 30, 40, 50, 60, 70, 80, 90})]
    [DataRow(new uint[] { 10, 20, 30 }, 1u, new float[] { 10, 20, 30 })]
    [DataRow(new uint[] { 10, 20, 30 }, 3u, new float[] { 20 })]
    [DataRow(new uint[] { 10, 20 }, 5u, new float[] { })] // Window Size > array length
    [DataRow(new uint[] { }, 3u, new float[] { })]       // Empty array
    public void Average(uint[] inputData,uint windowSize, float[] expected)
    {
        float[] actual = SampleAverager.Average(inputData, windowSize);
        
        Assert.AreEqual(expected.Length, actual.Length);
        CollectionAssert.AreEqual(expected,actual);
    }
}