# Evidence Matrix — 털실 마스터 / Wool Crush

2026-09-08. 대상 Android `wool.match.color.sort.jam.puzzle`, iOS `6743385713`.

## 판독 규칙

- **Verified / 관찰:** 제시한 화면·구간에서 직접 확인. 모든 버전의 내부 코드가 확인됐다는 뜻이 아니다.
- **Strong evidence / 강한 추론:** 관찰된 여러 상태 변화를 가장 잘 설명한다. 대안 구현 여지는 남는다.
- **Likely / 가설:** 시각·설명과 맞지만 독립 확인이나 통제된 입력 실험이 부족하다.
- **Unknown:** 확보 자료로 결정할 수 없다.
- **우리 게임의 설계 결정:** 원작 신뢰도 등급과 별개. 02·04·05·13의 구현 계약이다.

기사에 게임 UI가 보이는 것과 독립 플레이어의 무편집 녹화는 다르다. 이 조사에는 실제 게임 화면 클립 3종이 있지만 같은 매체에서 제공했다. 5개 독립 플레이 출처 조건은 충족하지 못했다. 영상 해상도와 편집 때문에 발생 프레임·입력 순간을 과도하게 정밀하게 주장하지 않는다.

## 핵심 규칙

| 항목 | 결론 | 신뢰도 / 분류 | 근거 | Source | Timestamp |
|---|---|---|---|---|---|
| 대상 제품 | 제공 이미지와 일치하는 게임은 Wool Crush | Verified / 관찰 | 스토어 식별자·동일 UI | U1,G1,A1,S1 | 정지 이미지 |
| 화면 구조 | 위 용/구조 대상, 가운데 실타래, 아래 방향 블록 | Verified / 관찰 | 세 고유 클립과 첨부 이미지 | U1,V1,V4,V5 | 각 시작부 |
| 기본 입력 | 아래 블록을 선택해 밖으로 내보냄 | Verified / 관찰 | 선택 손·블록 이동·보드 빈자리 | V1,V4 | 00:02–00:14 / 00:02–00:04 |
| 화살표 방향 이동 | 블록이 가리키는 방향으로 탈출 | Verified / 관찰 | 보라→, 노랑→, 주황← 등 | V1,V4 | 00:02–00:08 / 00:02–00:04 |
| 통로 막힘 | 다른 블록이 탈출 통로를 막으면 선행 제거 필요 | Strong evidence / 강한 추론 | 작은 배치의 상대 위치·실제 제거 순서·기사 설명 | V1,H1 | 00:00–00:18 |
| 정확한 collision | footprint 전체 swept 영역인지, 허용 오차·대각선 판정 | Unknown | 막힌 입력을 통제해서 비교한 자료 없음 | — | — |
| renderer occlusion | 픽셀 가림이 합법성 판정이라는 근거 없음 | Unknown | 3D 외형만으로 판정 구현을 알 수 없음 | — | — |
| 목적지 | 빈 중앙 자리에 같은 색 실타래 등장 | Verified / 관찰 | 하단 주황 제거→중앙 주황 | V4 | 00:02–00:04 |
| 기본 자리 수 | 관찰 화면의 주요 작업 자리는 4개 | Verified / 관찰 | 세 클립·U1 모두 가로 4개 | U1,V1,V4,V5 | 전체 |
| 확장 자리 상한 | Unlock/VIP UI 존재, 총 확장 상한·영구성 미확정 | Unknown | 실제 확장 완료 전후 비교 없음 | U1,V4,S1 | V4 00:00 |
| 용량 4/6/10 | 튜토리얼 시연에서 작은/중간/긴 상자 수용량 | Verified / 관찰 | 중국어 자막 4·6·10과 블록 길이 | V1 | 약 00:02 / 00:06 / 00:08–00:10 |
| 전 버전 용량 | 모든 블록·버전이 항상 4/6/10 | Unknown | 첨부 이미지의 잔여 숫자로 초기 용량 단정 불가 | — | — |
| 숫자 의미 | 남은 수집 가능량 | Strong evidence / 강한 추론 | 감김 진행에 따라 감소하고 자리 비워짐 | V1,V4 | 00:04–00:08 / 00:03–00:08 |
| 같은 색 수집 | 실타래와 같은 색 몸통에서 선이 연결됨 | Verified / 관찰 | 주황·초록·보라·파랑 연결 | V1,V4,V5 | 00:08–00:14 / 00:03–00:14 / 00:04–00:10 |
| 2/3개 매치 | 고정 개수의 실타래 그룹 제거라는 모델은 맞지 않음 | Strong evidence / 강한 추론 | 각 실타래가 독립적으로 감기고 완료 | V1,V4 | 위와 같음 |
| 머리만 수집 | 몸통 중간의 색에서도 수집됨 | Verified / 관찰 | 머리와 떨어진 주황/초록 구간 연결 | V4 | 00:03–00:10 |
| 개별 수집 단위 | 눈에 보이는 꽃잎 하나와 숫자 1이 항상 대응하는가 | Unknown | 저해상도·동시 수집으로 일대일 계수 불가 | — | — |
| 수집 타깃 우선순위 | 같은 색 여러 지점/용/실타래의 우선순위 | Unknown | 선택 가능 후보를 통제한 영상 없음 | — | — |
| 몸통 감소 | 수집에 따라 색 구간이 줄고 뒤쪽 색이 나타남 | Verified / 관찰 | 연속 프레임 대조 | V4 | 00:03–00:18.7 |
| 안개 | 강화 중 선명하다가 종료 후 상단이 흐려짐 | Verified / 관찰 | 카운트다운과 영역 변화 | V5 | 00:10–00:14 |
| 안개 수집 제한 | 노출 범위가 수집 조건에 관여 | Strong evidence / 강한 추론 | 영상·기사·범위 밖 색 리뷰의 일치 | V5,H1,R1 | 00:10–00:24 |
| 정확한 exposure | 화면 밖/안개/거리의 논리 경계 | Unknown | shader opacity만으로 복원 불가 | — | — |
| 자리 full | 경고 후에도 게임·감김 지속. 즉시 실패는 아님 | Verified / 관찰 | ‘需要解锁更多格子’ 다음에도 플레이 | V5 | 00:10–00:14 |
| 시간 압박 | 용 이동·접근·불·하트·위험 테두리 | Verified / 관찰 | 기다리는 동안 위험 변화 | V1,V5 | 00:49–00:57 / 00:18–00:24 |
| 체력 소진 실패 | 기사 설명과 화면이 일치하나 최종 소진 화면 미확보 | Strong evidence / 강한 추론 | 하트·공격·설명 | H1,V5 | 00:18–00:24 |
| 클리어 | 100%·빈 작업대·‘小猫得救’ 구조 성공 | Verified / 관찰 | 장식 용 머리는 화면에 남음 | V4 | 00:18.7 |
| 정확한 win 경계 | 마지막 소비/피해 동시 발생 시 우선순위 | Unknown | 해당 경계 사례 없음 | — | — |
| 3D 회전 | 관찰 플레이에서 사용되지 않음 | Verified / 관찰 | 고정 상하 구도에서 전체 조작 | V1,V4,V5 | 전체 |
| zoom/pan 존재 | 별도 옵션까지 없다고 단정 불가 | Unknown | 메뉴 탐색 자료 부족 | — | — |
| 회색 공급 장치 | 숫자 5 표기 장치가 블록 보드에 존재 | Verified / 관찰 | U1 L4/L12, V5 L16 | U1,V5 | V5 00:00 |
| 공급 장치 동작 | 다음 색 순서·추출 trigger·숫자 정확한 뜻 | Unknown | 완전한 전후 추적 없음 | — | — |
| 복수 용 | 레벨 16 영상에 머리 두 개 | Verified / 관찰 | 다른 위치의 머리 | V5 | 00:00–00:04 |
| 강화 | 기간제 카운트다운과 노출 영역 변화 | Verified / 관찰 | effect 종료가 보임 | V5 | 00:00–00:14 |
| 강화 획득 방식 | 해당 사용이 광고/재화/무료 중 무엇인지 | Unknown | 활성화 이전 UI 없음 | — | — |
| 해제/제거/정렬/강화 | 네 개의 하단 도구 라벨 존재 | Verified / 관찰 | 첨부 한국어 UI | U1 | 정지 이미지 |
| 정렬의 state 변화 | 순서·색·위치 중 무엇을 바꾸는가 | Unknown | 클릭 전후 없음; shuffle로 단정 금지 | — | — |
| 제거의 state 변화 | 블록/몸통/실타래 중 무엇을 제거하는가 | Unknown | 광고 이미지의 장갑 효과는 구현 증거 부족 | S02 | 정지 광고 |
| undo | 확인되지 않음 | Unknown | 이전 다른 게임의 undo 정보 제외 | — | — |
| restart | 재시도 존재는 리뷰가 지지 | Strong evidence / 강한 추론 | 실패·다시 하기 광고 보고 | G1,A1,R1 | 리뷰 |
| revive 광고 | 정확한 부활 선택 UI·복구 state | Unknown | 영상 전후 없음 | — | — |
| forced/banner ad | 광고 포함·하단 배너·승패 뒤 광고 보고 | Verified / 관찰 및 리뷰 보고 | 공식 표시·실제 하단 배너·다수 리뷰 | G1,G2,A1,V4 | V4 00:00–00:18 |
| 의도적 UNSAT | 기본 상태를 고의로 불가능하게 만드는 알고리즘 | Unknown | 광고 유도 체감·제작사 수익 최적화만으로 증명 불가 | I1,R1,R2 | 기사·리뷰 |
| 반복 | 일부 사용자가 quest 반복 보고 | Verified / 리뷰 보고 | 배치 데이터 전체 중복률은 알 수 없음 | G3 | Annie 리뷰 |
| 후반 100+ | 실제 전체 레벨 구조는 미검증 | Unknown | Level156은 광고, YT 제목만 확보 | V3,YT4 | 광고 00:40–00:55 |
| 원작 mesh/shader | V자 조직·둥근 겹침은 관찰; 구현은 미확정 | Likely / 가설 | geometry+normal 혼합으로 설명 가능 | S01–04,V4 | 12의 확대 참조 |

## 영상 출처·중복 검증

아래는 공개 기사 본문 video 요소가 제공하는 MP4다. APK/리소스 추출이 아니다. 자료 꾸러미에는 관찰 프레임만 포함하며 전체 원본 동영상은 포함하지 않는다.

| ID | 제목 또는 기사 내 표기 | 게시일 / 길이 / 크기 | 성격·확인 범위 |
|---|---|---|---|
| V1 | I1 인터뷰의 Wool Crush 플레이 시연 | 기사 2026-08-04, 파일 경로 08-03 / 65.805초 / 220×480 | 실제 게임형 UI, 편집 튜토리얼+L2 |
| V2 | H1의 초기 플레이 설명 | 2026-04-03 / 동일 길이·크기 | V1과 파일 hash 동일. 추가 독립 출처로 세지 않음 |
| V3 | H1 광고 소재, 广大大 출처 표기 | 2026-04-03 / 약 60초 / 1080×1920 | 광고. 말하는 고양이+Level156 화면; 실제 레벨 검증 제외 |
| V4 | H1 ‘Wool Crush 关卡末尾流程’ | 2026-04-03 / 18.947초 / 592×1280 | L41 종반과 성공 화면 |
| V5 | H1 강화 기간 효과 시연 | 2026-04-03 / 25.205초 / 220×480 | L16 복수 용·강화·자리 부족 경고 |

- V1: https://www.baijing.cn/ueditor/php/upload/video/20260803/1785739788319382.mp4
- V2: https://www.baijing.cn/ueditor/php/upload/video/20260403/1775217362680345.mp4
- V3: https://www.baijing.cn/ueditor/php/upload/video/20260403/1775217783207210.mp4
- V4: https://www.baijing.cn/ueditor/php/upload/video/20260403/1775218266819293.mp4
- V5: https://www.baijing.cn/ueditor/php/upload/video/20260403/1775218300960604.mp4

| 파일 | SHA-256 |
|---|---|
| V1=V2 | `4cd7603dec2a009832dd1cbb82324d2464486492b9c5a4a751232023870548e1` |
| V3 | `d2306944d57f88af5e0915d157e9013cceacf58d0cbeddf53b00c51447ba0049` |
| V4 | `ceb7be5f8f71a7c1b8a0c158cbb1e6ce17991491f939d8789ce0e39b41543204` |
| V5 | `a788e78bfa13ab166544bff04fc369bb034350a4c86da00c1cba21ca93c2586b` |

## 추가 플레이 후보와 접근 결과

다음은 **검색으로 발견한 후보**다. 관찰 timestamp는 모두 Unknown이며 규칙 검증 수에 포함하지 않았다. YT1/YT6는 플레이어가 로드됐으나 이번 환경에서 재생 위치 0·media readyState 0에 머물렀다. 나머지는 제목/검색 메타데이터만 확인했다. 게시일을 모르면 상대 날짜를 임의의 절대 날짜로 바꾸지 않는다.

| ID | 제목·단계 | URL | 게시일 | 상태 |
|---|---|---|---|---|
| YT1 | Wool Crush Yarn Color Sort Level 1,2,3 Gameplay Walkthrough Part1 Android iOS | https://www.youtube.com/watch?v=cj1CQV_5K9Y | Unknown | 재생 미확인 |
| YT2 | WOOL CRUSH LEVEL20 SOLUTION WALKTHROUGH / OA GAME | https://www.youtube.com/watch?v=nt8XsManvzQ | 검색 표기 2025-11-16 | 프레임 미확인 |
| YT3 | Wool crush Level20 Solution Walkthrough / Floras Gaming | https://www.youtube.com/watch?v=8LgjU1sjJio | 검색 표기 2025-12-07 | 프레임 미확인 |
| YT4 | Wool Crush Level100 | https://www.youtube.com/watch?v=GO6bc6x3IWU | Unknown | 후반 후보 |
| YT5 | Wool Crush gameplay | https://www.youtube.com/watch?v=atc5djEVnL4 | Unknown | 프레임 미확인 |
| YT6 | Wool Crush Shorts gameplay | https://www.youtube.com/shorts/mteCUakc7G8 | Unknown | 재생 미확인 |
| YT7 | Level44 | https://www.youtube.com/watch?v=0G0-VoemPRU | Unknown | 프레임 미확인 |
| IG1 | Level100 공개 게시물 | https://www.instagram.com/reel/DTEyyy3Ee6I/ | Unknown | 페이지 throttling, 미관찰 |

검색어는 털실 마스터, Wool Crush gameplay/level20/level100, 毛线/毛线消除, ウール/毛糸 및 정확한 package를 조합했다. TikTok·Facebook·Reddit에서 이 package의 규칙을 독립 검증할 만한 접근 가능한 연속 플레이를 추가 확보하지 못했다. 찾지 못했다는 것이 존재하지 않는다는 뜻은 아니다.

## 리뷰 확인 표본

리뷰는 **사용자의 보고**이지 내부 난수·공정성 알고리즘의 증명이 아니다. 아래 33개 표본은 검색/스토어 노출에 편향되어 있으며 통계적 대표성이 없다. G3의 Jess는 G2와 중복이라 다시 세지 않았다. R1/R2는 2026-09-08 열람 당시 캐시 페이지의 ‘2–4일 전’ 표기를 정확한 게시 날짜로 간주하지 않는다. 짧은 요지는 번역·요약이다.

| Source | 작성자 | 요지 |
|---|---|---|
| G1 | DMK | 재시도 광고 부담 |
| G1 | 오문덕 | 레벨 안 광고·정지 불편 |
| G1 | han “soda” soda | 광고 제거 뒤에도 보상 광고·종료 오류 |
| G2 | Jess Tetro | 닫기 버튼이 작고 숨겨짐 |
| G2 | Nicole Drake Strabala | 귀엽고 광고와 같은 플레이, 이후 광고 과다 |
| G2 | Keshia Shields | 높은 레벨의 추가 자리 광고 부담 |
| G3 | Bhairvi Shah | 실패·재시도 광고 |
| G3 | Annie | 실 풀림은 좋음, quest 반복 불만 |
| A1 | 셜리 | 광고 의존 체감 |
| A1 | 깡블리블리 | 광고가 많음 |
| A1 | ㅡㅇ으ㅏㅇ아 | 레벨8에서 장시간 막힘 |
| A1 | midol09 | 재미있지만 승패 뒤 광고 |
| A2 | App lover12345 | 몇 레벨 간격으로 불가능해 보이는 배치 보고 |
| R1 | Mcge3 | 필요한 색이 화면 밖, 기다리면 접근 위험 |
| R1 | GrWeAbBr | 진행이 너무 빠름 |
| R1 | KasiRodz | 클리어 뒤 광고 |
| R1 | KandiG007 | 광고 유도 알고리즘 의심 |
| R1 | A Russian ;) | 레벨3 난이도 체감 |
| R1 | abbielouburton | 레벨296에서도 두뇌 자극 |
| R1 | veryveryannoyed21012794 | 광고의 외부 쇼핑 이동 불만 |
| R1 | mccem77 | 레벨975에서 재화 손실 보고 |
| R1 | Dusterella | 긴 광고 |
| R1 | Loni_Cakes | 승패·재시도 광고 |
| R2 | Moochiesmom4 | 구매 뒤 광고·공격 연출 불호 |
| R2 | 2011LK | 부적절한 광고 |
| R2 | Jkord1 | 튜토리얼 난이도 |
| R2 | hethza | 실패 때 강제 광고가 없다는 긍정 보고 |
| R2 | Rhoandzoo | 광고의 오도 표현 불만 |
| R2 | LoveFaithBlossom | 레벨45 부근 이후 불편 |
| R2 | APSM41 | 거미 상황에서 선택지 없음 보고 |
| R2 | Horrible censorship | 광고 불만 |
| R2 | hashmatoullah | 광고 중 휴대폰 발열 |
| R2 | Squat54 | 여러 행동에서 광고 |

서로 다른 광고 경험은 버전·지역·실험·구매 상태 차이일 수 있다. 한 리뷰로 모든 사용자에게 동일한 광고 규칙이라고 단정하지 않는다. 레벨975라는 리뷰는 후반 UI·레이아웃을 직접 관찰한 증거가 아니다.

## 출처 등록부

- **U1:** 사용자가 제공한 6패널 이미지. [원본 사본](crush_references/U01_confirmed_game.jpg). 사용자가 함께 제공한 https://m.blog.naver.com/gg_bites/224030807532 의 본문은 이번 도구에서 읽지 못했다. 이미지와 블로그 텍스트를 혼동하지 않는다.
- **G1:** 한국 Google Play — https://play.google.com/store/apps/details?hl=ko&id=wool.match.color.sort.jam.puzzle
- **G2:** 영어 Google Play — https://play.google.com/store/apps/details?id=wool.match.color.sort.jam.puzzle&hl=en
- **G3:** 인도 노출 Google Play — https://play.google.com/store/apps/details?gl=in&id=wool.match.color.sort.jam.puzzle
- **A1:** 한국 App Store — https://apps.apple.com/kr/app/id6743385713
- **A2:** 미국 App Store — https://apps.apple.com/us/app/wool-crush-escape-traffic-jam/id6743385713
- **R1:** 리뷰 목록 1 — https://appshunter.io/ios/app/6743385713/reviews
- **R2:** 리뷰 목록 2 — https://appshunter.io/ios/app/6743385713/reviews/2
- **S1:** 같은 iOS ID의 스토어 이미지 목록 — https://appshunter.io/ios/app/6743385713 . 캐시 버전을 현재 버전으로 간주하지 않는다. S01–04 개별 CDN은 12에 기록.
- **H1:** 白鲸出海, 2026-04-03 — https://www.baijing.cn/article/55125 . 같은 글의 재게시 https://www.huxiu.com/article/4848020.html 은 독립 두 출처로 세지 않는다.
- **I1:** 白鲸出海 제작/광고 운영 인터뷰, 2026-08-04 — https://www.baijing.cn/article/56212 . 광고 사용·운영 설명과 개별 퍼즐의 UNSAT 증명은 별개다.

### 배제한 혼동 자료

`wool.master.screw.match.coloring` 및 `com.ly.game.mx`는 대상 package가 다르다. https://levelsolve.com/wool-crush/level/1/ 은 같은 페이지의 색 수/풀이가 충돌하므로 레벨 데이터 근거에서 제외했다. https://tap-guides.com/2025/09/27/wool-crush-beginners-guide/ 의 tube/move limit/undo 설명은 실제 확보 화면과 교차 검증되지 않아 채택하지 않았다.

## 조사 종료 조건에 대한 현재 상태

핵심 loop, 초반과 L16/L41 일부 비교, 원작/제안 구분, 구현 가능한 아트 분석, 첫 데모 기준은 문서화했다. **독립 실제 영상 5개, 실제 100+ 전체 레벨, 모든 booster·실패 조건의 확정은 아직 미충족이다.** 따라서 이번 산출물은 대상 정정과 시각 프로토타입을 위한 근거 있는 재기획판이며 원작 전체 역설계 완료 선언이 아니다. Unknown을 임의 규칙으로 메우지 않는다.
