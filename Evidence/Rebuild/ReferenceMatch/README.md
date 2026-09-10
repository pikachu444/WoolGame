# 최종 검토 결과와 실행 증거

2026-09-10. 이 폴더의 최종 대상은 verified-run/ 캡처, gameplay-final.mp4, runtime-final.log, build-final.log 및 package-integrity.json에 적힌 패키지다. 루트의 gameplay.mp4, runtime.log, motion/build-*.png는 상단 수집 오류로 독립 검토에서 미달 판정을 받은 이전 실행 기록이다.

## 직접 비교

- [시작 화면 나란히 보기](comparison-start.png): 왼쪽 원본 V04, 오른쪽 최종 실행 캡처.
- [완료 화면 나란히 보기](comparison-success.png): 왼쪽 원본 V04, 오른쪽 최종 실행 캡처.
- [원본·수정본 비교 영상](comparison-motion.mp4): 왼쪽 원본, 오른쪽 실제 패키지. 원래 재생 속도를 유지했다. 원본이 끝난 후에는 마지막 프레임을 유지한다. 소리는 제외했다.
- [최종 실행 영상](gameplay-final.mp4): 실제 Windows 실행 파일의 자동 시연. 25.07초, 540×1038, 30fps, 합성 효과음 포함. 19.5917초에 하트3개로 완료했다. 내부 게임 캔버스 캡처는 592×1138이다. 고정 프레임 녹화이므로 실시간 성능 증거는 아니다.
- [독립 검토 기록](INDEPENDENT_REVIEW.md): 실패했던 지점과 수정 후 재검토 결과.

원본 다운로드 주소·해시·영역 측정은 [REFERENCE.md](REFERENCE.md)에 있다. 최초 레벨 전체가 아니라 76% 진행 상태의 9블록 후반 구간을 재현했다. 광고·운영체제 화면은 제외하고 중국어 문구는 한국어로 바꿨다.

## 패키지와 검사

../../../Builds/Rebuild/WoolRescue-Windows.zip 및 WoolRescue-Android.apk를 갱신했다. Windows ZIP, 실행 PCK, APK 내부 PCK의 바이트 일치를 package-integrity.json에 기록했다. 최종 소스 해시는 source-integrity.json에 있다.

규칙 검사 1076/1076, 뷰포트 입력·전환 검사19/19 통과. 상단 안개 속 실이 먼저 수집되지 않는 회귀 검사도 포함한다. 추가 두 자체 퍼즐은 additional-puzzle-1/2의 실제 패키지 로그·캡처로 확인한다.

APK는 ARM64 검토 빌드이며 서명·패키지·16KB 정렬을 확인했다. Android 실기기 조작과 성능은 검증하지 않았다.
