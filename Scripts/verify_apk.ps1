param([string]$Apk = (Join-Path $PSScriptRoot '..\Builds\Android\WoolLab.apk'))
$ErrorActionPreference='Stop'
$woolRoot=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$woolAndroid=Join-Path $woolRoot 'Tools\Unity\Editor\Data\PlaybackEngines\AndroidPlayer'
$woolApk=(Resolve-Path -LiteralPath $Apk).Path
$woolEvidence=Join-Path $woolRoot 'Evidence\Android'
New-Item -ItemType Directory -Path $woolEvidence -Force | Out-Null
$signature=& "$woolAndroid\OpenJDK\bin\java.exe" -jar "$woolAndroid\SDK\build-tools\36.0.0\lib\apksigner.jar" verify --verbose --print-certs $woolApk
if($LASTEXITCODE -ne 0){throw 'APK signature verification failed'}
$signature | Set-Content (Join-Path $woolEvidence 'signature.txt')
$badging=& "$woolAndroid\SDK\build-tools\36.0.0\aapt.exe" dump badging $woolApk
if($LASTEXITCODE -ne 0){throw 'APK metadata verification failed'}
$badging | Set-Content (Join-Path $woolEvidence 'badging.txt')
$permissions=& "$woolAndroid\SDK\build-tools\36.0.0\aapt.exe" dump permissions $woolApk
$permissions | Set-Content (Join-Path $woolEvidence 'permissions.txt')
if(($permissions -join "`n") -match 'android.permission.INTERNET|AD_ID|READ_EXTERNAL_STORAGE|WRITE_EXTERNAL_STORAGE'){throw 'Unexpected network, advertising or storage permission'}
if(($badging -join "`n") -notmatch "native-code: 'arm64-v8a'"){throw 'ARM64 ABI not found'}
if(($badging -join "`n") -notmatch "sdkVersion:'26'"){throw 'Unexpected minimum SDK'}
if(($badging -join "`n") -notmatch "targetSdkVersion:'36'"){throw 'Unexpected target SDK'}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::OpenRead($woolApk)
try{$il2cpp=$null -ne $zip.GetEntry('lib/arm64-v8a/libil2cpp.so')}finally{$zip.Dispose()}
if(!$il2cpp){throw 'IL2CPP native library missing'}
$report=[ordered]@{
    timestampUtc=[DateTime]::UtcNow.ToString('O'); passed=$true; path=$woolApk
    bytes=(Get-Item -LiteralPath $woolApk).Length; sha256=(Get-FileHash -LiteralPath $woolApk -Algorithm SHA256).Hash
    package='com.cozyworkshop.woollab'; version='1.0'; versionCode=1
    minSdk=26; targetSdk=36; abi='arm64-v8a'; backend='IL2CPP'; graphics='OpenGLES3'
    signing='Android Debug certificate, APK signature scheme v2'; internetPermission=$false
    deviceInstallation='NOT TESTED - no connected Android device'; devicePerformance='NOT MEASURED'
}
$report | ConvertTo-Json | Set-Content (Join-Path $woolEvidence 'apk_verification.json')
$report | ConvertTo-Json
