extends RefCounted

# Measured V04 0-2s footprints: x,y,width,height,direction,color,capacity.
# This is the observed late-level board, not the original full level 41.
const OBSERVED = [
	[239,682,78,60,3,5,6],[221,734,64,63,1,2,6],[295,734,47,63,0,4,4],
	[221,803,48,62,0,3,4],[295,806,48,92,0,1,6],[221,866,48,92,0,0,6],
	[276,898,81,65,3,4,6],[240,958,46,63,0,3,4],[295,958,47,63,0,5,4]
]

# Additional complete dense puzzles at the reference's tile scale.
# Authored variants, not claims about undocumented original level data.
static func dense(variant: int) -> Array:
	var rows=[[3,5],[1,3,4,5],[1,2,4,5,6],[0,2,3,5,7],[0,1,3,4,6,7],[1,2,4,5,7],[2,3,5,6]]
	var result=[]
	var index=0
	for row in range(rows.size()):
		for col in rows[row]:
			var x=48+col*61
			var y=582+row*63
			var direction=0 if row<3 else 2
			if row==3: direction=3 if col<4 else 1
			if variant==2:
				x=544-x-44
				if direction%2==1:direction=(direction+2)%4
			result.append([x,y,44,56,direction,[3,2,5,4,0,1][(index+variant)%6],4])
			index+=1
	return result
