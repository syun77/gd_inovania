extends CharacterBody2D
# =================================
# プレイヤー.
# =================================
class_name Player
# ---------------------------------
# const.
# ---------------------------------
var ANIM_NORMAL_TBL = [0, 1]
var ANIM_DEAD_TBL = [2, 3, 4, 5]

const JUMP_SCALE_TIME := 0.2
const JUMP_SCALE_VAL_JUMP := 0.2
const JUMP_SCALE_VAL_LANDING := 0.25

## 状態.
enum eState {
	READY,
	MAIN,
	DEAD,
}

## ジャンプスケール.
enum eJumpScale {
	NONE,
	JUMPING, # ジャンプ開始.
	LANDING, # 着地開始.
}

# ---------------------------------
# onready.
# ---------------------------------
## 設定ファイル.
@onready var _config:Config = preload("res://assets/config.tres")
## Sprite.
@onready var _spr = $Sprite
## デバッグ用ラベル.
@onready var _label = $Label

# ---------------------------------
# var.
# ---------------------------------
## 状態.
var _state = eState.READY
## アニメーション用タイマー.
var _timer_anim = 0.0
## フレームカウンタ.
var _cnt = 0
## 無敵タイマー.
var _timer_muteki = 0.0
## 右向きかどうか.
var _is_right = true # 左向きで開始.
## 着地しているかどうか.
var _is_landing = false
## 飛び降り中かどうか.
var _is_fall_through = false
## 方向.
var _direction = 0
## 踏んでいる床.
var _stomp_tile = Map.eType.NONE
## ダメージ処理フラグ.
var _is_damage = false
## ダメージ値.
var _damage_power = 1
## 回復時間.
var _timer_recovery = 0.0
## ジャンプスケール.
var _jump_scale = eJumpScale.NONE
## ジャンプスケールタイマー.
var _jump_scale_timer = 0.0
## ジャンプ回数.
var _jump_cnt = 0
var _jump_cnt_max = 1
## 獲得したアイテム.
var _itemID:Map.eItem = Map.eItem.NONE
## ジャンプ開始座標.
var _jump_start_y = 0.0

# ---------------------------------
# public functions.
# ---------------------------------
## 開始.
func start() -> void:
	_state = eState.MAIN
	
## 死亡したかどうか.
func is_dead() -> bool:
	return _state == eState.DEAD
	
## アイテム獲得.
func gain_item(itemID:Map.eItem) -> void:
	_itemID = itemID
	match _itemID:
		Map.eItem.JUMP_UP:
			_jump_cnt_max += 1 # ジャンプ最大数アップ.
		Map.eItem.LIFE:
			max_hp += 1 # 最大HP増加.
			hp = max_hp # 最大まで回復.
## アイテムをリセット.
func reset_item() -> void:
	_itemID = Map.eItem.NONE

## 更新.
func update(delta: float) -> void:
	_cnt += 1
	_timer_anim += delta

	match _state:
		eState.READY:
			_update_ready()
		eState.MAIN:
			_update_main(delta)
		eState.DEAD:
			_update_dead(delta)
	
	# デバッグ用更新.
	#_update_debug()

# ---------------------------------
# private functions.
# ---------------------------------
func _ready() -> void:
	hp = _config.hp_init
	if Common.is_lunker:
		hp = 1 # ランカーモードの初期HPは1.
		_jump_cnt_max = 2 # 追加ジャンプが可能.
		_jump_start_y = position.y
	max_hp = hp
	_spr.flip_h = _is_right
	
	var frame = 0
	if Common.is_lunker:
		# ランカーモード.
		frame += OFS_SPR_LUNKER
	_spr.frame = frame

## 更新 > 開始.
func _update_ready() -> void:
	pass

## 更新 > メイン.	
func _update_main(delta:float) -> void:
	# タイマー関連の更新.
	if _timer_muteki > 0:
		_timer_muteki -= delta

	# HP回復処理.
	_update_recovery(delta)
	
	# 移動処理.
	_update_moving()
	
	# アニメーション更新.
	_update_anim()

	move_and_slide()
	
	if _is_landing == false and is_on_floor():
		# 着地した瞬間.
		_jump_scale = eJumpScale.LANDING
		_jump_scale_timer = JUMP_SCALE_TIME
		_jump_cnt = 0 # ジャンプ回数をリセット.
		
		if Common.is_lunker:
			# ランカーモードは落下ダメージがある.
			if position.y - _jump_start_y > LUNKER_JUMP_DAMAGE1:
				_is_damage = true
			if position.y - _jump_start_y > LUNKER_JUMP_DAMAGE2:
				_is_damage = true
				_damage_power = 99 # 即死.
		
		# 高さを記憶.
		_jump_start_y = position.y

	_is_landing = is_on_floor()
	
	_update_jump_scale_anim(delta)
	
	if is_on_floor():
		_set_fall_through(false) # 着地したら飛び降り終了.
	
	_update_collision_post()
	
	if Common.is_lunker:
		# ランカーモードの補助用描画.
		queue_redraw()

## 更新 > 死亡.
func _update_dead(delta:float) -> void:
	# タイマー関連の更新.
	_timer_anim += delta
	_timer_muteki = 0
	_spr.visible = true
	
	# 移動.
	## 重力.
	velocity.y = min(velocity.y + _config.gravity, _config.fall_speed_max)
	_update_horizontal_moving(false)
	move_and_slide()
	
	_update_jump_scale_anim(delta)
	
	# アニメーションを更新.
	_spr.frame = _get_anim(true)
	
## HP回復処理.
func _update_recovery(delta:float) -> void:
	# HPが減っていたら回復処理.
	if hp != max_hp:
		_timer_recovery += delta
		var v = _config.life_ratio
		if _timer_recovery >= v:
			# HP回復.
			hp += 1
			Common.play_se("heal", 1)
			_timer_recovery -= v
	else:
		_timer_recovery = 0	
	
## 飛び降りフラグの設定.
func _set_fall_through(b:bool) -> void:
	if _is_fall_through == b:
		return # すでに設定されていれば更新不要.
	
	_is_fall_through = b
	# コリジョンレイヤーの設定.
	_update_collision_layer()

## 移動処理.
func _update_moving() -> void:
	if _is_damage:
		_is_damage = false
		if _timer_muteki <= 0:
			# ダメージ処理.
			velocity.y = -_config.jump_velocity
			_timer_muteki = _config.muteki_time
			Common.play_se("damage")
			hp -= _damage_power
			_damage_power = 1
			if hp <= 0:
				# 死亡処理へ.
				_state = eState.DEAD
			return
	
	# move_and_slide()で足元のタイルを判定したいので
	# 常に重力を加算.
	velocity.y += _config.gravity
	
	if _is_fall_through:
		# 飛び降り中.
		if _check_fall_through() == false:
			# 飛び降り終了.
			_set_fall_through(false)
	elif _check_fall_through():
		# 飛び降り開始.
		_set_fall_through(true)
		# X方向の速度を0にしてしまう.
		# ※これをしないと is_on_floor() が falseにならない.
		velocity.x = 0
		return

	elif _checkJump():
		# 接地していたらジャンプ.
		velocity.y = _config.jump_velocity * -1
		Common.play_se("jump")
		_jump_cnt += 1 # ジャンプ回数を増やす.
		_jump_scale = eJumpScale.JUMPING
		_jump_scale_timer = JUMP_SCALE_TIME
		# ジャンプした高さを記憶.
		_jump_start_y = position.y

	
	# 左右移動の更新.
	_update_horizontal_moving()

## ジャンプチェック.
func _checkJump() -> bool:
	if Input.is_action_just_pressed("action") == false:
		# ジャンプボタンを押していない.
		return false
	if _jump_cnt >= _jump_cnt_max:
		# ジャンプ最大回数を超えた.
		return false
	
	if _jump_cnt == 0:
		if is_on_floor() == false:
			if _jump_cnt_max >= 2:
				_jump_cnt += 1 # 接地していないペナルティ.
				return true # 2段ジャンプ以上あればできる
			# 最初のジャンプは接地していないとできない.
			return false
		
	# ジャンプする.
	return true
	
## 飛び降り判定.
func _check_fall_through() -> bool:
	if Input.is_action_pressed("action"):
		if Input.is_action_pressed("ui_down"):
			return true # 下＋ジャンプ.
	return false
	
## 左右移動の更新.
func _update_horizontal_moving(can_move:bool=true) -> void:
	if can_move:
		# 左右キーで移動.
		if Input.is_action_pressed("ui_left"):
			_direction = -1
		elif Input.is_action_pressed("ui_right"):
			_direction = 1
	else:
		_direction = 0

	var MOVE_SPEED = _config.move_speed
	var AIR_ACC_RATIO = _config.air_acc_ratio
	
	if is_on_floor() == false:
		# 空中移動.
		velocity.x = velocity.x * (1.0 - AIR_ACC_RATIO) + _direction * MOVE_SPEED * AIR_ACC_RATIO
		return

	# 地上の移動.
	var GROUND_ACC_RATIO = _config.ground_acc_ratio
	var SCROLLPANEL_SPEED = _config.scroll_panel_speed
	# 前回の速度を減衰させる.
	var base = velocity.x * (1.0 - GROUND_ACC_RATIO)
	
	# 踏んでいるタイルごとの処理.
	match _stomp_tile:
		Map.eType.NONE: # 普通の床.
			velocity.x = base + _direction * MOVE_SPEED * GROUND_ACC_RATIO
		Map.eType.SCROLL_L: # ベルト床(左).
			velocity.x = base + (_direction * MOVE_SPEED - SCROLLPANEL_SPEED) * GROUND_ACC_RATIO
		Map.eType.SCROLL_R: # ベルト床(右).
			velocity.x = base + (_direction * MOVE_SPEED + SCROLLPANEL_SPEED) * GROUND_ACC_RATIO
		Map.eType.SLIP: # すべる床.
			pass # 地上では加速できない.

## アニメーションの更新.
func _update_anim() -> void:
	# ダメージ点滅.
	_spr.visible = true
	if _timer_muteki > 0.0 and _cnt%10 < 5:
		_spr.visible = false
	
	# 向きを更新.
	_is_right = (_direction >= 0.0)
	_spr.flip_h = _is_right
	_spr.frame = _get_anim(false)

## アニメーションフレーム番号を取得する.
func _get_anim(is_dead:bool) -> int:
	var ret = 0
	if is_dead():
		# 死亡.
		var idx = (_cnt/7)%4
		ret = ANIM_DEAD_TBL[idx]
	else:
		# 通常.
		var t = int(_timer_anim * 8)
		ret = ANIM_NORMAL_TBL[t%2]
	
	if Common.is_lunker:
		# ランカーモードはオフセットする.
		ret += OFS_SPR_LUNKER
	
	return ret

## コリジョンレイヤーの更新.
func _update_collision_layer() -> void:
	var oneway_bit = Common.get_collision_bit(Common.eCollisionLayer.ONEWAY)
	if _is_fall_through:
		# 飛び降り中なのでビットを下げる.
		collision_mask &= ~oneway_bit
	else:
		collision_mask |= oneway_bit

func _update_collision_post() -> void:
	# 衝突したコリジョンに対応するフラグを設定する.
	var dist = 99999 # 一番近いオブジェクトだけ処理する.
	_stomp_tile = Map.eType.NONE # 処理するタイル.
	
	for i in range(get_slide_collision_count()):
		var col:KinematicCollision2D = get_slide_collision(i)
		# 衝突位置.
		var pos = col.get_position()
		var v = Map.get_floor_type(pos)
		if v == Map.eType.NONE:
			continue # 何もしない.
		if v == Map.eType.SPIKE:
			_is_damage = true # ダメージ処理は最優先.
			continue # 移動処理に直接の影響はない.
		
		if pos.y < position.y:
			# プレイヤーよりも上にあるタイルは処理不要.
			continue
			
		var d = pos.x - position.x
		if d < dist:
			# より近い.
			dist = d
			_stomp_tile = v

## 床種別に対応した処理をする.
func _update_floor_type(delta:float, v:Map.eType) -> bool:
	var ret = false
	match v:
		Map.eType.NONE:
			pass # 何もしない.
		Map.eType.SCROLL_L: # スクロール床(左).
			velocity.x -= _config.scroll_panel_speed * delta
		Map.eType.SCROLL_R: # スクロール床(右).
			velocity.x += _config.scroll_panel_speed * delta
	
	return ret

# ジャンプ・着地によるスケールアニメーションの更新
func _update_jump_scale_anim(delta:float) -> void:
	_jump_scale_timer -= delta
	if _jump_scale_timer <= 0:
		# 演出終了
		_jump_scale = eJumpScale.NONE
	match _jump_scale:
		eJumpScale.JUMPING:
			# 縦に伸ばす
			var d = JUMP_SCALE_VAL_JUMP * Ease.cube_in_out(_jump_scale_timer / JUMP_SCALE_TIME)
			_spr.scale.x = 1 - d
			_spr.scale.y = 1 + d * 3
		eJumpScale.LANDING:
			# 縦に潰す
			var d = JUMP_SCALE_VAL_LANDING * Ease.back_in_out(_jump_scale_timer / JUMP_SCALE_TIME)
			_spr.scale.x = 1 + d
			_spr.scale.y = 1 - d * 1.5
		_:
			# もとに戻す
			_spr.scale.x = 1
			_spr.scale.y = 1

# デバッグ用更新.
func _update_debug() -> void:
	_label.visible = true
	_label.text = "stomp:%d"%_stomp_tile
	_label.text += "\nis_floor:%s"%("true" if is_on_floor() else "false")
	_label.text += "\n" + str(get_floor_normal())

func _draw() -> void:
	if Common.is_lunker == false:
		return # ランカーモードでなければ描画しない.
	if Common.is_lunker_support == false:
		return # 補助線が無効.
	if _is_landing:
		return # 着地中は描画しない.
	
	var center = Vector2(0, _jump_start_y - position.y)
	var idx = 0
	var cols = [Color.YELLOW, Color.RED]
	for dy in [LUNKER_JUMP_DAMAGE1, LUNKER_JUMP_DAMAGE2]:
		var p1 = center + Vector2(-1024, dy)
		var rect = Rect2(p1, Vector2(2048, 1024))
		var c = cols[idx]
		c.a = 0.2
		draw_rect(rect, c)
		idx += 1
		

# ---------------------------------
# properties.
# ---------------------------------
## HP.
var hp:int = 0:
	get:
		return hp
	set(v):
		hp = v
		if hp < 0:
			hp = 0
## 最大HP
var max_hp:int = 0:
	get:
		return max_hp
	set(v):
		max_hp = v

## 獲得したアイテム.
var itemID:Map.eItem:
	get:
		return _itemID
