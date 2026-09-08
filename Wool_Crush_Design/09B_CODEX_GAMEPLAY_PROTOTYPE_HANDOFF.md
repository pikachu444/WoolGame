# 두 번째 Codex 작업 — Gameplay Prototype

09A의 시각 게이트 후 사용한다. 아직 전체 게임을 만들지 않는다.

---

털실 마스터(Wool Crush)를 참고하는 독자 게임의 작은 gameplay prototype을 만들어라. 02_GAMEPLAY_SPEC와 05_LEVEL_SYSTEM을 구현 계약으로 사용하고, 11에서 원작 관찰과 독자 결정을 구분하라. 3개 매치·2주문+5buffer·3D 물체 회전 규칙을 넣지 마라.

## 범위

1. 엔진 참조 없는 순수 C# Core: Block, WorkSlot, YarnUnit, Chain, RescueTarget, LevelState.
2. 전체 footprint의 방향 탈출, 네 작업 자리 예약, 이동/도착, 색별 수용량, 20Hz StepTick, 동적 노출, 수집, 승패.
3. 무료 undo/restart/pause. 생각 모드와 흐름 모드가 같은 Core를 사용.
4. 05의 수동 10블록 fixture: 실제 데이터 파일, 좋은 순서와 네 자리 deadlock, 전체 색 보존.
5. 속도/후퇴가 있는 작은 동적 레벨 하나. 정적 fixture 통과를 동적 퍼즐 검증으로 대체하지 마라.
6. solver SAT/UNSAT/UNKNOWN, timed witness와 정식 Core 재생. 정상 레벨은 기본 4자리·booster0으로 인증.
7. GameplayLab scene. 09A visual은 adapter로 연결하되 Core가 renderer에 의존하지 않게 한다.

## 주의

모델 화면의 가림을 dependency로 쓰지 마라. renderer callback이 논리 완료를 결정하지 않게 하라. 같은 색 실타래끼리 합치지 마라. full slot은 새 출발만 막고 미래 수집/노출을 검사한다. 잘못 누른 입력은 시간을 소비하지 않는다.

solver에 실제 AdvanceToDecision 대기 분기가 있어야 한다. 내부는 1 tick씩 진행하되 UI가 다시 판단할 수 없는 중간 tick에 출발을 삽입하지 마라. DFS 예산 초과를 불가능 판정으로 바꾸지 마라. 색 개수만으로 상태를 축약하거나 slot 순서를 정렬하지 마라. 현재 상태의 힌트에 최초 해답을 무조건 적용하지 마라.

## 검증과 제출

색별 수용량 보존, 중복 소비/예약, 같은 색 두 실타래, 길쭉한 블록 충돌, 도착/수집 동시 사건, 마지막 unit/피해 동시 사건, undo 중 애니메이션 취소, 앱 정지 복구, 인증 hash 변경을 검증한다.

작은 fixture의 실행 로그와 그림, timed witness, 실제 실패/복구 영상, Android 실행 결과, 아직 확인하지 않은 원작 규칙을 제출한다. 자동 레벨 양산은 이 단계에 넣지 마라.
