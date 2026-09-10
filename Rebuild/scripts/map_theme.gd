extends RefCounted
# Themes directly observed at original levels 3 / 5 / 7 / 9.
# Adjacent level assignments are authored choices, not a claimed original schedule.
const ORDER=["meadow","meadow","meadow","festive","festive","ribbon","ribbon","winter","winter","winter"]
const PALETTES={
 "meadow":{"name":"꽃길","stage":"c8dfa0","board":"f8e6c7","dock":"d7bf92","well":"b6a27f","road":"e4b986","rim":"efcda5","seam":"f7dcad"},
 "festive":{"name":"겨울 축제 숲","stage":"568557","board":"f4ddbd","dock":"bd8c71","well":"9d6750","road":"a7583b","rim":"c78257","seam":"deaa77"},
 "ribbon":{"name":"리본 정원","stage":"d9d3f2","board":"e8e3f7","dock":"b4abd5","well":"8d82b1","road":"f4f0ff","rim":"c0b7df","seam":"d8d0f0"},
 "winter":{"name":"눈꽃 길","stage":"c3ddf2","board":"bfdfed","dock":"97b7d3","well":"799cbf","road":"759fc2","rim":"9abdd5","seam":"a8cde4"}
}
static func for_level(level: int) -> Dictionary:
 var key=ORDER[clampi(level,0,9)]
 var result=PALETTES[key].duplicate();result.id=key;return result
