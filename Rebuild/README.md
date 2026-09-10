# 털실 구조대 · 오프라인 캠페인

Godot 4.7.2 / GDScript로 만든 개인용 오프라인 게임이다. 사용자와 합의한 범위에 따라 홈에서 시작하는 10판 캠페인, 도전·자유 모드, 성장과 카드 수집을 제공한다. 현재 코드는 Rebuild이며 UnityProject는 이전 이력이다.

## 원본 조사와 구현 범위

[조사 보고서](../Docs/WOOL_CRUSH_RESEARCH_2026-09-10.md)는 공식 자료와 여러 게임 영상의 출처, 관찰한 장면, 미확인 규칙을 구분한다. 기존 영상의 76% 진행 장면은 scripts/levels.gd와 이전 검토 자료에 남겨 두었다. 새 캠페인의 열 판은 관찰한 경로·배치·색·안개·복수 용의 요소를 바탕으로 직접 제작했으며 원본의 1~10판을 그대로 추출한 것이 아니다.

화면은 592×1138 기준으로 무대 약37%, 가로 실패 선반 약12%, 블록 영역 약43%, 도구 약9%를 유지한다. 사용자가 수용한 고양이·용 아트를 사용한다. 도주와 하트 피해, 보호·동결, 공격과 수집 효과를 구분한다. 미확인 수치와 경제는 [개인용 기본값](../Docs/OFFLINE_CAMPAIGN_PLAN.md)이다.

현재 0.3.0은 [경계 이동·맵 개선](../Docs/BLOCK_EXIT_AND_MAP_REVISION.md)과 [10판 학습·난이도 설계](../Docs/STAGE_PROGRESSION.md)를 반영한다. 원본 APK도 [정적 분석](../Evidence/Research/2026-09-10/APK_ANALYSIS.md)했으며, 내부 레벨과 화면 번호의 매핑은 아직 미복원이다.

## 코드

- scripts/campaign.gd: 열 판의 경로, 도주 지점, 배치, 색과 실 수량.
- scripts/block_flight.gd / map_theme.gd: 읽히는 경계 회전 경로와 네 배경 테마.
- scripts/state.gd: 정상 선택, 슬롯 예약, 수집, 위기 상태와 도구.
- scripts/profile.gd: 모드별 진행, 코인, 성장, 카드와 중복 없는 보상 저장.
- scripts/game.gd / hud.gd: 홈·결과·성장·카드·게임 전환, 일시정지, 오디오.
- scripts/world.gd / spool.gd / board.gd: 캐릭터, 실 연결·감김·완료 효과와 입력.
- tests/verify_campaign.gd / verify_ui.gd / verify_stage_progression.gd: 현재 캠페인의 규칙 및 씬 전환 회귀 검사.
- tests/verify.gd: 이전 세 퍼즐 시제품 검사. 현재 빌드 게이트가 아니다.

## 빌드

저장소 루트에서 Python 3로 실행한다.

    python Rebuild/tools/build.py --android

필요한 도구는 Godot 4.7.2 Windows 실행 파일(Tools/Godot), 공식 4.7.2 export templates(사용자 AppData/Godot/export_templates), Apktool 3.0.3(Tools/Godot), Android SDK build-tools 36.0.0과 JDK(Tools/Unity/Editor/Data/PlaybackEngines/AndroidPlayer)다. 도구 바이너리는 저장소에 포함하지 않는다. Python 코드는 표준 라이브러리만 사용한다.

빌드는 아트 리소스를 만들고 세 회귀 검사를 실행한 뒤 Windows ZIP과 ARM64 APK를 Builds/Rebuild에 생성한다. 같은 PCK가 두 패키지에 들어간다. APK 실행 진입점, 서명, 16KB 정렬, 내장 PCK 일치를 확인한다. 배포 APK는 개인 설치용 디버그 서명이며 Android 8 이상 ARM64용이다.

QA 실행은 -- --profile-dir <절대경로>로 실제 저장을 분리할 수 있다. --level 0..9는 QA 전용 직접 진입이고 일반 UI에서는 완료한 판까지만 선택된다. --demo는 정상 선택 검증을 거치는 자동 시연이다. 자동 시연은 독립 실제 플레이 검증을 대신하지 않는다.

현재 검증 기록과 기기 검증의 한계는 [BlockExit/ACCEPTANCE.md](../Evidence/Rebuild/BlockExit/ACCEPTANCE.md)에 기록한다. OfflineCampaign과 ReferenceMatch/Final은 이전 빌드의 기록이다.
