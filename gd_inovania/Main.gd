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
# objects.
# -------------------------------------------
const BLOCK_OBJ = preload("res://src/gimmic/Block.tscn")

# -------------------------------------------
# onready.
# -------------------------------------------
@onready var _map = $BgLayer/TileMap
@onready var _player = $MainLayer/Player
@onready var _camera = $Camera2D

@onready var _bg_layer = $BgLayer
@onready var _main_layer = $MainLayer
@onready var _particle_layer = $ParticleLayer
@onready var _ui_layer = $UILayer

# -------------------------------------------
# var.
# -------------------------------------------
var _cnt:int = 0

# -------------------------------------------
# private functions.
# -------------------------------------------
## 開始.
func _ready() -> void:
	var layers = {
		"bg": _bg_layer,
		"main": _main_layer,
		"particle": _particle_layer,
		"ui": _ui_layer,
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
	_cnt += 1
	# 共通の更新.
	Common.update(delta)
	
	if Common.is_hit_stop() == false:
		# プレイヤーの更新.
		_player.update(delta)
	
	# カメラの更新.
	_update_camera(delta)
	
	# デバッグ用更新.
	_update_debug()

## タイルからオブジェクトを作る.
func _create_obj_from_tile() -> void:
	for j in range(MAP_HEIGHT):
		for i in range(MAP_WIDTH):
			var pos = Map.grid_to_world(Vector2(i, j))
			var type = Map.get_floor_type(pos)
			if type == Map.eType.NONE:
				continue
			
			#print(type, ":", pos)
			
			match type:
				Map.eType.BLOCK:
					var obj = BLOCK_OBJ.instantiate()
					obj.position = pos
					_bg_layer.add_child(obj)
					Map.erase_cell_from_world(pos)
				Map.eType.LADDER:
					Map.erase_cell_from_world(pos)
				Map.eType.CLIMBBING_WALL:
					#Map.erase_cell_from_world(pos)
					pass

# カメラの更新.
func _update_camera(delta:float) -> void:
	_update_camera_shake(delta)

func _update_camera_shake(delta:float) -> void:
	var rate = Common.get_camera_shake_rate()
	if rate <= 0.0:
		_camera.offset = Vector2.ZERO
	var dx = 1
	if _cnt%4 < 2:
		dx = -1
	
	var intensity = Common.get_camera_shake_intensity()
	_camera.offset.x = 32.0 * dx * rate * intensity
	_camera.offset.y = 24.0 * randf_range(-rate, rate) * intensity

## デバッグ用更新.
func _update_debug() -> void:
	if Input.is_action_just_pressed("reset"):
		# リセット.
		get_tree().change_scene_to_file("res://Main.tscn")
