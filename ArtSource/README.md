# WoolLab 아트 원본

현재 게임 자산은 Blender 4.5.13 LTS와 Python으로 직접 제작했습니다. 원작의 이미지·모델·텍스처를 추출해 게임 자산으로 사용하지 않았습니다.

| 대상 | 제작 스크립트 | 편집 가능한 원본 / 출력 |
|---|---|---|
| 용 머리·고양이 | `rebuild_characters.py` | `CharacterRebuild.blend`, `CloudDragonHead.fbx`, `CreamCat.fbx` |
| 겹치는 V자 몸통 마디 | `rebuild_cuff.py` | `CloudSegmentSource.blend`, `CloudSegment.fbx` |
| 삼합사 V자 편물 normal·AO | `bake_knit_physical.py` | `PhysicalKnitSource.blend`, `PhysicalKnitNormal.png`, `PhysicalKnitAO.png` |
| 일시정지·다시 보기·속도 아이콘 | `generate_ui_icons.py` | `control_pause.png`, `control_replay.png`, `control_speed.png` |

FBX는 `UnityProject/Assets/CozyRescue/Art/Models`, 편물 PNG는 `Art/Textures`, 아이콘은 `Art/UI`로 내보냅니다. Unity의 `WoolLab > Refresh original art bindings`가 자산 연결과 import 설정을 갱신합니다.

## 재생성

게임 실행과 빌드에는 재생성이 필요하지 않습니다. 아트를 변경할 때 저장소 루트 `C:\SourceCodes\WoolGame`에서 필요한 명령만 실행합니다. 각 명령은 해당 원본과 출력 자산을 덮어쓰므로 수작업으로 수정한 원본은 먼저 별도 저장합니다. 몸통 검토 렌더는 편물 normal을 읽으므로 전체 재생성 시 아래 순서를 따릅니다.

```powershell
$woolBlender = 'C:\SourceCodes\WoolGame\Tools\Blender\blender-4.5.13-windows-x64\blender.exe'
& $woolBlender --background --python ArtSource/bake_knit_physical.py
& $woolBlender --background --python ArtSource/rebuild_characters.py
& $woolBlender --background --python ArtSource/rebuild_cuff.py
python ArtSource/generate_ui_icons.py
```

아이콘 생성에는 Python과 Pillow가 필요합니다. Blender 스크립트는 Blender에 포함된 Python을 사용합니다. 캐릭터 원본은 자산별 오브젝트가 숨겨진 상태로 저장되므로 편집할 오브젝트의 표시를 켭니다. FBX는 Y up·+Z front이며 눈과 고양이 앞발은 런타임 애니메이션용 별도 오브젝트입니다.

편물은 실제 삼합사 루프 geometry에서 4×4 stitch 타일을 1024×1024 normal·AO로 구웠습니다. normal은 tangent-space OpenGL, AO는 선형 데이터입니다. 큰 실루엣은 몸통 mesh, 작은 조직은 이 맵으로 표현합니다. Unity의 최종 색·편물 밀도·조명은 `WoolLabSettings.asset`과 프레젠테이션 코드에서 조정합니다.

## 검토 이미지와 이전 자료

현재 제작 검토 이미지는 `CloudDragonHead_rebuild_preview.png`, `CreamCat_rebuild_preview.png`, `RebuiltCuffReview.png`, `PhysicalKnitBakedPreview.png`입니다. **모두 Blender 렌더이며 실제 게임 실행 증거가 아닙니다.** 실제 실행 캡처와 영상은 저장소의 `Evidence` 하위 폴더에서 확인합니다.

`generate_art.py`, `preview_art.py`, `WoolLabOriginals.blend`, `ArtPreview.blend`, `ArtPreview.png`, 이전 `CloudSegmentOverlapPreview.png`는 폐기된 시안입니다. **현재 아트를 재생성하려고 이전 `generate_art.py`를 실행하지 마세요. 새 캐릭터와 몸통 FBX를 이전 모델로 덮어쓸 수 있습니다.** 이전 `asset_manifest.json`·`mesh_validation.json` 수치를 현재 모델 수치로 해석하지 않습니다. 캐릭터 제작 정보는 `character_rebuild_manifest.json`, 편물은 `physical_knit_manifest.json`을 사용하며, 전체 씬이나 Android 성능 측정과는 별개입니다.

## 최종 편물 맵

현재 빌드는 `Art/Textures/RefinedKnitNormal.png`와 `RefinedKnitAO.png`를 우선 연결합니다. `python ArtSource/refine_knit.py`로 `ArtSource/RefinedKnit`에 재생성한 뒤 두 PNG를 Unity의 `Assets/CozyRescue/Art/Textures`로 복사합니다. numpy와 Pillow가 필요합니다. 자체 폐곡선 실 고리·둥근 단면·3겹 꼬임·미세 섬유에서 normal과 옆면 음영을 수학적으로 생성합니다. 미리보기는 실제 Unity 캡처가 아닙니다.

기존 PhysicalKnitSource.blend와 물리 베이크 스크립트도 제작 원본으로 보존합니다. 원작 이미지를 읽거나 재사용하지 않습니다. 최종 기본 반복은 마디 폭당 8열이며, 화면에서 V 고리를 읽기 위해 설계 시작값 12–20열에서 조정했습니다.
