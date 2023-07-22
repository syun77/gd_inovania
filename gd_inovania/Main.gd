extends Node2D
# ===========================================
# メインシーン.
# ===========================================

# -------------------------------------------
# const.
# -------------------------------------------
const MAP_WIDTH = 20
const MAP_HEIGHT = 15

# -------------------------------------------
# onready.
# -------------------------------------------
@onready var _map = $BgLayer/TileMap
@onready var _player = $MainLayer/Player
@onready var _camera = $Camera2D

@onready var _bg_layer = $BgLayer
@onready var _main_layer = $MainLayer

# -------------------------------------------
# var.
# -------------------------------------------

# -------------------------------------------
# private functions.
# -------------------------------------------
## 開始.
func _ready() -> void:
	var layers = {
		"bg": _bg_layer,
		"main": _main_layer,
	}
	Common.setup(layers, _player, _camera)
	
	# マップのセットアップ.
	Map.setup(_map, MAP_WIDTH, MAP_HEIGHT)
	
	# タイルマップからオブジェクトを作る.
	_create_obj_from_tile()
	
	# プレイヤー移動開始.
	_player.start()

## 更新.
func _physics_process(delta: float) -> void:
	_player.update(delta)	

## タイルからオブジェクトを作る.
func _create_obj_from_tile() -> void:
	for j in range(MAP_HEIGHT):
		for i in range(MAP_WIDTH):
			var pos = Map.grid_to_world(Vector2(i, j))
			var type = Map.get_floor_type(pos)
			if type == Map.eType.NONE:
				continue
			
			match type:
				Map.eType.BLOCK:
					Map.erase_cell_from_world(pos)
				Map.eType.LADDER:
					Map.erase_cell_from_world(pos)
				Map.eType.CLIMBBING_WALL:
					Map.erase_cell_from_world(pos)
