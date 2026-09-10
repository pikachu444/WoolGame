extends SceneTree
func _initialize():
 var paths=["scripts/art.gd","scripts/background.gd","scripts/block_flight.gd","scripts/board.gd","scripts/campaign.gd","scripts/game.gd","scripts/hud.gd","scripts/layout.gd","scripts/levels.gd","scripts/map_theme.gd","scripts/memory_cards.gd","scripts/profile.gd","scripts/spool.gd","scripts/state.gd","scripts/world.gd","art/memory_cards_v1.res","scenes/game.tscn","project.godot"]
 var matched=[]
 for relative in paths:
  assert(FileAccess.get_sha256("res://"+relative)==FileAccess.get_sha256("C:/SourceCodes/WoolGame/Rebuild/"+relative),"PCK differs: "+relative)
  matched.append(relative)
 print("PCK_SOURCE_MATCH ",JSON.stringify(matched));quit()
