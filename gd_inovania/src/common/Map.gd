# ========================================
# Tilemapのラッパーモジュール.
# ========================================
class_name Map

# --------------------------------------------------
# const.
# --------------------------------------------------
## マップの基準位置を変更したい場合はこの値を変更する.
const OFS_X = 0
const OFS_Y = 0

## タイルソースID.
const TILE_SOURCE_ID = 0

## タイルマップのレイヤー.
enum eTileLayer {
	GROUND, # 地面.
#	TERRAIN, # 地形.
}

## 地形の種類.
enum eType {
	NONE = 0,
	
	SCROLL_L = 1, # ベルト床(左).
	SCROLL_R = 2, # 移動床(右).
	SPIKE = 3, # トゲ.
	SLIP = 4, # 滑る床.
	LOCK = 5, # 鍵穴.
	BLOCK = 6, # ブロック.
	LADDER = 7, # はしご.
	CLIMBBING_WALL = 8, # 登れる壁.
	
}

# --------------------------------------------------
# private var.
# --------------------------------------------------
static var _tilemap:TileMap = null
static var _width:int = 0
static var _height:int = 0

# --------------------------------------------------
# public functions.
# --------------------------------------------------
## タイルマップを設定.
static func setup(tilemap:TileMap) -> void:
	_tilemap = tilemap
	# タイルの使用している幅と高さを設定しておく.
	var rect = tilemap.get_used_rect()
	_width = rect.size.x
	_height = rect.size.y

## タイルサイズを取得する.
static func get_tile_size() -> int:
	# 正方形なので xの値 でOK.
	return _tilemap.tile_set.tile_size.x

## ワールド座標をグリッド座標に変換する.
static func world_to_grid(world:Vector2, centered:bool=true) -> Vector2:
	var grid = Vector2()
	grid.x = world_to_grid_x(world.x, centered)
	grid.y = world_to_grid_y(world.y, centered)
	return grid
## ワールド座標をグリッド座標に変換する.
## @return Vector2i
static func world_to_grid_vec2i(world:Vector2, centered:bool=true) -> Vector2i:
	var grid = Vector2i()
	# @note 小数部を四捨五入する.
	grid.x = round(world_to_grid_x(world.x, centered))
	grid.y = round(world_to_grid_y(world.y, centered))
	return grid
static func world_to_grid_x(wx:float, centered:bool) -> float:
	var size = get_tile_size()
	if centered:
		wx -= size / 2.0
	return (wx-OFS_X) / size
static func world_to_grid_y(wy:float, centered:bool) -> float:
	var size = get_tile_size()
	if centered:
		wy -= size / 2.0
	return (wy-OFS_Y) / size

## グリッド座標をワールド座標に変換する.
static func grid_to_world(grid:Vector2, centered:bool=true) -> Vector2:
	var world = Vector2()
	world.x = grid_to_world_x(grid.x, centered)
	world.y = grid_to_world_y(grid.y, centered)
	return world
static func grid_to_world_x(gx:float, centered:bool=true) -> float:
	var size = get_tile_size()
	var x = OFS_X + (gx * size)
	if centered:
		x += size / 2.0 # 中央に移動.
	return x
static func grid_to_world_y(gy:float, centered:bool=true) -> float:
	var size = get_tile_size()
	var y = OFS_Y + (gy * size)
	if centered:
		y += size / 2.0 # 中央に移動.
	return y

## マウスカーソルの位置をグリッド座標で取得する.
static func get_grid_mouse_pos(viewport:Viewport) -> Vector2i:
	var mouse = viewport.get_mouse_position()
	# 中央揃えしない.
	return world_to_grid(mouse, false)
static func get_mouse_pos(viewport:Viewport, is_snap:bool=false) -> Vector2:
	if is_snap == false:
		# スナップしない場合は viewport そのままの値.
		return viewport.get_mouse_position()
	# スナップする場合はいったんグリッド座標に変換.
	var pos = get_grid_mouse_pos(viewport)
	# ワールドに戻すことでスナップされる.
	return grid_to_world(pos, true)
	
## 指定の位置にあるタイル消す.
static func erase_cell(pos:Vector2i, tile_layer:eTileLayer=eTileLayer.GROUND) -> void:
	_tilemap.erase_cell(tile_layer, pos)
static func erase_cell_from_world(pos:Vector2, tile_layer:eTileLayer=eTileLayer.GROUND) -> void:
	var grid_pos = world_to_grid(pos)
	erase_cell(grid_pos, tile_layer)
## 指定の位置にあるタイルを置き換える.
static func replace_cell(pos:Vector2i, atlas_coords:Vector2i, tile_layer:eTileLayer=eTileLayer.GROUND) -> void:
	_tilemap.set_cell(tile_layer, pos, TILE_SOURCE_ID, atlas_coords)
static func replace_cell_from_world(pos:Vector2, atlas_coords:Vector2i, tile_layer:eTileLayer=eTileLayer.GROUND) -> void:
	var grid_pos = world_to_grid(pos)
	replace_cell(grid_pos, atlas_coords, tile_layer)

## 床の種別を取得する.
static func get_floor_type(world:Vector2) -> eType:
	var ret = get_custom_data_from_world(world, "type")
	if ret == null:
		return eType.NONE
	return ret
	
## カスタムデータを取得する (ワールド座標指定).
static func get_custom_data_from_world(world:Vector2, key:String) -> Variant:
	var pos:Vector2i = world_to_grid(world, false)
	return get_custom_data(pos, key)

## カスタムデータを取得する.
static func get_custom_data(pos:Vector2i, key:String) -> Variant:
	for layer in eTileLayer.values():
		var data = _tilemap.get_cell_tile_data(layer, pos)
		if data == null:
			continue
		return data.get_custom_data(key)
	
	# 存在しない.
	return null
	
## コリジョンレイヤーが設定されている数を取得する.
## 1以上の場合は何らかのコリジョンが設定されているタイルとなる.
static func get_tile_collision_polygons_count(pos:Vector2i, layer:eTileLayer) -> int:
	var data = _tilemap.get_cell_tile_data(layer, pos)
	if data == null:
		return 0
	
	var cnt = 0
	for i in range(_get_physics_layers_count()):
		if data.get_collision_polygons_count(i) > 0:
			# 何らかのコリジョンがある.
			cnt += 1
	return cnt

# --------------------------------------------------
# private functions.
# --------------------------------------------------
## タイルセットを取得する.
static func _get_tile_set() -> TileSet:
	return _tilemap.tile_set

## Physics Layerの数を取得する.	
static func _get_physics_layers_count() -> int:
	return _get_tile_set().get_physics_layers_count()
	
## Physics Layer Maskのビットフラグを取得する.
static func _get_physics_layer_collision_mask(layer_index:int) -> int:
	return _get_tile_set().get_physics_layer_collision_mask(layer_index)

# --------------------------------------------------
# properties.
# --------------------------------------------------
## 幅 (read only)
static var width:int = 0:
	get:
		return _width
## 高さ (read only)
static var height:int = 0:
	get:
		return _height
