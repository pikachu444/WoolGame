# WoolLab 실행과 빌드

저장소는 `C:\SourceCodes\WoolGame`, Unity 프로젝트는 그 안의 `UnityProject`입니다. 아래는 재현 절차입니다. 빌드 성공·검증 완료 여부는 최종 검증 보고서와 해당 실행 로그를 확인합니다.

## 프로젝트 열기와 플레이

1. Unity Hub에서 `C:\SourceCodes\WoolGame\UnityProject`를 추가해 **Unity 6000.3.23f1**로 엽니다. 이 컴퓨터의 Editor는 `Tools\Unity\Editor\Unity.exe`입니다.
2. import가 끝나면 `Assets/CozyRescue/Scenes/WoolLab.unity`를 열고 Game 뷰를 720×1560 세로 화면으로 설정한 뒤 Play를 누릅니다. 모델과 UI는 실행 시 구성됩니다.
3. 파란 긴 블록 → 초록 세로 블록 → 노랑 → 산호색을 짧게 누르면 용량 10·6·4·4, 총 24 unit을 감아 고양이를 구조합니다. 산호색은 처음부터 꺼낼 수도 있습니다. 막힌 화살표 앞은 먼저 비워야 합니다.
4. `잠깐`으로 정지하고 정지 메뉴의 `계속하기`로 재개합니다. `다시 보기`는 처음으로 돌아가며 `0.5×`/`1×`는 시연 속도를 바꿉니다. 정지 메뉴에서 소리·진동을 조절합니다. Android 뒤로 가기는 정지 토글이며 앱이 배경으로 가면 정지합니다.

설정 자산은 `Assets/CozyRescue/Content/WoolLabSettings.asset`입니다. `WoolLab > Generate scene (preserve art settings)`는 조정값을 보존하고 씬을 다시 생성합니다. 수작업으로 추가한 씬 오브젝트를 보존하는 명령은 아닙니다. 아트 연결만 갱신할 때는 `WoolLab > Refresh original art bindings`를 사용합니다. 아트 재생성은 `ArtSource/README.md`를 따르며 실행을 위해 재생성할 필요는 없습니다.

## Windows와 Android 빌드

Editor 메뉴 `WoolLab > Build Windows preview` 또는 `WoolLab > Build Android APK`를 실행합니다. 빌드 명령은 씬 생성도 수행합니다.

| 대상 | 출력 | 설정 |
|---|---|---|
| Windows | `Builds/Windows/WoolLab.exe` | 64비트, Direct3D 11, 기본 창 720×1560 |
| Android | `Builds/Android/WoolLab.apk` | ARM64·IL2CPP·OpenGLES3, 최소 API 26·목표 API 36, 세로 고정 |

Android에는 같은 Editor 버전의 Android Build Support와 SDK·NDK·OpenJDK가 필요합니다. 이 컴퓨터는 `Tools/Unity/Editor/Data/PlaybackEngines/AndroidPlayer` 아래 도구를 사용합니다. 개인 설치용 패키지 ID는 `com.cozyworkshop.woollab`이며 스토어 배포용 사용자 keystore는 구성하지 않습니다.

Editor를 닫고 저장소 루트에서 아래 PowerShell 명령으로 빌드할 수도 있습니다. 같은 프로젝트의 Editor와 batch 빌드를 동시에 실행하지 않습니다. 종료 코드와 로그의 최종 빌드 결과를 확인합니다.

```powershell
$woolEditor = 'C:\SourceCodes\WoolGame\Tools\Unity\Editor\Unity.exe'
$woolProject = 'C:\SourceCodes\WoolGame\UnityProject'
$woolBuild = Start-Process $woolEditor -ArgumentList "-batchmode -quit -buildTarget Win64 -projectPath $woolProject -executeMethod CozyRescue.Editor.WoolLabBuilder.BuildWindows -logFile C:\SourceCodes\WoolGame\Tools\unity-build-windows.log" -WindowStyle Hidden -PassThru
$woolBuild.WaitForExit()
$woolBuild.ExitCode

$woolBuild = Start-Process $woolEditor -ArgumentList "-batchmode -quit -buildTarget Android -projectPath $woolProject -executeMethod CozyRescue.Editor.WoolLabBuilder.BuildAndroid -logFile C:\SourceCodes\WoolGame\Tools\unity-build-android.log" -WindowStyle Hidden -PassThru
$woolBuild.WaitForExit()
$woolBuild.ExitCode
```

생성된 APK를 기기로 복사해 설치하거나 USB 디버깅을 허용한 기기에 SDK의 `adb install -r Builds/Android/WoolLab.apk`로 설치합니다. APK 생성과 실제 기기 설치·실행 검증은 별개입니다.

## 실제 실행 캡처와 영상

Windows 빌드 후 `--wool-demo`는 자동 시연을 시작합니다. `--wool-capture`는 자동 시연과 약 16초의 실제 렌더 프레임 저장을 함께 수행합니다. 아래 실행은 보이는 창으로 시작해야 합니다.

```powershell
$woolPlayer = Start-Process '.\Builds\Windows\WoolLab.exe' -ArgumentList '-screen-width 540 -screen-height 1170 -screen-fullscreen 0 --wool-capture --wool-evidence-dir C:\SourceCodes\WoolGame\Evidence\ManualCapture --wool-quit' -PassThru
$woolPlayer.WaitForExit()
python Scripts/encode_evidence.py Evidence/ManualCapture
python Scripts/compare_evidence.py Evidence/ManualCapture
```

Python·FFmpeg가 필요합니다. 인코더에 `--ffmpeg '실제\ffmpeg.exe'`를 전달할 수도 있습니다. 게임 종료 후 `frame_times.csv`와 `capture_context.txt`를 확인합니다. 영상 `WoolLab_actual_runtime.mp4`는 CSV의 실제 프레임 간격으로 인코딩합니다.

`01_full.png`, `02_knit_detail.png`, `03_unravel.png`, `04_rescue.png`는 전체·조직 확대·풀림·구조 성공 캡처입니다. 확대 이미지는 실제 렌더 프레임의 일부를 잘라낸 것입니다. 비교 이미지의 원작 영역과 Blender 렌더는 우리 실행 증거가 아닙니다. 캡처는 저장 부하를 추가하므로 이 실행의 FPS를 일반 플레이 성능으로 보고하지 않습니다.

## 검증 재현과 버전

| 항목 | 지정 버전 |
|---|---|
| Unity | 6000.3.23f1 (09d2ecc7fb28) |
| URP | 17.3.0 |
| Input System | 1.20.0 |
| Splines | 2.9.0 |
| uGUI | 2.0.0 |
| Test Framework | 1.6.0 |
| 아트 제작 | Blender 4.5.13 LTS, Python·Pillow |

Unity Test Runner의 EditMode `DemoSessionTests` 또는 .NET 9 SDK로 순수 C# 상태 전이를 검증합니다.

```powershell
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
dotnet run --project 'UnityProject/Assets/CozyRescue/Tests/Standalone~/DemoChecks.csproj'
```

Windows 플레이어에는 두 개의 별도 검증 모드가 있습니다. 아래 실행은 각각 종료된 뒤 다음을 시작하며 캡처·자동 시연 모드와 섞지 않습니다.

```powershell
$woolChecks = Start-Process '.\Builds\Windows\WoolLab.exe' -ArgumentList '--wool-checks --wool-aspects --wool-checks-dir C:\SourceCodes\WoolGame\Evidence\ManualChecks --wool-quit' -PassThru
$woolChecks.WaitForExit()
$woolChecks = Start-Process '.\Builds\Windows\WoolLab.exe' -ArgumentList '--wool-pointer-checks --wool-pointer-checks-dir C:\SourceCodes\WoolGame\Evidence\ManualPointer --wool-quit' -PassThru
$woolChecks.WaitForExit()
```

첫 모드는 실제 플레이어 API로 상태 전이·정지·재시작·화면 비율과 자산 수명을 확인합니다. 두 번째는 합성 MouseState를 Input System에 넣어 포인터 판정·Physics Raycast·uGUI 경로를 검증합니다. **합성 입력은 실제 마우스 조작이나 Android 터치 검증이 아닙니다.** Windows 프레임 시간은 데스크톱 실행 측정이며 Android 기기 성능이나 GPU 시간으로 해석하지 않습니다. 목표 60fps와 측정값을 구분하고, 실기기를 사용하지 않았다면 APK 유무와 무관하게 기기 검증은 미실시로 기록합니다.

최종 결과: APK 빌드와 서명·패키지·권한 검사는 완료했습니다. 실제 Windows 입력 경로 11항목, 24 unit 구조 시연, 20회 재시작, 세 화면 비율 검증을 통과했습니다. 상세 결과와 측정 범위는 [검증 기록](DELIVERY_VALIDATION.md)에 있습니다.
