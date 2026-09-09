using System;
using System.Reflection;
using NUnit.Framework;
class Runner
{
    static int Main()
    {
        int passed = 0, failed = 0;
        foreach (var method in typeof(DemoSessionTests).GetMethods())
        {
            if (!Attribute.IsDefined(method, typeof(TestAttribute))) continue;
            try { method.Invoke(new DemoSessionTests(), null); Console.WriteLine("PASS " + method.Name); passed++; }
            catch (Exception error) { Console.WriteLine("FAIL " + method.Name + ": " + (error.InnerException ?? error)); failed++; }
        }
        Console.WriteLine($"Standalone logic checks: {passed} passed, {failed} failed. Not Unity execution.");
        return failed == 0 ? 0 : 1;
    }
}
