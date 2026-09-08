# 털실 마스터 재현을 위한 기술 아트 R&D

2026-09-08. 모든 수치가 **우리 구현의 출발점**이다. 원작 shader·polygon·engine을 추출하거나 확인한 것이 아니다.

## 1. 가장 현실적인 구현

**반복 편물 마디 mesh + 직접 만든 knit normal/AO + 경로 배치 + 선택 마디만 변형 + 연결 spline**을 채택한다. 원작 S01–S04의 큰 마디 실루엣과 미세 V 조직을 따로 구현한다. 전신을 실제 실 수만 가닥으로 감는 도구는 첫 단계에서 만들지 않는다.

![실제 이미지 확대](crush_references/MATERIAL_CLOSEUPS.png)

### 스케일 계약

마디 폭 B=1을 모델링 기준으로 한다. 화면에서 B가 50–80px일 때를 기본 관찰 거리로 삼는다.

| 항목 | 시작값 | 이유/비교 방법 |
|---|---:|---|
| 마디 길이 | 0.55–0.75 B | 겹친 짧은 편물 조각의 리듬 |
| 인접 마디 중심 간격 | 0.40–0.55 B | 길이 대비 약 20–35% 겹침부터 조정 |
| 마디 두께 | 0.25–0.40 B | 얇은 종이보다 봉제 덩어리 |
| 큰 가장자리 둥글림 | 0.08–0.15 B | soft silhouette; 화면상 2px 이하 날카로운 끝 회피 |
| 마디 LOD0 | 400–900 triangles | 실루엣용 geometry; 미세 조직은 제외 |
| knit 반복 | B당 12–20 stitch 열 | 원작 확대의 촘촘한 방향성 조직 참고 |
| 조직 요철 높이 느낌 | 0.003–0.008 B | shading으로 처리. 외곽을 심하게 울퉁불퉁하게 만들지 않음 |
| 연결 실 직경 | 0.035–0.060 B | 마디보다 훨씬 가늘고 모바일에서 보임 |
| 연결 tube radial segments | 보통 8 / 가벼움 6 | 경로 단면 실루엣 |
| 연결 spline 샘플 | 길이 간격 0.08 B 출발, 곡률 적응 | 화면 chord error 0.5px 이내를 목표 |
| 가는 실 twist pitch | 실 직경의 4–8배, texture 표현 | 실제 ply 수·pitch는 원작에서 확정 불가 |

원작 전체 polygon 수·radial segment 수는 **Unknown**이다. 위 값을 ‘원작 측정치’로 표기하지 않는다. 직선 샘플을 무조건 촘촘하게 만들지 않는다.

## 2. Mesh·normal·fuzz의 역할

| 층 | 무엇을 만드나 | 구현 |
|---|---|---|
| Geometry | 마디의 지느러미/구름형 테두리, 머리, 둥근 블록 | Blender low-poly + bevel/subdivision bake |
| Texture | 반복 V 고리, 작은 섬유 방향, 골의 AO | 독자 procedural stitch tile을 고해상도로 만든 뒤 normal/AO bake |
| URP Lit | 기본색·normal·roughness에 대응하는 smoothness·그림자 | Metallic 0, smoothness 0.12–0.25 출발 |
| Shader Graph 추가 | 완만한 grazing fuzz, 약한 색 변화, 소비 경계 | opaque Lit 기반; rim은 emission을 크게 넣지 말고 낮은 에너지로 제한 |
| 선택 마디 변형 | 실이 나오는 끝으로 납작해지며 풀리는 느낌 | local vertex mask/2–3 bone 또는 간단한 CPU vertex deformation |
| 연결 실 | 이동하는 3D 곡선 | 동적 tube, 실제 밧줄 물리 불필요 |

fuzz는 외곽에 1px 정도의 부드러운 반응부터 비교한다. shell fur와 alpha card 전신 도포는 MVP에서 제외한다. 무거운 overdraw와 깜박임 위험이 크다. 원작에서 SSS/anisotropy/fiber shell을 사용했다는 증거는 없다.

UV는 길이 방향 고정. 부위별 texel 밀도가 달라져 뜨개 조직이 고무처럼 늘어나면 실패다. 몸통 휨은 마디 transform으로 해결하고, 표면 미세 무늬가 프레임마다 미끄러지지 않게 한다.

## 3. 경로와 풀림 애니메이션

몸통은 하나의 긴 skin mesh보다 경로 위 pooled 마디 배치로 시작한다. 경로 위치와 접선·up frame을 bake하고 길이를 arc length로 평가한다. 코너에서 마디 간격·방향이 급변하지 않도록 parallel-transport frame을 사용한다. 원작 구현 추정이 아닌 우리의 선택이다.

한 번의 수집은 3개 표현을 맞춘다:

1. 대상 마디가 pull point 방향으로 100–180ms 가볍게 수축한다.
2. 180–350ms 동안 마디의 잔여 편물 면적이 줄며 연결 실이 살아난다.
3. 같은 진행량으로 실타래 감김이 늘고 숫자 변화가 표시된다. 수집 결과는 Core가 먼저 소유한다.

블록 이동·자리 pop·성공 반응은 tween/Animator로 충분하다. 휘는 용과 연결 실은 spline이 필요하다. 풀리는 마디에는 제한된 mesh 변형이 유리하지만 옷감 시뮬레이션·전신 연성체·모든 stitch의 물리 풀림은 필요하지 않다. 원작의 위상 변화처럼 보이는 결과를 실제 topology 변경으로 구현해야 한다고 단정하지 않는다.

동시에 최대 4개의 연결 선을 허용한다. source/target 좌표가 다른 카메라 공간이면 작업대 anchor를 같은 world로 변환한다. UI 해상도 변화 때 연결 선이 실타래 옆으로 빗나가지 않아야 한다.

## 4. 조명과 renderer 시작값

URP Forward, Linear, HDR off, MSAA 2×. orthographic camera, 보드 법선에서 약 15–25° 기울임부터 비교한다. 이는 원작 camera 역산값이 아니다. 상단/하단 공간은 부모 transform으로 분리하고 화면 구성은 safe area 기준으로 유지한다.

주광 하나를 화면 좌상단 방향으로 두고 밝은 ambient로 채운다. 실 smoothness 0.18, roughness로 표현하면 약 0.82. 실타래 축은 smoothness 0.35–0.5로 대비한다. 물리 단위 light intensity를 그대로 유사도 수치로 쓰지 않고 회색 기준물과 원작 화면으로 노출을 맞춘다.

그림자 atlas 1024 출발, 충분하면 2048. 작은 장면은 1 cascade부터 검증. 주요 생물만 실시간 shadow, 블록 접촉부는 mesh/texture AO로 보강한다. SSAO·Bloom·DOF·motion blur는 기본 off. 실의 미세 밝기가 날아가는 bloom은 금지한다.

## 5. 개인 개발자의 asset 공급 방식

전면 자동 ‘임의 모델→풀 수 있는 털실 게임’은 채택하지 않는다. 이 게임에는 **마디 family를 잘 만드는 도구**가 훨씬 효과적이다.

| 방법 | 비용·자동화 | 품질/수정성 | 채택 |
|---|---|---|---|
| Blender Python + 직접 base | 소프트웨어 비용 없음, 반복 처리 자동화 높음 | 귀여운 머리 비율은 검수 필요 | 주 경로 |
| Geometry Nodes | 마디 반복·curve mesh·UV/속성 생성에 적합 | semantic region 판단은 자동 해결 안 됨 | 주 경로 |
| Spline wrapping | 연결 실·실타래 감김·큰 장식 고리 | 전신에 쓰면 과밀/충돌/비용 증가 | 선택 부위 |
| 임의 base→surface curve | 가이드가 있는 단순 부위는 가능 | 손·귀·깊은 홈에서 단일 자동 규칙 실패 | 후순위 도구 |
| Meshy text/image-to-3D | 생성당 credit, 재생성 비용 | 머리 초안에는 유용; UV/부위/표정은 수정 필요 | 선택 실험 |
| Tripo + segmentation | 생성/분할 별도 비용, API 자동화 가능 | semantic 분할 보조. 퍼즐 graph는 생성하지 않음 | 선택 실험 |
| Rodin Gen-2.5 | 모델 생성 API, 비용은 계약/credit 확인 | base 형태 검토용. 변형 topology 보장 없음 | 대안 |
| Asset Store | 라이선스·재질 일치·수정 비용 | 정확한 아트 방향의 일관성 확보가 어려움 | 첫 slice에는 미도입 |
| runtime procedural geometry | 연결 실/마디 배치 자동화 | 로드 중 전신 생성은 CPU 비용 | 작은 동적 부분만 |

AI 도구의 월 구독을 API credit와 혼동하지 않는다. 2026-09-08 Meshy API 문서의 Meshy-6/7 image-to-3D 예시는 texture 없이 20, 포함 30 credit이고 모델/옵션별로 달라진다. Tripo 현재 가격 페이지와 문서 예제의 차감 수치는 다를 수 있다. **공통 비용식은 ‘시도 횟수×생성비 + 분할/리토폴로지비 + 수작업 시간’**이다. 품질 벤치마크를 직접 수행한 것은 아니며, 이번 조사에서 유료 생성·구독은 하지 않았다. [T5–T8]

### 실제 제작 파이프라인

1. 머리/몸통 마디/귀/꼬리의 독자 base를 만든다.
2. Python이 semantic region 이름·단위·원점·UV 방향을 검사한다. AI 분할을 써도 사람이 경계를 승인한다.
3. 마디 외곽은 실제 mesh, 중앙은 낮은 polygon. 마디 접속부를 숨길 겹침 영역을 지정한다.
4. 하나의 독자 stitch tile을 curve로 만들어 normal/AO를 bake한다. Curve to Mesh와 Resample Curve를 사용할 수 있다. [T1,T2]
5. material별 텍셀 밀도·큰 고리·pull endpoint·LOD를 export한다.
6. Unity importer가 modelId, regionId, pullPoint, mesh bounds를 연결한다.
7. Level authoring은 **따로** 하단 footprint/direction에서 dependency를 생성한다. 생물 마디에서 블록 dependency가 자동 생기는 것이 아니다.
8. 색 공급 unit 목록을 몸통 시각 마디에 매핑하고, Core solver 인증과 아트 검수를 모두 통과시킨다.

Blender 노드는 부위 의미·좋은 실루엣·좋은 퍼즐을 대신 결정하지 못한다. 초기 목표는 완전 자동화가 아니라 1종 승인 후 다음 변형을 짧은 시간에 만드는 재현 가능한 recipe다.

## 6. Android 예산

| 측정 항목 | Visual Slice 목표 | 확장 시 대응 |
|---|---|---|
| visible triangles | 목표 60k, 상한 100k | 마디 LOD/가시 범위 조절 |
| render batches | 목표 60 이하, 상한 100 | shared mesh/material; SRP Batcher와 draw call 감소를 혼동하지 않음 |
| 동시에 보이는 마디 | 24–40부터 시작 | 멀리 있는 마디 instancing, 개별 material 복제 금지 |
| 동적 연결 실 | 최대 4, 합계 8k triangles 이내 | 길이/곡률 적응 샘플 |
| texture GPU memory | 목표 32MiB, 상한 64MiB | ASTC, mip, 공용 atlas |
| steady GC | 프레임당 0B 목표 | pooling, 배열 재사용 |
| 로드/생성 | 대부분 bake | full mesh 재생성은 플레이 중 금지 |
| 성능 | 중급 Android 60fps 목표, 저사양 30fps | 13의 실기기 게이트 적용 |

CPU/GPU 프레임 시간을 각각 측정한다. Editor fps와 실기기 성능은 다르다. 아직 구현하거나 기기에서 측정하지 않았다.

## 기술 출처

- T1 [Blender 4.5 Curve to Mesh](https://docs.blender.org/manual/es/4.5/modeling/geometry_nodes/curve/operations/curve_to_mesh.html)
- T2 [Blender 4.5 Resample Curve](https://docs.blender.org/manual/es/4.5/modeling/geometry_nodes/curve/operations/resample_curve.html)
- T3 [Unity 6.3 Splines](https://docs.unity3d.com/6000.3/Documentation/Manual/com.unity.splines.html)
- T4 [Unity URP](https://docs.unity3d.com/6000.3/Documentation/Manual/com.unity.render-pipelines.universal.html)
- T5 [Meshy API 가격](https://docs.meshy.ai/en/api/pricing)
- T6 [Tripo API 가격](https://developers.tripo3d.com/en/pricing)
- T7 [Tripo segmentation](https://developers.tripo3d.ai/en/docs/mesh-segment)
- T8 [Rodin Gen-2.5](https://docs.hyper3d.ai/en/api-specification/rodin-gen2-5)
