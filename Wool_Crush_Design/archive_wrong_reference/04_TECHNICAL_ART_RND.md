# 털실 그래픽과 콘텐츠 제작 R&D

2026-09-08 · 설계 문서. 실제 제작·벤치마크 결과 아님.

## 1. 기술 결론

가장 현실적인 방식은 **직접 만든 단순 부품형 base mesh → 부위별 감김 가이드 → spline tube로 굵은 실 제작 → 미세 섬유 normal → Unity에서 선택한 묶음만 풀기**다. Blender는 제작·베이크에, Unity는 게임용 재질·카메라·인출 애니메이션에 사용한다.

“어떤 3D 모델이나 넣으면 자동으로 예쁜 털실 퍼즐이 된다”는 일반 변환기는 첫 목표로 적합하지 않다. 손잡이, 오목한 접합부, 갈라진 가지, 얇은 날개는 감김 방향과 조각 분할을 정해야 한다. **부품 분할과 가이드 축 몇 개를 지정하면 반복 작업을 자동화하는 반자동 도구**는 현실적인 핵심 자산이다.

원작의 실제 geometry/셰이더 방식은 미공개다. 이하 모든 수치는 우리 시작 예산과 구현 제안이다. Blender의 Curve to Mesh는 곡선을 메시로 바꾸는 도구이며, 자동으로 좋은 감김 경로를 찾아 주는 도구가 아니다. [T1,T2]

## 2. 제작 방법 비교

| 방법 | 현금 비용 | 품질·자동화 | Codex 활용과 판단 |
|---|---|---|---|
| 완전 수작업 모델/감김 | Blender 자체 비용 없음, 작업시간 큼 | 최고 제어, 생산량 낮음 | 레퍼런스 1~3개와 어려운 부위 수정용 |
| Python procedural base | 도구 비용 없음 | 단순 장난감 실루엣에 강함; 자연스러운 비대칭은 조정 필요 | JSON recipe→mesh 반복 생성. **기본 공급원** |
| Geometry Nodes | Blender 내장 | 감김 프로필·간격·단면·LOD를 재사용 가능 | 노드 생성/파라미터화, UI 슬라이더. **채택** |
| spline yarn wrapping | 별도 상용 플러그인 불필요 | 실루엣과 풀림 경로를 함께 확보 | curve 길이·UV·순서까지 자동 생성. **핵심** |
| 임의 mesh→털실 | 자체 도구 개발비 큼 | 오목면/구멍/토폴로지에서 실패 가능 | 지원 범위를 제한한 guided conversion 채택 |
| AI text-to-3D | 서비스별 과금 | 빠른 모티브 탐색, 부품 의미/길/토폴로지 미보장 | 초안 base 용도. 생성 결과를 곧바로 퍼즐에 넣지 않음 |
| AI image-to-3D | 이미지+3D 생성 비용 | 독자 콘셉트의 비례를 유도 가능, 뒷면/얇은 부분 보정 필요 | 원작 이미지 대신 독자 콘셉트 입력. **선택적 보조** |
| Asset Store base | 자산별 무료/유료, 라이선스별 상이 | 스타일 통일·분할·리토폴로지 작업 남음 | MVP 필수 구매 없음. 필요시 특정 base만 검토 |
| runtime procedural | 현금보다 CPU/GPU/디버깅 비용 | 가변 형태 가능, 로딩·GC·일관성 부담 | 이동 실에만 사용. 전체 모델 생성은 오프라인 베이크 |
| 혼합 | 무료 도구 중심 + 선택 AI 비용 | 일정 품질과 물량의 균형 | **최종 추천** |

“AI가 만든 털실 텍스처”는 진짜로 풀릴 순서와 경로를 가진 메시가 아니다. 표면에 그려진 실은 인출할 수 없다. 사용할 때는 매끈한 base 형상만 취하고 감김 정보는 우리 도구에서 만든다.

### AI 비용을 계산하는 방법

2026-09-08 공식 API 문서 기준, Meshy의 Meshy-6/7 이미지→3D는 무텍스처 20 credits, 텍스처 포함 30 credits이며 별도 remesh가 5 credits다. 크레딧의 현금 환산은 해당 계정의 구매 조건을 확인해야 한다. [T5]

Tripo 공식 문서는 $1=100 credits를 표시한다. H2/H3 image-to-model은 무텍스처 20, 텍스처 30 credits, P1은 각각 40/50이다. 선택 파라미터·후처리 비용은 별도일 수 있다. [T6]

예를 들어 H2/H3 무텍스처 후보를 모티브당 3회씩 30개 생성하면 기본 생성만 90×20=1,800 credits, 문서 환산으로 $18다. 이는 **계산 예시**이지 총 제작비 견적이 아니다. 이미지 생성, 재시도, segmentation, cleanup, 작업시간은 빠져 있다. 싸게 생성되는 것과 실전에 쓸 자산을 싸게 완성하는 것은 다르다. API를 이번 작업에서 호출하거나 유료 생성하지 않았다.

첫 slice는 AI 비용 0으로도 시도 가능하다. 채택 후보마다 `source, prompt/recipe, modelVersion, seed, licenseReference, edits, author, outputHash`를 기록한다. 유료 서비스나 외부 에셋 도입은 품질 샘플로 필요성을 확인한 뒤 별도 결정한다.

## 3. Base model → Wool asset pipeline

### 입력 계약

- 원본 mesh 또는 procedural recipe. 단위는 meter로 통일하고 정규화 크기/원점 기록.
- 부위 분할: body/head/handle/leaf 등 semantic part.
- part마다 wrapMode, axis/frame, threadRadius, pitch, startEnd, seam 위치.
- 한 번에 선택할 묶음 구획, support group, blocker 설명.
- 이동 가능한 곡선의 인출 시작점과 방향. 눈/입 같은 고정 장식은 별도 표시.

### 처리 순서

| 단계 | 처리 | 저장되는 결과 |
|---|---|---|
| 1 정리 | 중복점·뒤집힌 normal·scale·nonmanifold 검사 | 정규화 base 및 문제 목록 |
| 2 부품 분할 | 구형/관형/판형/분기형 분리 | PartDefinition |
| 3 가이드 | wrap axis와 local frame, 구멍·seam·금지영역 지정 | guide curves 및 태그 |
| 4 경로 | 적절한 wrapping recipe로 중심선 생성 | 순서 있는 curve samples |
| 5 품질 검사 | 곡률·간격·교차·노출 끝점 검사 | 자동 수정 또는 수동 수정 marker |
| 6 메시화 | 원형/약간 찌그러진 단면으로 sweep | LOD별 tube mesh |
| 7 재질용 데이터 | arc-length UV, tangent, 자체 AO, palette/part ID | UV0/UV1·vertex attributes |
| 8 퍼즐 컴파일 | 묶음·support·blockers를 단조 제거 그래프로 변환 | ModelDefinition + graph candidates |
| 9 Unity 미리보기 | 실게임 shader, 카메라, 선택, 중간 제거 | 캡처·GPU 측정 대상 scene |
| 10 검사/패키징 | 해답·접근성·성능·시각 게이트 | prefab/mesh/texture + metadata hashes |

Blender Geometry Nodes의 procedural 결과를 Unity가 그대로 실행하지는 않는다. 메시·텍스처는 FBX와 이미지로 베이크하고, **실의 경로는 별도 JSON 또는 binary sidecar**로 내보낸다. FBX만으로 curve의 의미·blocking·해답이 전달된다고 가정하지 않는다. Blender material node도 URP로 자동 호환된다고 기대하지 않는다.

### 형상별 wrapping recipe

| 형상 | 생성 방식 | 실패 처리 |
|---|---|---|
| 타원/몸통 | 축별 단면 contour를 잇는 나선 또는 band | 극점에서 반지름 줄임, 끝부분 별도 cap winding |
| 관/꼬리/목 | 중심 guide curve의 parallel transport frame으로 helix | 급한 곡률 구간의 pitch/radius 조정 |
| 판/날개/잎 | surface chart 위 serpentine 경로, 모서리 귀환 | chart 경계에서 분리, 겹친 잎은 따로 생성 |
| 손잡이/torus | 닫힌 guide를 따른 tube wrapping | seam의 frame twist 분산, 연결 부위 장식으로 정리 |
| 다리/가지 분기 | 부위를 나눠 독립 감김 후 seam 접합 | 분기 전체를 단일 helix로 처리 금지 |
| 복잡한 오목 mesh | patch별 축/가이드 수동 지정 | 자동 실패를 숨기지 않고 지원되지 않는 부위로 표시 |

단면 슬라이싱 결과의 contour가 여러 개로 갈라질 수 있다. 직전 contour와 centroid만 가까운 것을 무조건 연결하면 공간을 가로지르는 실이 생긴다. part/loop ID를 유지하고 split/merge 지점을 명시해야 한다. 일반 모델에 대한 완전 자동화가 어려운 이유가 여기 있다.

### 곡선 품질 규칙

- arc length 간격으로 resample한다. 매개변수 t의 같은 간격이 같은 실제 거리라고 가정하지 않는다.
- tangent에서 frame을 만들 때 Frenet frame의 직선/변곡점 불안정을 피하고 parallel transport를 사용한다.
- 고곡률 부분은 추가 sample, 거의 직선인 부분은 감소시킨다.
- 중심선 거리와 tube 반경으로 비인접 segment의 충돌을 검사한다. 의도적 교차는 위아래 관계를 별도로 기록한다.
- curve가 보이는 끝에서 풀리도록 시작점을 정한다. “뒷면에서 갑자기 사라지는” 시작점은 불합격.
- LOD마다 원본 curve의 arc-length 좌표를 유지한다. 다른 인출 방향이나 blocker ID로 바뀌면 안 된다.

## 4. Geometry 표현과 polygon 예산

굵은 실은 실제 튜브, 꼬인 가는 실은 normal, 솜털은 셰이더와 제한적인 가장자리 표현으로 나눈다.

튜브 단면 k개 점, 경로 S개 ring이면 대략 vertices=S×k, triangles=2×(S−1)×k다. UV seam 복제점·cap·장식은 별도다.

예: 48묶음×160 rings×6각 단면 ≈ 46,080 vertices, 91,584 triangles. 이것은 제안하는 한 모델의 계산 예이며 **원작 polygon 추정치가 아니다.** 120묶음에 같은 밀도를 적용하면 약 230,000 triangles로 늘어나므로 후반에도 묶음당 밀도를 동일하게 유지할 수 없다.

| 영역 | 보통 품질 시작 예산 | 낮은 품질 시작 예산 |
|---|---:|---:|
| 화면 전체 활성 triangle | 120k 이하 목표, 임시 상한 180k | 70k 이하 |
| 활성 vertices | 80k 내외 목표 | 45k 내외 |
| 전체 draw calls | 그림자·UI 포함 100 이하 목표 | 65 이하 |
| 재질 변형 | 공유 6색+작은 선택/효과 변형 | 동일 또는 더 적게 |
| 이동 중 실 | 1묶음 / transfer tube 1개 | 동일 |
| texture residency | 64 MiB 내 목표 | 32 MiB 내 목표 |
| 앱 전체 메모리 | 350 MiB 내 목표 | 250 MiB 내 목표 |

하드웨어 독립적인 성능 보장은 아니다. profiler로 조정할 초기 budget이다. 그림자 패스·깊이 패스는 triangle 처리를 다시 발생시킨다. 모델 triangle만 세고 frame 비용을 무시하지 않는다.

실이 충분히 가늘게 보이는 부분에서는 6각 단면 + smooth normal, 가까운 silhouette에는 8각을 사용한다. 정상 화면에서 튜브의 다각형 단면이 보이면 해당 부위만 올린다. 전체 오브젝트를 무조건 고밀도로 만들지 않는다.

## 5. Shader 구현 방향

### MVP 셰이더

- URP Forward의 opaque Lit 기반. metallic=0, smoothness 낮게.
- UV의 한 축은 실제 실 길이, 다른 축은 단면 회전 각도다.
- 독자 생성한 작은 tileable fiber normal을 사용한다. texture scale은 실 길이 단위에 맞춰 균일하게 유지한다.
- 굵은 홈은 geometry가 만들고, normal은 꼬임과 미세 섬유만 담당한다.
- AO는 각 묶음의 자체 홈 위주로 bake한다. 나중에 없어질 이웃이 만든 큰 occlusion을 영구 베이크하지 않는다.
- 부드러운 wrap diffuse와 약한 grazing sheen은 2차 실험. full subsurface scattering, 복잡한 hair BRDF는 사용하지 않는다.

고품질 비교안으로 tangent 방향 anisotropic lobe를 시험하되, 비용과 색 읽힘이 개선되는 경우만 채택한다. full-screen bloom은 실을 부드럽게 만드는 주요 수단이 아니다.

### per-piece 변화와 배칭

처음에는 색별 공유 material + 선택한 1묶음에만 별도 animated material을 사용해 단순하게 시작한다. 정적인 개체를 클릭할 때마다 `renderer.material`로 복제하지 않는다.

Unity 6.3 공식 문서에는 **Renderer Shader User Value(RSUV)**가 있다. renderer당 uint32를 전달하고 `unity_RendererUserValue`로 읽으며 SRP batching과 양립하는 방식이다. 이후 palette index·선택 flag·정규화 progress를 packing하는 비교안을 사용할 수 있다. 이것은 수많은 MaterialPropertyBlock을 무조건 쓰는 것보다 적절한 후보다. [T7]

SRP Batcher는 CPU의 material state 설정 비용을 줄이지, 서로 다른 mesh 수십 개를 자동으로 draw call 1개로 합치는 기능이 아니다. GPU instancing도 동일 mesh 반복에 유리하며 모든 독자 spline mesh에 자동으로 적용되지 않는다. 실제 Frame Debugger로 확인한다. [T8]

60개의 독립 renderer가 main/shadow에서 각각 그려지면 UI 이전에 120 draw calls에 이를 수 있다. 예산 초과 시 색·부품 단위로 정적 mesh를 합치고 piece별 index 구간을 보존하는 방법을 시험한다. 선택 시 해당 구간을 정적 draw에서 제외하고 임시 animated renderer로 옮긴다. 제거가 끝나면 남은 index만 한 번 갱신한다. 매 프레임 전체 mesh를 다시 합치지 않는다. 그림자용 저밀도 proxy를 별도로 통합하는 대안도 비교한다. 이러한 최적화 없이 표의 draw call 목표가 자동 달성된다고 가정하지 않는다.

## 6. Lighting과 화면 효과

기본 key directional light 1개, 밝은 ambient, 단순 바닥, soft shadow를 시작점으로 한다. 움직이는 오브젝트의 전체 그림자를 lightmap에 고정 베이크하지 않는다. static 배경은 가능하다.

- shadow atlas 1024부터, main light 1 cascade를 시작값으로 사용한다.
- 작은 홈은 자체 AO/normal, 바닥 접촉은 얇은 contact blob이나 가벼운 그림자로 보완한다.
- SSAO는 기본 꺼짐. 높은 품질에서 실제 개선이 명확하면 downsampled 저비용 설정을 비교한다.
- HDR·tone mapping은 palette를 바꾸므로 LDR와 비교한다. 기본은 과한 post 없는 일관된 색.
- MSAA 2×부터, 높음 4×는 측정 후. 미세 섬유의 aliasing은 샘플 수만 늘리기보다 normal mip/강도 조절로 해결한다.
- 투명 fur shell 여러 장, full-screen blur, 화면 전체 particle는 피한다. 선택 piece에만 소량 효과.

조명/그림자 설정 숫자는 GPU 테스트 뒤 고정한다. 원작과 같다고 주장하지 않는다.

## 7. 풀림 애니메이션: 필요한 기술의 경계

단순 Tween은 눌림·상자 이동·가벼운 낙하에는 적합하지만 실 풀림 자체에는 부족하다.

### 제안: 남은 감김 + 연결 실 + 목적지 감김

1. 정적 winding path를 길이 s로 parameterize해 저장한다.
2. 선택 시 보이는 끝에서 trim frontier가 이동한다. 원본 곡선의 남은 구간을 실제로 줄인다.
3. frontier의 위치·접선을 연결 실 spline의 시작점으로 사용한다.
4. 연결 실 끝은 스풀의 실제 감김점이다. 손가락 위치로 끌고 가는 게임이 아니므로 위치는 목적지에 고정한다.
5. 이동 spline에 곡률과 약한 지연을 주어 당김이 느껴지게 한다. 실제 rope solver 없이 제어점 보간으로 시작한다.
6. 감김에서 빠진 길이와 spool에 감긴 길이의 비율을 맞춘다. 논리 수량은 1단위지만 시각 길이는 묶음마다 다를 수 있다.
7. 남은 조각이 사라질 때 endpoint를 순간이동시키지 않고 끝 cap과 마지막 loop를 정리한다.

GPU alpha clipping만으로 줄이면 사라진 부분의 vertex 처리가 계속 발생하고 shadow pass와 불일치할 수 있다. MVP는 미리 할당한 mesh/index 구간을 축소하거나 선택된 묶음의 작은 mesh만 갱신한다. shader trim은 비교안이며 bounds/ShadowCaster/depth pass도 동일하게 처리한다.

연결 실은 대략 32~64 samples×6~8각 단면으로 runtime 갱신한다. 전체 모델의 normals/tangents를 매 프레임 재계산하지 않는다. 이동 실의 프레임과 normal을 직접 계산하고 버퍼를 재사용한다.

### 충돌과 카메라

인출 실이 본체를 관통하면 싼 효과로 보인다. 첫 도구는 미리 정한 출구 방향 + 모델 바깥 control point + 스풀 도착으로 경로를 만든다. 모델 회전 중에도 시작점을 매 프레임 갱신한다. 장애물이 큰 복합 모델은 authoring한 경로를 사용한다. 출구 경로와 gameplay blocker를 실제 rope 물리 하나로 통합하지 않는다.

스풀은 UI 이미지로만 그리지 않고 고정된 상단 3D 트레이에 놓는 것이 연결 실을 유지하기 쉽다. Canvas의 표시 위치를 world-space tray anchor로 변환한다. UI용 별도 camera/RenderTexture가 필요하면 추가 비용을 측정한 뒤 선택한다. 첫 slice는 단일 main camera에 3D tray와 UI overlay를 배치한다.

| 동작 | Tween | Spline | Mesh 변화 | 물리 |
|---|---|---|---|---|
| 선택 눌림 | 필수 | 없음 | 보통 없음 | 불필요 |
| 실 인출 | 보조 | 필수 | 선택된 감김/연결 실만 | 불필요 |
| 스풀 이동/완료 | 필수 | 선택 | 감김량 표현만 | 불필요 |
| support 조각 제거 | 필수 | 없음 | 보통 없음 | 장식용 옵션 |
| 전체 완성 | 필수 | 선택 | 마스크/표시 | 불필요 |

실제 cloth/softbody, 전체 yarn self-collision, 물리적 매듭 풀기는 프로젝트 범위 밖이다. 블록의 낙하는 시각만 담당하고 충돌 결과가 새 blocker를 만들지 않는다.

## 8. 모바일 최적화와 측정

목표는 Android 중급기에서 60fps, 낮은 품질에서 안정적인 30fps다. 아내의 실제 기종은 아직 모르므로 현재 보이는 사용자 폰 정보를 아내의 폰으로 간주하지 않는다.

측정 대상: 중급기 1대+실제 사용 폰, Mali/Adreno를 둘 다 구할 수 있으면 비교한다. 에뮬레이터와 데스크톱 GPU의 성능은 모바일 통과 근거가 아니다.

| 위험 | 전략 | 검증 |
|---|---|---|
| vertex 증가 | 화면 크기 기반 LOD, 단면/길이 샘플 감소 | 최악 레벨의 triangles/vertex 처리 시간 |
| draw call | 공유 material, 정적 묶음의 선택적 통합 | main/shadow/UI pass별 Frame Debugger |
| overdraw | opaque 중심, 잔털/입자 최소 | overdraw 시각화·GPU 시간 |
| shader | normal 1장+palette, branch/texture sample 제한 | LOD별 shader cost 비교 |
| texture | 공용 512~1K fiber, 압축·mipmap | 실제 GPU residency |
| runtime 생성 | 에디터 베이크, 이동 실만 업데이트 | GC alloc 0/frame 목표 |
| 열/배터리 | 30fps 모드, background pause, 불필요 렌더 중지 | 15분 연속 플레이 p95 frame time |
| 저장/로딩 | 한 번에 현재 모델만 로드 | cold/warm load, peak memory |

60fps 모드의 초기 게이트: warm-up 후 15분 플레이에서 p95 frame interval≤20ms, 100ms 이상 hitch 없음 목표. 낮은 품질은 p95≤35ms 목표. 평균 fps만 보고 합격시키지 않는다. thermal throttling·배터리 상태·해상도·품질·기종을 결과에 기록한다.

## 9. R&D 순서와 중단 기준

| 실험 | 비교 | 통과 조건 | 실패시 |
|---|---|---|---|
| A 굵은 실 | normal-only / tube+normal | 기본 거리에서 감김과 포근함 | 반경·간격·조명 조정 |
| B 재질 | Lit / weak sheen / anisotropy | sheen 없이도 부드럽고 색 구별 | 복잡 shader 추가 전 geometry 수정 |
| C 인출 | shader trim / index trim+transfer spline | 연결 끊김·관통 없이 부드러움 | 경로와 cap 수정 |
| D 범용성 | 생물/손잡이/잎 3형태 | 신규 모티브가 같은 룩으로 생성 | 지원 부위 제한, 수동 가이드 증가 |
| E 실제 폰 | 보통/낮음 품질 | art rubric와 frame budget 동시 통과 | LOD/그림자/normal 순 조절 |
| F 생산성 | 독자 모델 5개 제작 시간 기록 | 보정 시간이 반복적으로 감소 | 100모델 목표 철회, 12모델 완성 우선 |

첫 3개를 완성하기 전 수십 개를 생성하지 않는다. 동일 조명 아래 시각 승인 없이 node graph/코드가 있다는 사실만으로 도구 완료를 선언하지 않는다. 원작 수준 품질은 아직 실증되지 않았다.

## 기술 출처

- T1 [Blender Curve to Mesh](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/curve/operations/curve_to_mesh.html): 공식 검색 본문으로 기능 확인. 본문 open은 오류였으므로 세부 API는 구현 때 로컬 Blender 문서로 재확인.
- T2 [Blender 4.5 Geometry Nodes](https://docs.blender.org/manual/en/4.5/modeling/geometry_nodes/index.html): 제작 기준 문서 경로. node API의 실제 설치 버전은 lock 필요.
- T3 [Blender 4.5 LTS](https://www.blender.org/releases/4-5/), [LTS 유지](https://www.blender.org/download/lts/4-2/): 4.5 LTS 지원과 제작 기준 선택.
- T4 [Unity Splines 6000.3](https://docs.unity3d.com/6000.3/Documentation/Manual/com.unity.splines.html): 2.9.0 released, 경로/곡선 도구.
- T5 [Meshy API 가격](https://docs.meshy.ai/en/api/pricing), [Image-to-3D API](https://docs.meshy.ai/en/api/image-to-3d): 기능·비용. 최종 품질 보장 근거로 사용하지 않음.
- T6 [Tripo API 가격](https://docs.tripo3d.ai/get-started/pricing.html): 모델군별 credit와 환산 기준.
- T7 [Unity 6.3 RSUV](https://docs.unity3d.com/6000.3/Documentation/Manual/renderer-shader-user-value-intro.html): per-renderer shader 데이터와 batching.
- T8 [Unity draw call 최적화 비교](https://docs.unity3d.com/kr/current/Manual/optimizing-draw-calls-choose-method.html): SRP Batcher와 batching의 구분. 구현은 고정 6000.3 문서/API로 확인.

이 파이프라인과 예산은 위 도구의 기능을 바탕으로 한 설계 추론이다. 원작 제작 방식의 발견이나 이미 작동하는 자동 변환기의 성능 보고가 아니다.
