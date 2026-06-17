extends Node2D

func _ready() -> void:
	var used : Rect2i = $TileMap.get_used_rect().grow(-1) # 获取地图的区域大小，position为左上角，end为右下角
														 # grow(-1) = 上下左右各往里缩 1 格。
	var tile_size = $TileMap.tile_set.tile_size # 上面获取的是以瓦片为单位，要用瓦片的像素转为像素位置
	
	
	$Player/Camera2D.limit_top = used.position.y * tile_size.y
	$Player/Camera2D.limit_bottom = used.end.y * tile_size.y
	$Player/Camera2D.limit_left = used.position.x * tile_size.x
	$Player/Camera2D.limit_right = used.end.x * tile_size.x
	$Player/Camera2D.reset_smoothing() # 刚启动时终止当前所有平滑过渡，让相机瞬间定格在当前真实坐标
