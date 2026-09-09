# Optional standalone logic checks

From the repository root, run:

```powershell
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
dotnet run --project 'UnityProject/Assets/CozyRescue/Tests/Standalone~/DemoChecks.csproj'
```

Requires .NET 9 SDK and restores NUnit 3.13.3. This invokes the same eight test methods used by the Unity EditMode test assembly. It checks pure C# state transitions only; it is not evidence of Unity scene, rendering, or Android execution. Unity ignores this directory because its name ends in `~`.

2026-09-08: standalone result **8 passed, 0 failed**, .NET SDK 9.0.203. The first attempt used Unity 2018's bundled NUnit DLL and failed due to its unsupported .NET Remoting dependency; switching this optional runner to NUnit 3.13.3 resolved that test-host incompatibility without changing the demo implementation.
