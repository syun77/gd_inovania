extends Node2D
# ===========================================
# メインシーン.
# ===========================================

# -------------------------------------------
# const.
# -------------------------------------------
const MAP_WIDTH = 80
const MAP_HEIGHT = 30

# -------------------------------------------
# objects.
# -------------------------------------------
const BLOCK_OBJ = preload("res://src/gimmic/Block.tscn")
const LADDER_OBJ = preload("res://src/gimmic/Ladder.tscn")
const ONEWAY_FLOOR_OBJ = preload("res://src/gimmic/OnewayFloor.tscn")

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
		j = MAP_HEIGHT - (j + 1)
		for i in range(MAP_WIDTH):
			var pos = Map.grid_to_world(Vector2(i, j))
			var type = Map.get_floor_type(pos)
			if type == Map.eType.NONE:
				continue
			
			#print(type, ":", pos)
			
			match type:
				Map.eType.BLOCK:
					# 壊せる壁.
					var obj = BLOCK_OBJ.instantiate()
					obj.position = pos
					_bg_layer.add_child(obj)
					Map.erase_cell_from_world(pos)
				Map.eType.LADDER:
					# ハシゴ.
					var obj = LADDER_OBJ.instantiate()
					obj.position = pos
					_bg_layer.add_child(obj)
					Map.erase_cell_from_world(pos)
					
					# 上を調べてコリジョンがなければ一方通行床を置く.
					_check_put_oneway(i, j)

				Map.eType.CLIMBBING_WALL:
					#Map.erase_cell_from_world(pos)
					pass

## 上を調べてコリジョンがなければ一方通行床を置く.
func _check_put_oneway(i:int, j:int) -> void:
	var pos = Map.grid_to_world(Vector2i(i, j))
	var pos2 = Map.grid_to_world(Vector2(i, j-1))
	var col_cnt = Map.get_tile_collision_polygons_count(Vector2(i, j-1), Map.eTileLayer.GROUND)
	if col_cnt > 0:
		return # コリジョンがあるので何もしない.
	
	var type = Map.get_floor_type(pos2)
	if type == Map.eType.LADDER:
		return # 上がハシゴなので何もしない.
	
	var obj2 = ONEWAY_FLOOR_OBJ.instantiate()
	obj2.position = pos # 重ねるのはハシゴの上.
	_bg_layer.add_child(obj2)


# カメラの更新.
func _update_camera(delta:float, is_warp:bool=false) -> void:
	# カメラの注視点
	var target = _player.position
	target.y += -64 # 1タイルずらす
	target.x += _player.velocity.x * 0.7 # 移動先を見る.
	
	if is_warp:
		# カメラワープが有効.
		_camera.position = target
	else:
		# 通常はスムージングを行う.
		_camera.position += (target - _camera.position) * 0.05	
	
	# 揺れ更新.
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
