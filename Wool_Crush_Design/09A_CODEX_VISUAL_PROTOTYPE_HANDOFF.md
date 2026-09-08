# 첫 Codex 작업 — Visual Vertical Slice

아래 지시를 첫 개발 작업으로 사용한다. 이번 연구 작업에서는 실행하지 않았다.

---

Android 개인용 게임의 **시각 프로토타입 한 씬**을 만들어라. 참고 대상은 사용자가 이미지로 확정한 **털실 마스터 / Wool Crush**, Android package `wool.match.color.sort.jam.puzzle`, Astrasen Global이다. `wool.master.screw.match.coloring`은 다른 게임이므로 참고하지 마라.

03_ART_DIRECTION, 04_TECHNICAL_ART_RND, 12_VISUAL_REFERENCE_INDEX, 13_VISUAL_VERTICAL_SLICE_SPEC를 읽어라. 원작 이미지는 비교용으로만 사용하고 APK/코드/model/texture/audio/level을 추출하거나 복사하지 마라. 원작의 특정 용 얼굴·고양이 무늬·보드·UI를 재제작하지 마라.

## 결과물

Unity 6.3 LTS 6000.3.23f1 + URP 프로젝트, WoolLab scene, 필요한 독자 source assets, 재현 가능한 Editor 생성 명령, Android APK와 실제 실행/검증 기록. 설치/라이선스/기기 접근이 없어 실행하지 못한 항목은 솔직히 보고하라.

## 구현 범위

- 세로 화면. 상단 움직이는 생물 35%, 중앙 작업대 10%, 보드 44%, 도구 11%를 safe area 기준 출발점으로 사용.
- 독자 솜구름 용 한 마리와 크림색 고양이 한 마리. 통통한 마디·둥근 형태·방향성 knit 조직.
- material은 큰 마디 geometry + 직접 만든 knit normal/AO + 약한 grazing fuzz. 전신 fiber shell 금지.
- 곡선 경로를 따라 반복 마디가 움직이고 코너에서 부드럽게 이어짐.
- 작업 자리 4개, 짧은 방향 블록 4개, 24개의 색 unit을 가진 짧은 시연 구성. 수용량은 4/4/6/10, 각 색 총량과 맞춤.
- 터치/마우스 탭 → 눌림 → 화살표 방향 탈출 → 작업대 도착 → 같은 색 구간 풀림 → 연결 실 → 감김/자리 회수.
- 한 묶음 풀림의 source/line/destination이 연결되어야 함. 단순 투명도 감소만으로 털실 애니메이션을 끝내지 마라.
- 짧은 구조 성공 연출과 다시 보기.
- pause/resume, Android back 처리, safe area, 소리/진동 끄기.

**플레이용 3D 드래그 회전은 만들지 마라.** 이것은 회전 물체 해체 게임이 아니다. 아트 조정용 Editor orbit은 허용한다.

## 제외 범위

solver, procedural level generation, 계정, 광고/IAP, 재화, 서버, 도감 전체, 수십 레벨, 원작 모든 booster. 시연용 상태 기계만 사용하고 이후 production Core와 혼동하지 않도록 분리하라.

## 작업 방식

먼저 현재 workspace와 AGENTS.md, Unity 설치를 확인하라. package와 Editor를 기록하라. scene/prefab은 반복 실행 가능한 Editor 생성기로 만들되 수작업 art parameter를 보존하라. 거대한 YAML을 추측 편집하지 마라.

1. 화면 구성과 머리/마디 silhouette를 잡는다.
2. source reference와 같은 크기에서 knit 재질을 비교한다.
3. 이동·풀림·감김을 구현한다.
4. Android에서 확인하고 13 기준에 못 미치는 부분을 수정한다.

전체 게임으로 범위를 늘리지 마라. 시각 결과가 약하면 placeholder 레벨을 더 만들지 말고 재질/실루엣/애니메이션을 개선하라.

## 제출

- 실제 실행 캡처: 전체 화면, 마디 확대, 풀림 중간, 구조 성공.
- 10–20초 실제 실행 영상. 원작 광고와 혼동되지 않게 OUR PROTOTYPE 표기.
- APK, Editor/패키지 버전, 재생성/실행 방법.
- target 기기명, build 설정, 프레임 시간·batches·triangles·메모리·15분 유지 결과. 측정하지 않은 수치는 목표라고 표시.
- 13 체크리스트와 미통과 항목. ‘원작과 같은 품질’은 비교 화면 없이 선언하지 마라.

첫 단계의 성공은 **원작 화면 옆에서도 뜨개 재질과 상호작용이 크게 초라하지 않은 한 장면**이다.
