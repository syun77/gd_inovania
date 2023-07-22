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

## アイテムID.
## タイルのカスタムデータの "item" と連動している.
## アイテム取得メッセージとも連動している.
enum eItem {
	NONE = 0, # 何もない.
	
	## アップグレード・特殊アイテム系.
	JUMP_UP = 1, # ジャンプ回数上昇.
	
	## 収集アイテム系.
	### 富士系.
	FUJI = 2, # 富士山.
	BUSHI = 3, # 武士.
	APPLE = 4, # ふじリンゴ.
	V = 5, # ブイ.
	
	### 鷹系.
	TAKA = 6, # 鷹.
	SHOULDER = 7, # 肩.
	DAGGER = 8, # ダガー.
	KATAKATA = 9, # かたかた.
	
	### 茄子系.
	NASU = 10, # 茄子.
	BONUS = 11, # 棒と茄子.
	NURSE = 12, # ナース.
	NAZUNA = 13, # なずな.
	
	### クソゲー系.
	GAMEHELL = 14, # ゲームヘル2000.
	GUNDAM = 15, # 実写版ガンダム.
	POED = 16, # PO'ed (ポエド).
		
	### その他.
	MILESTONE = 17, # マイルストーン.
	ONE_YEN = 18, # 1円札.
	TRIANGLE = 19, # トライアングル・サービス.
	OMEGA = 20, # おめがの勲章.
	
	### アイテム2.
	LIFE = 21, # ライフ最大値上昇.
	POWER_UP = 22, # 未使用.
	KEY = 23, # 未使用.
}

## 収集アイテム番号.
const ITEM_BEGIN = eItem.FUJI # 開始.
const ITEM_END = eItem.OMEGA # 終端.
const ITEM_NUM = ITEM_END - ITEM_BEGIN + 1 # 収集アイテム総数.
const ITEM_UNKNOWN = 99 # 不明なアイテムアイコン.

## 3種の神器.
const ITEM_LEGENDS = [Map.eItem.FUJI, Map.eItem.TAKA, Map.eItem.NASU]

## アイテム種別.
enum eItemType {
	FUJI, # 富士系.
	TAKA, # 鷹系.
	NASU, # 茄子系.
	HELL, # クソゲー.
	OTHER, # その他.
	
	POWER_UP, # パワーアップ系.
}

static func get_item_type(id:eItem) -> eItemType:
	if eItem.FUJI <= id and id <= eItem.V:
		return eItemType.FUJI
	if eItem.TAKA <= id and id <= eItem.KATAKATA:
		return eItemType.TAKA
	if eItem.NASU <= id and id <= eItem.NAZUNA:
		return eItemType.NASU
	if eItem.GAMEHELL <= id and id <= eItem.POED:
		return eItemType.HELL
	if eItem.MILESTONE <= id and id <= eItem.OMEGA:
		return eItemType.OTHER
	
	return eItemType.POWER_UP

static func item_to_color(id:eItem) -> Color:
	var ret = Color.WHITE
	match get_item_type(id):
		eItemType.FUJI:
			ret = Color.DEEP_PINK
		eItemType.TAKA:
			ret = Color.CORAL
		eItemType.NASU:
			ret = Color.MAGENTA
		eItemType.HELL:
			ret = Color.GREEN
		eItemType.OTHER:
			ret = Color.DODGER_BLUE
		_:
			ret = Color.YELLOW

	#if Item.is_rare(id) == false:
	#	# レア系意外は暗くする.
	#	ret = ret.lerp(Color.BLACK, 0.5)	
	
	return ret
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
static func setup(tilemap:TileMap, w:int, h:int) -> void:
	_tilemap = tilemap
	_width = w
	_height = h

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
static func erase_cell_from_world(pos:Vector2i, tile_layer:eTileLayer=eTileLayer.GROUND) -> void:
	var grid_pos = world_to_grid(pos)

## 床の種別を取得する.
static func get_floor_type(world:Vector2) -> eType:
	var ret = get_custom_data_from_world(world, "type")
	if ret == null:
		return eType.NONE
	return ret
	
## アイテムの種類を取得する.
static func get_item(pos:Vector2i) -> eItem:
	var ret = get_custom_data(pos, "item")
	if ret == null:
		return eItem.NONE
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

# --------------------------------------------------
# private functions.
# --------------------------------------------------

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
