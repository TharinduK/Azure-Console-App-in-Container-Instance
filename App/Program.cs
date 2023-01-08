Console.WriteLine("Start long running app");

var counter = 0;
var maxCount = Environment.GetEnvironmentVariable("max_count");
var max = string.IsNullOrEmpty(maxCount) ?-1: Convert.ToInt32(maxCount);
while (max == -1 || counter < max)
{
    Console.WriteLine($"Counter: {++counter}");
    await Task.Delay(TimeSpan.FromMilliseconds(1_000));
}

Console.WriteLine("End long running app");