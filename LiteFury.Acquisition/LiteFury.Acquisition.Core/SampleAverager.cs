namespace LiteFury.Acquisition.Core;

public class SampleAverager
{
    public static float[] Average<T>(T[] values, uint avg)
    {
        if (values == null)
            throw new ArgumentNullException(nameof(values));
        if (avg == 0)
            throw new ArgumentOutOfRangeException(nameof(avg));
        if (avg > values.Length)
            return Array.Empty<float>();

        //https://www.analog.com/media/en/technical-documentation/dsp-book/dsp_book_Ch15.pdf
        // y[i] = y[i-1] + x[i] - x[i - avg]
        // y[i-1] old value
        // x[i] new value right side but still inside the window 
        // x[i-avg] old value at the left outside the window
        // 
        // example: avg (window-size) = 3 and x = 10,20,30,40,50,60,70,80,90,100
        // Step 1: calc y[i-1]= 10+20+30
        // Step 2: start movign (i=1) a window of size avg=3, 10,[20,30,40],50,60,70,80,90,100
        // y[i-1] is old sum value 30
        // x[i] is the new value 40
        // x[i-avg] is left window outside 10
        // Step 3: y
        float invAvg = (float)(1.0 / avg);
        float y = 0;
        float[] result = new float[values.Length - avg + 1];
        for (int i = 0; i < avg; i++)
            y += Convert.ToSingle(values[i]);

        result[0] = y * invAvg;
        for (int i = 1; i < result.Length; i++)
        {
            y += Convert.ToSingle(values[i + avg - 1]) - Convert.ToSingle(values[i - 1]);
            result[i] = y * invAvg;
        }

        return result;
    }
}