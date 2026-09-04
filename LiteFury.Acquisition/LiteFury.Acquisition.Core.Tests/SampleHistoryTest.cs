using JetBrains.Annotations;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace LiteFury.Acquisition.Core.Tests;

[TestClass]
[TestSubject(typeof(SampleHistory))]
public class SampleHistoryTest
{
    private float[] _testArray = new float[] { 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 };
    private SampleHistory _history;

    [ClassInitialize]
    public void InitSampleHistoryTest()
    {
        _history = new SampleHistory(10);
    }

    [TestMethod]
    public void Add()
    {
        foreach (var value in _testArray)
            _history.Add(value);
        
    }

    
    [TestMethod]
    public void GetChunc()
    {
        
    }

}