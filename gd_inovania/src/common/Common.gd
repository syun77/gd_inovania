extends Node
# ========================================
# 共通モジュール.
# ========================================

# ----------------------------------------
# consts
# ----------------------------------------
# ウィンドウの幅と高さ.
const WINDOW_WIDTH = 1280
const WINDOW_HEIGHT = 960

# 同時再生可能なサウンドの数.
const MAX_SOUND = 8

## コリジョンレイヤー.
enum eCollisionLayer {
	PLAYER = 1, # プレイヤー.
	WALL = 2, # 壁・床.
	ONEWAY = 3, # 一方通行床.
}

# ----------------------------------------
# var.
# ----------------------------------------
## 初期化済みかどうか.
var _initialized = false

## セーブデータ用.
var _achievements:Array[bool] = []

## ゲームデータ.
var _gained_item = {} # 獲得アイテム.
var _past_time = 0.0 # 経過時間.

## 共有オブジェクト.
var _layers = []
var _camera:Camera2D = null
var _player:Player = null
var _bgm:AudioStreamPlayer = null
### BGMテーブル.
var _bgm_tbl = {
	"ino1": "res://assets/sound/ino1.ogg",
	"ino2": "res://assets/sound/ino2.ogg",
}
var _snds:Array = []
### SEテーブル.
var _snd_tbl = {
	"damage": "res://assets/sound/damage.wav",
	"heal": "res://assets/sound/heal.wav",
	"itemget2": "res://assets/sound/itemget2.wav",
	"itemget": "res://assets/sound/itemget.wav",
	"jump": "res://assets/sound/jump.wav",
}

var _slow_timer = 0.0 # スロータイマー.
var _hit_stop_timer = 0.0 # ヒットストップタイマー.

## 画面揺れ.
var _shake_timer = 0.0 # 揺れタイマー.
var _shake_max_timer = 1.0 # 揺れタイマーの最大.
var _shake_intensity = 0.0 # 揺れ倍率.

# ----------------------------------------
# public functions.
# ----------------------------------------
func get_collision_bit(bit:eCollisionLayer) -> int:
	return int(pow(2, bit-1))

## 初期化.
func init() -> void:
	if _initialized == false:
		# 実績.
		for i in range(Achievement.eType.size()):
			_achievements.append(false)
		
		# BGM.
		if _bgm == null:
			_bgm = AudioStreamPlayer.new()
			add_child(_bgm)
			_bgm.bus = "BGM"
		
		# 初期化した.
		_initialized = true
	
	init_vars()

## 各種変数の初期化.
func init_vars() -> void:
	_past_time = 0
	_gained_item = {}
	_snds.clear()

	# タイマーの初期化.
	_slow_timer = 0.0
	_hit_stop_timer = 0.0

## セットアップ.
func setup(layers, player:Player, camera:Camera2D) -> void:
	init_vars()
	
	_layers = layers
	_player = player
	_camera = camera
	# AudioStreamPlayerをあらかじめ作っておく.
	## SE.
	for i in range(MAX_SOUND):
		var snd = AudioStreamPlayer.new()
		#snd.volume_db = -4
		add_child(snd)
		_snds.append(snd)

## 更新.
func update(delta:float) -> void:
	if _slow_timer > 0.0:
		_slow_timer -= delta
	if _hit_stop_timer > 0.0:
		_hit_stop_timer -= delta
	if _shake_timer > 0.0:
		_shake_timer -= delta

## CanvasLayerを取得する.
func get_layer(name:String) -> CanvasLayer:
	return _layers[name]
	
## スロー再生係数.
func get_slow_rate() -> float:
	return 1.0
	
## ヒットストップ開始.
func start_hit_stop(frame:int=3) -> void:
	_hit_stop_timer = 0.01666 * frame # 60fpsと想定.

## ヒットストップ中かどうか.
func is_hit_stop() -> bool:
	return _hit_stop_timer > 0.0
	
## 揺れ開始.
func start_camera_shake(intensity:float=1.0, time:float=1.0) -> void:
	_shake_intensity = intensity
	_shake_timer = time
	if time > 0.0:
		_shake_max_timer = time

## 揺れの値を取得する.
func get_camera_shake_rate() -> float:
	if _shake_timer <= 0.0:
		return 0.0
	
	return _shake_timer / _shake_max_timer
func get_camera_shake_intensity() -> float:
	return _shake_intensity

## 経過時間を足し込む.
func add_past_time(delta:float) -> void:
	_past_time += delta

## 収集アイテムを所持しているかどうか.
func has_item(id:Map.eItem) -> bool:
	return id in _gained_item

## 収集アイテムの所持数を取得する.
func count_item() -> int:
	return _gained_item.size()

## 経過時間の取得.
func get_past_time() -> float:
	return _past_time

## 経過時間を秒で取得する.
func get_past_time_sec() -> int:
	var t = _past_time
	var sec = int(t) % 60
	return sec

## 経過時間を文字列として取得する.
func get_past_time_str() -> String:
	var t = _past_time
	var msec = int(t*1000) % 1000
	var sec = int(t) % 60
	var minute = int(t/60)
	var time = "%2d:%02d.%03d"%[minute, sec, msec]
	return time
	
## 収集アイテム獲得.
func gain_item(id:Map.eItem) -> void:
	_gained_item[id] = true
	
## 収集アイテム

## BGMの再生.
func play_bgm(key:String) -> void:
	if not key in _bgm_tbl:
		push_error("存在しないサウンド %s"%key)
		return
	_bgm.stream = load(_bgm_tbl[key])
	_bgm.play()

## BGMの停止.
func stop_bgm() -> void:
	_bgm.stop()

## SEの再生.
func play_se(key:String, id:int=0) -> void:
	if id < 0 or MAX_SOUND <= id:
		push_error("不正なサウンドID %d"%id)
		return
	
	if not key in _snd_tbl:
		push_error("存在しないサウンド %s"%key)
		return
	
	var snd = _snds[id]
	snd.stream = load(_snd_tbl[key])
	snd.play()
	
## 実績の開放.
func unlock_achievement(id:int) -> void:
	_achievements[id] = true
## 実績を開放済みかどうか.
func unlocked_achievement(id:int) -> bool:
	return _achievements[id]

# ----------------------------------------
# private functions.
# ----------------------------------------
