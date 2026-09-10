extends RefCounted
# Source pixels: V04, 592x1280. Gameplay ends at y1138 before the ad and OS area.
const SIZE=Vector2(592,1138)
const STAGE_BOTTOM=420.0
const DOCK_BOTTOM=553.0
const WORLD_ORIGIN=Vector2.ZERO
const CAT=Vector2(376,265)
const BOARD_ORIGIN=Vector2.ZERO
const BOARD_BOTTOM=1028.0
const FOOTER_Y=1041.0
static func slot_center(index: int) -> Vector2:
	return Vector2(78+(index%4)*144,450 if index<4 else 516)
static func slot_rect(index: int) -> Rect2:
	return Rect2(12+(index%4)*144,438 if index<4 else 497,133,40)
