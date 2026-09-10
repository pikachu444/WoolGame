extends RefCounted

const ATLAS=preload("res://art/memory_cards_v1.res")
# Authored panel boundaries in the generated 1003 x 1568 atlas. Trim the separators.
const ROWS=[0,315,630,941,1243,1568]

static func texture(index: int) -> AtlasTexture:
	var card=clampi(index,0,9)
	var row=card/2;var left=0 if card%2==0 else 501
	var right=501 if card%2==0 else 1003
	var result=AtlasTexture.new();result.atlas=ATLAS
	result.region=Rect2(left+2,ROWS[row]+2,right-left-4,ROWS[row+1]-ROWS[row]-4)
	result.filter_clip=true
	return result
