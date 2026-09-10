# Windows 실제 입력 확인

2026-09-10. 메인이 @oai/sky로 Godot Windows 창을 직접 클릭했다. 잠금 화면이 반환되던 초기 시도에는 입력을 하지 않았으며, 사용자가 로그인한 뒤 실제 게임 화면을 확인하고 재개했다.

## 실행 범위

소스 프로젝트 Rebuild를 Godot 4.7.2로 실행했다. QA 인자 --level 2와 별도 BuildWork/BlockExit/native-final-profile을 사용하여 3판에 직접 진입했다. 이는 정상 홈 진행이나 성장 능력을 얻은 3판 난이도 테스트가 아니다. 시작 하트는 1개였다. 실행 중 7판 데이터가 보정됐으나 이 입력 세션의 3판 데이터와 block_flight/board/state의 출구 코드는 변하지 않았다. 패키지 전체의 정확한 해시 검증과 구분한다.

## 직접 관찰

- 왼쪽 하향 노랑: 클릭 후 왼쪽 선반 진입 순간 포착. down-left-arrival.png.
- 오른쪽 하향 빨강: 도구 줄 위 바닥에서 오른쪽으로 회전하는 몸체와 화살표를 포착. down-right-contact.png.
- 좌향 빨강: 블록이 사라진 자리를 확인하고 선반의 빨강 실 연결·감김을 포착. left-exit-winding.png.
- 우향 파랑: 오른쪽 화면 경계에서 몸체가 보이는 접촉 장면을 포착. right-contact.png.
- 하향 초록: 왼쪽 가장자리에서 선반 밑으로 돌아가는 장면. down-left-dock-turn.png.
- 상향 빨강: 정상 선택 뒤 선반에서 수집됨. up-winding.png.
- 두 차례 실패와 100코인 이어하기를 실제 클릭했다. 첫 이어하기는17% 유지 및300→200코인, 둘째는33% 유지 및200→100코인. loss.png, continue.png.
- 39%에서 톱니바퀴를 눌러 일시정지 메뉴가 보드를 가리는 것을 확인했다. pause.png.

이 세션은 출구·수집·도주·실패·이어하기·일시정지의 제한된 실제 입력 검증이다. 3판 완주, 전체 캠페인 실제 플레이, Android 터치/성능, 음향 청취를 완료한 것으로 표시하지 않는다. 연속 이동 경로 전체의 시간·회전 검토는 별도30fps재현과 독립 규칙 검사에 있다.

## 최종 배포 파일 실제 입력

후보 f66f92fb1678b90d4d8a9d5e698d1fd405e26a0b의 Builds/Rebuild/WoolRescue.exe를 같은 폴더의 PCK와 직접 실행했다. EXE SHA-256 d34d36f3be1a6c49c56525ae86469b92e4f417ddf0b43cf00dd80c385c4b0562, PCK SHA-256 c16e7c1c48d231b437defccbfe4ef7e19bf622f927b7ff28ec455b512a2615e3.

QA --level 2 및 별도 native-packaged-profile로 진입했다. 하향 오른쪽 빨강을 직접 눌러 오른쪽 가장자리에서 선반 밑으로 왼쪽 회전하는 장면(packaged-down-right-dock-turn.png), 우향 파랑을 눌러 선반 아래에서 위로 진입하는 장면(packaged-right-slot-entry.png)을 캡처했다. 11% 수집 뒤 톱니바퀴를 눌러 수동 일시정지(packaged-pause.png)를 확인했다. 최종 EXE에서도 실제 포인터 입력·이동·수집·일시정지가 작동하는 범위의 확인이다. 전체 판 완주/Android 실기기/음향 청취를 주장하지 않는다.

## 수량 표시 수정 후 최종 파일

수량 표시/5판 안내만 추가한 최종 후보908c8efc4a53977f707ac1bb11f12e4e2d0901a6의 EXE를 다시 실행했다. 최종 PCK SHA-256351219ac1c7552ef9dfc4b755bd1e8b0bd452a1060ee731e8134ebee7b445090, EXE 해시는 앞과 같다. QA --level 4와 native-quantity-profile로5판에 진입했다. 직접 캡처에서 블록 아래2/4/6을 읽고, 빨강2 블록을 실제 클릭해 선반의 잔량1과 실 연결 및1% 수집을 확인했다. quantity-final-start.png, quantity-final-winding.png. 정상 종료했다. 앞선3판 기록은 표시 수정 전PCK의 입력 증거이며, 최종판과 규칙·배치는 동일하고5판부터 숫자 표시/안내만 추가됐다. 최종 파일 검증의 범위를 실제 수행한 이 조작까지로 제한한다.
