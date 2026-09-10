# 원본 Wool Crush APK 정적 분석

분석일: 2026-09-10. 대상은 Astrasen Global의 `wool.match.color.sort.jam.puzzle`이며 Wool Craze 등 유사 게임이 아니다.

## 실제 확보 및 확인 결과

공개 APKPure 배포 페이지에서 **Wool Crush 1.481 (versionCode 1481), arm64-v8a XAPK**를 실제 내려받았다. 원본 앱을 실행하거나 설치하지 않고 ZIP·manifest·서명·Unity 컨테이너만 읽었다. 원본 바이너리, 추출 텍스트/아트, 도구 의존성은 Git에서 제외되는 `BuildWork/OriginalApk`에만 보관했다.

| 항목 | 직접 확인한 값 |
|---|---|
| XAPK 크기 | 251,414,649 bytes |
| XAPK SHA-256 | `2db1d5123c7ed75662a8e21e215098ebf158cbb3efee9cf9abb08813604eded0` |
| base APK SHA-256 | `545920d33f36566acdc3d9b8fb4b6a2c81c2aa43e7089f463d6cb2ff7e53f7b3` |
| arm64 split SHA-256 | `1ea12a017be1a964f542644165787fdf06ef387ecc75cc893c9b54becc7503b9` |
| Android API | min 23 / target 36 (aapt2 manifest 검사) |
| 서명 인증서 SHA-1 | `f8256c481868514a8500a05ad773174cd653539a` |
| 서명 인증서 SHA-256 | `e435f97c72780204f8e74bfce86327c91cdbf823dbd65684f45f46c60aaaa83c` |
| 엔진 | Unity **2021.3.56f2** |
| 게임 코드 형태 | IL2CPP: `libil2cpp.so` 69,679,488 bytes 및 `global-metadata.dat` 11,799,256 bytes |
| Unity 번들 | 6,477개 `.unity3d` 경로 |

`apksigner verify --print-certs`가 종료 코드 0으로 검증됐고, 인증서 SHA-1은 APKPure 배포 페이지의 값과 일치했다. 이는 내려받은 파일과 배포 정보의 일치 확인이며 Google Play에서 직접 받아 대조한 결과는 아니다. XAPK에는 base와 arm64·영문·mdpi split이 있다.

## 읽힌 데이터와 한계

UnityPy 1.25.3으로 정적 컨테이너를 읽었다. 대부분 파일 앞에는 가변 길이 접두부가 있으며 내부에 평문 `UnityFS` 표식이 있다. 표식에서 표준 컨테이너 파싱을 시작했으며 암호 키를 추출하거나 DRM을 해제하지 않았다.

- 363개 번들에서 Unity 객체를 읽었다. 74개는 객체가 나오지 않았고, 6,040개는 파서가 번들 오류를 보고했다. 일부 객체 읽기 오류도 5건 있다. 이 비율을 전체 추출 성공으로 표현하면 안 된다.
- **TextAsset 271개를 읽었으며, 그중 245개가 `lvmap_` 이름의 지도/레벨 자료**다. 관련 번들 이름은 `data_wzhconfig_lvmapbinary_lvmap_…_bytes.unity3d`다.
- 레벨 자료는 완전한 평문 JSON이 아니라 바이너리 필드와 JSON 형태 배열이 섞인 형식이다. 내부 ID가 화면상의 스테이지 번호와 같은지는 확인하지 못했다.
- 예를 들어 `lvmap_8801`에는 0–10, 11–20 … 91–100 구간에 각각 다른 두 정수 배열이 대응한다. 이는 구간별 설정 데이터가 있음을 보여준다. **그 구간이 스테이지·진행률·시간 중 무엇을 뜻하는지, 두 정수가 어떤 규칙 값인지는 아직 미확인**이다.
- `Assembly-CSharp.dll` 원본 관리 어셈블리나 C# 소스 파일은 APK 목록에서 발견되지 않았다. 관리 어셈블리 이름이 설정 파일에 남아 있는 것과 코드 본문이 포함된 것은 다르다. IL2CPP는 관리 코드를 C++와 네이티브 바이너리로 변환하므로 APK에서 원래 Unity 프로젝트를 그대로 돌려받는 방식은 성립하지 않는다.
- 일반적인 `catalog.json`/Addressables 경로도 목록에서 확인되지 않았다. 실제 사용 여부까지 부정할 수는 없으며, 이 빌드는 적어도 별도의 해시 이름 AssetBundle 경로를 사용한다.

### 레벨 순서 연결을 막는 구체적인 부분

`assets/Android/appinfo.txt`는 설정 형식을 `MemoryPack`으로 명시한다. `LvMapEntry`, `LevelMapData`, `LvMapInfoModule`, `LvMapDataModule`, `LvMapBinaryTool`, `ConfigMgrCustom` 같은 실제 MonoScript 타입명도 존재한다. 따라서 읽힌 바이너리 자료에 임의로 행/열/색/속도 이름을 붙이지 않았다. 타입명 목록과 객체 참조는 확보했지만 MemoryPack 필드의 형식·순서를 정의하는 클래스 스키마나 화면 레벨 순서표는 확보하지 못했다.

별도 자원 목록 `ABFiles.txt`와 `PackageManifest_proj_mxcj_kl_1788429831.bytes`가 실제 존재한다. ABFiles는 해시 파일명·크기만 노출하며, PackageManifest 본문은 일반 JSON/가독 문자열 표가 아니다. 이 단계에서는 lvmap ID → 화면 레벨 → 환경 프리팹의 연결을 복원하지 못했다. 블록 행·열·방향·색·길이, 안개/스폰, 용 속도의 이름 붙은 테이블을 읽었다고 보고할 근거도 없다.

## 이번 개선에 바로 쓸 수 있는 근거

### 배경은 한 장으로 고정된 구조가 아니다

읽힌 AssetBundle 이름에서 환경 프리팹 `model_envmap_1706`, `1960`, `1702`와 `textures_envbg_top2/4/6/8/9/10/11/14/15/18/22`, `map3d_1/3` 계열을 확인했다. 따라서 원본이 여러 환경/배경 자료를 포함한다는 점은 확인된다. 어떤 테마가 어느 스테이지에 배정되는지, 몇 스테이지마다 바뀌는지는 확보한 자료에서 아직 연결하지 못했다. 우리 게임의 배경 변경은 구현하되 정확한 원본 배정표를 복원했다고 표현해서는 안 된다.

### 고양이 위치는 환경 프리팹 안에서 별도 앵커로 구성된다

환경 프리팹 3개의 실제 Transform/MonoBehaviour typetree를 추가로 읽었다. `CatPosRoot` 밑에 `Pos1`/`Pos2`, `CatEndpos`가 있으며 경로마다 `StartPos`, `RunPos1`, `RunPos2`, `RepelPos`, `ShootPos`가 따로 존재한다. `1960_EnvMap`은 `CurvyPath1`과 `CurvyPath2` 두 경로를 포함하고 RunPos가 좌우 대칭이다. 원본의 고양이 대기/도망/최종 지점과 용의 경로 지점을 환경에 맞춰 구분하는 구조는 직접 확인했다.

| 환경 프리팹 | CatEndpos의 로컬 좌표 (x, y, z) |
|---|---|
| 1706_EnvMap | (3.99, 1.20, 6.17) |
| 1960_EnvMap | (0.00, 0.00, 5.80) |
| 1702_EnvMap | (-0.71, 0.00, 6.35) |

이는 해당 프리팹 부모 기준 좌표다. 카메라 투영·부모 변환·화면 레벨 매핑·실제 활성 앵커 순서를 아직 확인하지 않았으므로 휴대폰 화면상의 픽셀 위치나 1–3스테이지 고양이 좌표로 해석하면 안 된다. 우리 게임에서는 스테이지별로 명시적인 고양이 앵커를 두고 경로와 시각적으로 맞물리는지 실제 화면으로 검증할 근거가 된다.

### 충돌 표시와 고양이 상태는 별도 구성요소가 있다

`model_uimove_91072_3dtouchhiteffc_prefab.unity3d`가 있고 이 프리팹의 실제 ParticleSystem 5개도 읽었다. 0.2초 및 1.0초 비반복 시스템과 5.0초 반복 시스템이 섞여 있으며, 이는 프리팹 설정값일 뿐 블록 충돌 전체 지속시간을 뜻하지 않는다. `animation_spine_mxcj_eff_pengzhuang_skeletondata_asset`(충돌을 뜻하는 이름) 자료도 있다. 기본 Unity 데이터에는 `WoolenCatSkillInvincibleState`, `WoolenCatSkillHPState`, `UI3DCatHpTag`, `WoolenCatAnimaMono` 등의 MonoScript 이름이 보존돼 있다. 별도 터치/타격 효과 프리팹과 고양이 체력·무적·애니메이션 구성요소의 존재를 보여준다. **이름만으로 블록 충돌 후 복귀 거리/시간, 밀기 여부, 고양이의 화면 좌표를 확정할 수는 없다.** 해당 동작은 원본 영상의 프레임 비교 및 우리 구현의 실제 재현 검증과 함께 판단해야 한다.

`ABExperimentMapSet`, `ABExperimentLv1MapColor`, `ABExperimentCatNoSkill` 같은 타입명도 존재한다. 이 빌드에 실험 분기 관련 코드가 포함될 가능성을 시사하지만 현재 어떤 분기가 활성화돼 있는지는 정적 이름만으로 알 수 없다. 버전·실험 조건을 고정하지 않고 한 영상의 배치를 모든 사용자에게 공통인 규칙으로 단정하지 않는다.

## 로컬 재현 자료

모두 `BuildWork/OriginalApk` 아래 있으며 공개 저장소에는 이 보고서만 포함한다.

- `inventory.json`: XAPK/각 APK의 SHA-256, 전체 ZIP 목록, XAPK manifest.
- `badging.txt`, `signature.txt`: aapt2와 apksigner 실제 출력.
- `scan_bundles.py`, `bundle-index.json`, `scan2.log`: 파서 버전, 객체/에러 수량과 읽힌 자원명.
- `target-typetrees.json`, `geometry-summary.json`: 환경 3개와 터치/타격 효과 프리팹의 실제 필드·계층·좌표.
- `textassets/`: 실제 읽힌 TextAsset. 원본 레벨 전체나 아트를 제품에 복사하지 않았다.
- `apkpure-download.html`: 다운로드 당시 공개 페이지. 검색 색인에는 1.470 등 이전 버전이 보이지만 실제 내려받은 manifest는 1.481이다.

## 출처

- [Google Play: Wool Crush / Astrasen Global](https://play.google.com/store/apps/details?id=wool.match.color.sort.jam.puzzle&hl=en_US) — 정확한 대상 앱 식별.
- [APKPure: Wool Crush 다운로드](https://apkpure.net/wool-crush%E2%84%A2/wool.match.color.sort.jam.puzzle/download) — 실제 공개 패키지 배포 경로.
- [Unity: IL2CPP 작동 방식](https://docs.unity.cn/2020.1/Documentation/Manual/IL2CPP-HowItWorks.html) — 관리 코드에서 C++·네이티브 코드로 이어지는 빌드 구조.
- [UnityPy 저장소와 사용법](https://github.com/K0lb3/UnityPy) — 정적 Unity 객체·TextAsset 파서.

정적 분석 결론: APK 확보와 일부 데이터 추출은 실제 가능했고 이번에 수행했다. **원본 레벨 배정표·블록 충돌 알고리즘·고양이 좌표를 복원했다는 단계에는 아직 도달하지 않았다.** 이번에 확인된 다중 배경과 별도 효과/상태 구성은 개선 방향의 근거로 즉시 활용할 수 있다.
