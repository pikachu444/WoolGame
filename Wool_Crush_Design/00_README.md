# 털실 마스터 재기획 문서

2026-09-08. 사용자가 제공한 이미지로 대상을 **Wool Crush / 털실 마스터**, Android `wool.match.color.sort.jam.puzzle`로 바로잡았다. 이전 Wool Master 3D `wool.master.screw.match.coloring` 분석과 혼합하지 않는다.

**현재 유효한 문서는 이 폴더의 01–13 및 09A/09B다.** `archive_wrong_reference/`는 이전 10개 문서의 보관본이며 개발 지시로 사용하지 않는다. 기존 Unity/URP·offline·Core 분리·solver·아트 우선 검증은 계승했다. 원작 규칙·아트 대상·카메라·콘텐츠 단위는 새 근거로 교정했다.

## 먼저 읽기

1. [10_KEY_DECISIONS.md](10_KEY_DECISIONS.md) — 한 페이지 핵심 결정.
2. [01_REFERENCE_GAME_ANALYSIS.md](01_REFERENCE_GAME_ANALYSIS.md) — 실제 게임 loop와 정정 이유.
3. [12_VISUAL_REFERENCE_INDEX.md](12_VISUAL_REFERENCE_INDEX.md) — 원작 이미지·확대·실제 프레임.
4. [13_VISUAL_VERTICAL_SLICE_SPEC.md](13_VISUAL_VERTICAL_SLICE_SPEC.md) — 첫 데모 성공 기준.
5. [09A_CODEX_VISUAL_PROTOTYPE_HANDOFF.md](09A_CODEX_VISUAL_PROTOTYPE_HANDOFF.md) — 다음 Codex 작업에 줄 지시문.

## 문서 지도

| 파일 | 역할 |
|---|---|
| [01_REFERENCE_GAME_ANALYSIS.md](01_REFERENCE_GAME_ANALYSIS.md) | 대상 식별·실제 관찰·작은 dependency·초반/중간 비교 |
| [02_GAMEPLAY_SPEC.md](02_GAMEPLAY_SPEC.md) | Reference behavior와 Proposed behavior, 정확한 상태 전이 |
| [03_ART_DIRECTION.md](03_ART_DIRECTION.md) | 미감·화면 비율·귀여움·독자 캐릭터 |
| [04_TECHNICAL_ART_RND.md](04_TECHNICAL_ART_RND.md) | mesh/knit shader/spline/Blender/AI 도구/성능 |
| [05_LEVEL_SYSTEM.md](05_LEVEL_SYSTEM.md) | 생성·동적 solver·수동 fixture·해답 인증 |
| [06_PRODUCT_SPEC.md](06_PRODUCT_SPEC.md) | 광고/과금 없는 offline 개인용 제품 |
| [07_TECH_ARCHITECTURE.md](07_TECH_ARCHITECTURE.md) | Unity 버전·패키지·Core/Presentation·Android |
| [08_IMPLEMENTATION_PLAN.md](08_IMPLEMENTATION_PLAN.md) | 시각 데모→Core→통합→24레벨 |
| [09_CODEX_HANDOFF.md](09_CODEX_HANDOFF.md) | 09A/09B 사용 순서 |
| [09A_CODEX_VISUAL_PROTOTYPE_HANDOFF.md](09A_CODEX_VISUAL_PROTOTYPE_HANDOFF.md) | 첫 작업: 완성도 높은 한 씬 |
| [09B_CODEX_GAMEPLAY_PROTOTYPE_HANDOFF.md](09B_CODEX_GAMEPLAY_PROTOTYPE_HANDOFF.md) | 두 번째: 순수 puzzle core와 검증 |
| [10_KEY_DECISIONS.md](10_KEY_DECISIONS.md) | 한 페이지 결정 요약 |
| [11_EVIDENCE_MATRIX.md](11_EVIDENCE_MATRIX.md) | 규칙별 신뢰도·URL·timestamp·중복·리뷰 |
| [12_VISUAL_REFERENCE_INDEX.md](12_VISUAL_REFERENCE_INDEX.md) | 원작 시각 reference index |
| [13_VISUAL_VERTICAL_SLICE_SPEC.md](13_VISUAL_VERTICAL_SLICE_SPEC.md) | 수치/관찰 가능한 데모 통과 기준 |

## 근거와 현재 한계

실제 게임 화면 클립 3종을 지정 시각 프레임으로 분석했다. 두 기사에 반복된 동일 영상은 hash로 중복 제외했다. 별도 광고는 실플레이 근거로 세지 않았다. 첨부 L2/L3/L4의 보이는 블록을 직접 세고 스토어 이미지 4장의 뜨개 조직·구도를 비교했다.

**독립 실제 플레이 출처 5개, 실제 후반 전체 레벨, 모든 booster/실패 경계의 역설계는 아직 미완이다.** 이 부분은 11에 Unknown으로 남겼다. 원작이 의도적으로 불가능한 퍼즐을 만든다고 단정하지 않는다. 우리 레벨은 기본 4자리로 해답을 인증하도록 별도 설계했다.

이번 결과물은 조사·설계 문서다. Unity 프로젝트·게임 코드·APK는 만들지 않았다. `crush_references/`는 원작 비교용 이미지이며 우리 제작 자산이나 완성 게임 화면이 아니다. 전체 원본 동영상은 포함하지 않았고 공개 URL을 제공한다.
