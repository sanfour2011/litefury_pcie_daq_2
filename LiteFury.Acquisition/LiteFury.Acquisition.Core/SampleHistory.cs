using System;

namespace LiteFury.Acquisition.Core;

public class SampleHistory
{
    public int Capacity { get; }
    private int _nextWriteIdx = 0;
    private float[] _buffer;

    public SampleHistory(int capacity)
    {
        if (capacity < 1)
            throw new ArgumentOutOfRangeException(nameof(capacity));
        Capacity = capacity;
        _buffer = new float[Capacity];
    }
    
    public void Add(float value)
    {
        
        if (_nextWriteIdx >= Capacity)
            _nextWriteIdx = _nextWriteIdx % Capacity;
        
        _buffer[_nextWriteIdx++] = value;
    }

    public float[] GetLast(int count)
    {
        if (count > Capacity)
            throw new ArgumentOutOfRangeException(nameof(count) + ">" + nameof(Capacity));
        
        float[] result = new float[count];

        var readRange = (Start: _nextWriteIdx - count, End: _nextWriteIdx);
        
        int idx = 0;
        while (readRange.Start < 0)
            result[idx++] = _buffer[Capacity - readRange.Start ++];

        for (int i = readRange.Start; i < _nextWriteIdx; i++)
            result[idx++] = _buffer[i];
        
        
        return result;
    }
}