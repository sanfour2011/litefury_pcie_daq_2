using System;
using System.Linq;
using System.Runtime.Loader;
using JetBrains.Annotations;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace LiteFury.Acquisition.Core.Tests;

[TestClass]
[TestSubject(typeof(SampleHistory))]
public class SampleHistoryTest
{
   
   [TestMethod]
    public void Add()
    {
        var history = new SampleHistory(5);
        float[] values = new float[] { 10, 20, 30, 40, 50 };
        foreach (var value in values)
            history.Add(value);
        
    }

    public void GetLatest_NormalCase()
    {
        var history = new SampleHistory(5);
        float[] values = new float[] { 10, 20, 30, 40, 50 };
        foreach (var value in values)
            history.Add(value);

        CollectionAssert.AreEqual(values,history.GetLatest(5));
        CollectionAssert.AreEqual(new float[]{values.Last()},history.GetLatest(1));
        CollectionAssert.AreEqual(new float[]{},history.GetLatest(0));
        
    }

    [TestMethod]
    public void GetLatest_WrapAround()
    {
        var history = new SampleHistory(4);
        float[] values = new float[] { 10, 20, 30, 40, 50,60 };
        foreach (var value in values)
            history.Add(value);
        CollectionAssert.AreEqual(new float[]{60,50,40,30},history.GetLatest(3));
    }

    [TestMethod]
    public void Getlatest_Count_GT_Capacity()
    {
        var history = new SampleHistory(3);
        Assert.Throws<ArgumentOutOfRangeException>(() => history.GetLatest(5));
    }
}