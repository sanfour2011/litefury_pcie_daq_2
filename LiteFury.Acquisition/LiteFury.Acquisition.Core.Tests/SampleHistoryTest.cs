using System;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Runtime.Loader;
using JetBrains.Annotations;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace LiteFury.Acquisition.Core.Tests;

[TestClass]
[TestSubject(typeof(SampleHistory))]
public class SampleHistoryTest
{
    private readonly float[] testValues = new float[] { 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 };

    [TestMethod]
    public void Add()
    {
        var history = new SampleHistory(5);
  
        foreach (var value in testValues)
            history.Add(value);
    }

    [TestMethod]
    [DataRow(5, new float[]{60,70,80,90,100})]
    [DataRow(1,new float[] { 100 })]
    [DataRow(0,new float[] { })]
    public void GetLatest_NormalCase(int count, float[] expected)
    {
        var history = new SampleHistory(5);
       
        foreach (var value in testValues)
            history.Add(value);

        CollectionAssert.AreEqual(expected, history.GetLatest(count)); }

    [TestMethod]
    public void GetLatest_WrapAround()
    {
        var history = new SampleHistory(8);
        foreach (var value in testValues)
            history.Add(value);
        
        CollectionAssert.AreEqual(new float[] { 70, 80,90, 100 }, history.GetLatest(4));
    }

    [TestMethod]
    public void Getlatest_Count_GT_Capacity()
    {
        var history = new SampleHistory(3);
        Assert.Throws<ArgumentOutOfRangeException>(() => history.GetLatest(5));
    }
}