# 핵심 의사결정 — 한 페이지

**대상 정정:** 아내가 좋아하는 게임은 **털실 마스터 / Wool Crush**다. Android `wool.match.color.sort.jam.puzzle`, iOS `6743385713`. 이전 Wool Master 3D 문서는 별도 게임을 분석한 것이므로 원작 증거로 사용하지 않는다. 원본은 archive_wrong_reference에 보존했다.

| 질문 | 결정 |
|---|---|
| 무엇을 재현하나 | 방향 블록을 빼서 4자리 작업대에 올리고, 용 몸통의 같은 색 실을 감아 공간을 회수하며 구조하는 경험 |
| 어느 정도 비슷하게 가능한가 | 화면의 세 구역, 뜨개 마디, 색 리듬, 감김·구조의 만족감은 가까운 품질을 목표로 할 수 있다. 원작 전체 레벨·모든 시간/booster 규칙까지 동일하다고 보장할 근거는 없다 |
| 가장 어려운 기술 | 마디 실루엣·knit 재질·풀림 연결감을 실제 휴대폰에서 자연스럽게 만드는 일, 움직이는 공급과 공간 제약의 공정한 인증 |
| 현실적인 그래픽 방법 | 반복 편물 마디 mesh + 독자 knit normal/AO + 부드러운 조명 + 경로 배치 + 선택 마디 변형 + 연결 spline. 전신 실 수만 가닥 물리는 불필요 |
| 추천 엔진 | Unity 6.3 LTS 6000.3.23f1, C#, URP. 공식 Splines/Input System, Blender 4.5 LTS. 유료 plugin 없이 시작 |
| 레벨 생성 | 보드/경로 template + 색·용량·방향 variation + 동일 Core timed solver + 실제 해답 재생 + 아트/반복 검수 |
| 스트레스 개선 | 광고/IAP/로그인/서버 제거. 기본 생각 모드, 선택 흐름 모드, 무제한 무료 undo. 공간·색·탈출 순서는 유지 |
| 가장 큰 리스크 | 아트 수준 미달과 원작 미검증 규칙의 과잉 확정. 후반 전체 레벨과 다섯 독립 gameplay 출처는 아직 미확보 |
| Codex 첫 작업 | **WoolLab Visual Vertical Slice**: 독자 용·고양이, 네 작업 자리, 방향 탭, 한 구간 풀림/감김/구조, Android 실행. solver보다 먼저 |
| 현실적인 완성 범위 | 고품질 씬 1개 → 실제 완성 레벨 1개 → 6레벨 → 첫 24레벨. 마디/머리/구조 동물 각 3종, 배경·경로 4종 |

**이번 결과는 재기획 문서와 실제 이미지/영상 프레임 분석이다. 게임 코드·Unity scene·APK·실기기 성능 측정 결과는 아직 없다.** 독자 시각 프로토타입을 시작할 기준은 마련했지만, 원작 후반까지 조사가 완료됐다는 뜻은 아니다.

첫 지시문: [09A_CODEX_VISUAL_PROTOTYPE_HANDOFF.md](09A_CODEX_VISUAL_PROTOTYPE_HANDOFF.md). 규칙 확신의 근거: [11_EVIDENCE_MATRIX.md](11_EVIDENCE_MATRIX.md).
