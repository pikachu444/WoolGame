# 솜길 구조대 · WoolLab

Unity URP로 만든 Android 개인용 뜨개 퍼즐 시연입니다. 광고·과금·로그인·서버 없이 방향 블록 네 개와 24개의 색 unit으로 고양이 구조까지 플레이합니다.

## 실행

- Android 설치 파일: `Builds/Android/WoolLab.apk`.
- Windows 미리보기: `Builds/Windows/WoolLab.exe`.
- Unity **6000.3.23f1**에서 `UnityProject`를 열고 `Assets/CozyRescue/Scenes/WoolLab.unity`를 실행합니다. 모델과 UI는 Play 시 생성됩니다.
- 아트 연결이나 씬을 재생성할 때는 `WoolLab > Generate scene (preserve art settings)`를 사용합니다.

화살표 블록을 짧게 누릅니다. 파란 긴 블록 → 초록 → 노랑 → 산호색 순서로 시연할 수 있습니다. 산호색은 처음부터 따로 꺼낼 수도 있습니다. 실타래에 같은 색 몸통이 감기고 네 자리 작업대가 비워지면 구조 연출이 나옵니다. 아래 `잠깐`, `다시 보기`, `0.5×` 버튼으로 제어합니다. 소리와 진동은 정지 메뉴에서 켤 수 있습니다.

## 실제 실행 결과와 제작 자료

- [실제 플레이 영상](Evidence/Final/WoolLab_actual_runtime.mp4)
- [전체 화면](Evidence/Final/01_full.png) · [뜨개 확대](Evidence/Final/02_knit_detail.png) · [풀림 중간](Evidence/Final/03_unravel.png) · [구조 성공](Evidence/Final/04_rescue.png)
- [원작과 같은 크기의 비교](Evidence/Final/comparison_full.png)
- [실행·빌드·검증 명령](Docs/RUN_AND_BUILD.md)
- [검증 결과와 남은 항목](Docs/DELIVERY_VALIDATION.md)
- [독자 아트 원본·제작 스크립트](ArtSource/README.md)

`Evidence/Final`은 실제 Windows 플레이어의 화면입니다. 원작 비교의 왼쪽 SOURCE는 조사 자료이며 게임 자산이 아닙니다. Blender/수학적 재질 미리보기는 실제 실행 캡처와 구분합니다. Android 실기기 설치·터치·발열·장시간 성능은 연결된 기기가 없어 미실시입니다.

참고 게임은 털실 마스터 / Wool Crush (`wool.match.color.sort.jam.puzzle`)입니다. 기존 화면 구성·캐릭터·몸통·UI를 교체했으며, 실제 제작 모델·뜨개 맵·아이콘과 네 블록 시연 데이터는 직접 만들었습니다. 원작 APK나 내부 자산을 추출하지 않았습니다.
