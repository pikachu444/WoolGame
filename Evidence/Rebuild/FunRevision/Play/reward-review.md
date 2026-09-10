# 새 추억 보상 독립 검토

2026-09-10 · /root/play_reviewer · **PASS_WITHIN_REWARD_PRESENTATION_SCOPE**

기존의 ‘같은 고양이·용 그림에 카드 이름만 바뀜’은 해결됐다. 열 장이 들꽃, 통나무 건너기, 목도리, 무지개 실, 약속, 등불, 얼음꽃, 두 용, 집처럼 서로 다른 행동과 물건을 담는다. 결과에서 본 장면이 수집 화면의 같은 이름 카드로 남으므로 무엇을 얻었는지 알아볼 수 있다. 최종 집 장면은 고양이를 구한 뒤 안전하게 쉬는 결말로 읽혀, 구조 성공과 보상의 관계가 이전보다 분명하다.

## 요청 항목별 판정

| 항목 | 판단 |
|---|---|
| 같은 그림 반복 해소 | 통과. 원본 atlas와 수집 화면의10장을 직접 봤다. 이름·배경색만의 차이가 아니라 장면과 행동이 다르다.9판의 두 용과10판 집은 후반 완주의 차이를 보여 준다. |
| 새 보상 인식·다음 판 기대 | 결과1·6·8·10에서 ‘새로운 추억’, 고유 장면·제목, 코인과 성장 보상이 구분된다. 수집할 서로 다른 장면이 생겼다는 동기상의 근거는 있다. 실제로 다음 판을 더 플레이하게 하는지는 측정하지 않았다. 잠금 카드는 물음표와 해금 판수이므로 다음 그림의 구체적 예고까지 제공하는 구조는 아니다. |
| 잠금·모드 소유 상태 | 도전10/10장에는 그림이 있고 자유0/10장에는 물음표와 각 해금 스테이지가 표시된다. 상단 모드명과 소유량이 일치한다. hud.gd도 current().cards에 들어간 항목만 그림을 추가한다. 혼합 소유 화면과 저장 재실행은 이번에 실행하지 않았다. |
| 가림·큰 표시 결함 | 최초 P1을 발견해 부모에게 즉시 전달했고 수정 후 해소를 확인했다. 수정 캡처에서 카드 제목·성장·코인·홈 버튼을 그림이 가리지 않는다. 검토한 화면에 미해결 P0/P1은 없다. |

## 최초 P1과 수정 확인

첫 캡처에서 결과 그림이 오른쪽 화면 밖으로 넘쳤고, 수집 그림은 다음 행과 제목을 덮어 홈 버튼 뒤까지 이어졌다. 이는 얻은 카드를 구별하고 다시 보는 핵심 흐름을 훼손하므로 보류했다. memory_picture가 텍스처와 크기를 먼저 지정한 뒤 expand_mode를 설정하는 순서를 지적했다.

부모가 expand_mode를 먼저 설정하고 크기를 마지막에 고정한 뒤 재캡처했다. rewards-capture-fixed.log의 REWARD_CAPTURE_DONE을 읽고 result-01/06/08/10 및 collection-all을 새로 열어 위 결함의 해소를 직접 확인했다. 첫 캡처 경로는 갱신되었으며 아래 해시는 수정 후 파일을 가리킨다. 최초 실패를 통과 증거로 사용하지 않는다.

## 플레이 동기와 검증 한계

이번 개선은 보상 내용을 실제로 달라지게 만들어, 다음 구조가 새로운 추억으로 이어질 기반을 만든다. 그림의 미관만 좋다는 판정이 아니다. 다만 진행 중 선택의 재미, 긴장과 여유, 열 판의 반복성 문제는 별도 캠페인 검토의 대상이며 이 카드 변경만으로 해결됐다고 보지 않는다. 실제 사용자 반응·재방문·Android 가독성·터치감·보상 등장 애니메이션도 미검증이다.

이 검토자는 UI를 조작하지 않았다. 캡처 하네스는 별도 프로필에 settle로 결과·소유 상태를 구성하고 화면을 렌더했다. 실제10판 완주나 정상 플레이로 카드 획득·저장을 검증한 증거는 아니다. 지금 판정은 아래 소스와 렌더에 한정하며, 이후 배포 PCK와의 일치 확인은 별도다.

## 파일 고정

기록 시각: 2026-09-10T09:19:49.257Z

소스와 하네스:

- Rebuild/scripts/hud.gd — SHA256 c408fe0d5b0fe17dd82f3cb77cce9f27814e99b1f9f93a38295040710d001380
- Rebuild/scripts/memory_cards.gd — SHA256 2c9820bfc95a5e5a513188a5caa1982ae237a4c5b8e3875ac4512b594487e4ea
- Rebuild/art/memory_cards_v1.png — SHA256 528500fe24a2f73861007bf323a25f1b64f56fcd0e5cd5aac0653a152776da46
- Rebuild/art/memory_cards_v1.res — SHA256 5363aeac7065dfaecdcc81536811d32c9c97742346825f38869be9829e95366c
- BuildWork/FunAudit/capture_rewards.gd — SHA256 273aa23c704f8b791d67d06af5054e39d929755ce79920c86bef003d5e814a81

수정 후 화면:

- Evidence/Rebuild/FunRevision/Rewards/result-01.png — SHA256 0155a960ae3af6b7ffa2baf3c0b1f60141b4bece34fa88a5b0eb0b9a2e0fab9b
- Evidence/Rebuild/FunRevision/Rewards/result-06.png — SHA256 c1d7122dd95d61341d92322aa21688e21c15f435119e166d416c1c3a138d17b5
- Evidence/Rebuild/FunRevision/Rewards/result-08.png — SHA256 3ac7cd8bc0effd641a0a41fb968fe3624e2986df6534ba8af27896253790e9bd
- Evidence/Rebuild/FunRevision/Rewards/result-10.png — SHA256 dd7a6fbc51ef24f4dcaa09adc634e0a13591c81018da77796f60d815d1d47a29
- Evidence/Rebuild/FunRevision/Rewards/collection-all.png — SHA256 35f60af560a7e310cbae9c1c573b78540346635dfae830108e0dd964e1c8fb17
- Evidence/Rebuild/FunRevision/Rewards/collection-locked.png — SHA256 87753b0b58658ac3ddb2eb19fce9e8729342e8bbaeb5790d585c5002f6967a1e
- Evidence/Rebuild/FunRevision/Rewards/home-complete.png — SHA256 f9a3c52ce131c298889dbe25d711903176ba05dfb9536b74c8407734193e5bc4
