# 아트 출처

아래 PNG는 이 프로젝트를 위해 ImageGen으로 생성했다. 원본 게임 화면과 동영상을 형태·위치·비율의 비교 자료로 사용하고, 일부 생성에는 해당 참조 화면을 입력했다. 원본 스크린샷의 픽셀을 잘라 게임 스프라이트로 넣지는 않았다.

- `characters_keyed.png`: 머리·고양이·흰 V형 뜨개 몸통·흰 블록의 아틀라스. 2026-09-10 생성, 초록 단색 배경으로 수정. 런타임 셰이더에서 배경을 제거하고 몸통·블록에 색을 적용한다.
- `spool_keyed.png`: 이전 세로 목재 실패 시안. 현재 화면에는 사용하지 않는다. 현재 가로 실패는 spool.gdshader에서 그린다.
- `app_icon.png`: 동일한 고양이 아트 방향으로 생성한 앱 아이콘.
- `characters.res`, `spool.res`: 위 PNG를 Godot 리소스로 변환한 파일. 별도 그림 수정 없이 원본 픽셀을 담는다.
- `NotoSansKR-Medium.ttf`: Google Fonts의 Noto Sans KR 가변 글꼴에서 weight 500을 추출한 고정 굵기 파일. SIL Open Font License는 `FONT_LICENSE.txt`에 있다.
- `korean.res`: 해당 글꼴을 게임 리소스로 저장한 파일.
- 효과음: `scripts/game.gd`에서 생성하는 짧은 합성음.

`../../Docs/DesignTargets/target-01.png`는 재질과 분위기를 잡기 위한 시안이다. 실제 게임 화면이 아니다. 실제 화면·영상은 `../../Evidence/Rebuild/ReferenceMatch`을 확인한다.

## 원본 대조 후 생성·교체한 자산 (2026-09-10)

- `booster_icons.png`: 원본의 실패·제거·정렬·강화 네 도구 형태를 참조한 아틀라스.
- `reference_cast.png`: 걱정/기쁜 고양이, 진행률 마스코트, 눈 덮인 나무.
- `pointed_cuff.png`: 원본 확대 자료 A/B를 참조한, 세 갈래 끝과 두꺼운 입구가 있는 흰 뜨개 소매. 런타임에서 색상·회전·겹침을 적용한다.
- `reference_details.png`: 원본 화면과 재질 확대 자료를 참조한 용 머리·입체 하트·눈사람·설정 버튼.
- `dragon_profile.png`, `rounded_cuff.png`: 독립 검토에서 차이가 지적되어 위 자산으로 교체한 중간 시안.
- 각 같은 이름의 `.res`는 PNG를 Godot ImageTexture로 저장한 리소스다.

최종 소매·세부 자산 생성의 전체 프롬프트와 참조 경로는 `REFERENCE_PROMPTS.json`에 보존했다. 앞선 아틀라스 생성 요청은 이 작업 세션의 ImageGen 호출에 있으며 위 항목은 용도 요약이다. 생성 원본은 C:/Users/pikac/.codex/generated_images/01a08874-831f-7163-88b8-94255c00fc6d에 그대로 보존했다.
