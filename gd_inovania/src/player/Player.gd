extends CharacterBody2D
# =================================
# プレイヤー.
# =================================
class_name Player
# ---------------------------------
# object.
# ---------------------------------
const SHIELD_OBJ = preload("res://src/player/Shield.tscn")

# ---------------------------------
# const.
# ---------------------------------
## アニメーションテーブル.
const ANIM_NORMAL_TBL = [0, 1]
const ANIM_DEAD_TBL = [2, 3, 4, 5]
## ジャンプの拡大・縮小演出.
const JUMP_SCALE_TIME := 0.2
const JUMP_SCALE_VAL_JUMP := 0.2
const JUMP_SCALE_VAL_LANDING := 0.25
## ダッシュタイマー.
const DASH_TIME = 0.05
const DASH_SPEED_RATIO = 50.0 # ダッシュ速度倍率.

## 状態.
enum eState {
	READY,
	MAIN,
	DEAD,
}

## 移動状態.
enum eMoveState {
	LANDING, # 地上.
	AIR, # 空中.
	GRABBING_LADDER, # はしごに掴まっている
	CLIMBING_WALL, # 壁登り中.
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
## 移動状態.
var _move_state = eMoveState.AIR
## アニメーション用タイマー.
var _timer_anim = 0.0
## フレームカウンタ.
var _cnt = 0
## 無敵タイマー.
var _timer_muteki = 0.0
## 右向きかどうか.
var _is_right = true # 左向きで開始.
## 飛び降り中かどうか.
var _is_fall_through = false
## 方向.
var _direction = 0
## 接触している壁.
var _touch_tile = Map.eType.NONE
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
## ダッシュ回数.
var _dash_cnt = 0
var _dash_cnt_max = 1
## 獲得したアイテム.
var _itemID:Map.eItem = Map.eItem.NONE
## はしご接触数.
var _ladder_count = 0
## ダッシュタイマー.
var _timer_dash = 0.0
## ダッシュ方向.
var _dash_direction := Vector2.ZERO
## シールド.
var _shield:Shield = null

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
func gain_item(id:Map.eItem) -> void:
	_itemID = id
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
	
## はしご接触数のカウント
func increase_ladder_count() -> void:
	_ladder_count += 1
func decrease_ladder_count() -> void:
	_ladder_count -= 1

# ---------------------------------
# private functions.
# ---------------------------------
func _ready() -> void:
	hp = _config.hp_init
	max_hp = hp
	_spr.flip_h = _is_right
	_direction = 1
	
	var frame = 0
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
	_update_moving(delta)
	
	# アニメーション更新.
	_update_anim()

	move_and_slide()
	
	if _is_landing() == false and is_on_floor():
		# 着地した瞬間.
		_just_landing(true)
	
	# 移動状態の更新.
	_update_move_state()
	
	# スケールアニメの更新
	_update_jump_scale_anim(delta)
	
	if _is_landing():
		_set_fall_through(false) # 着地したら飛び降り終了.
	
	_update_collision_post()
	
## 更新 > 死亡.
func _update_dead(delta:float) -> void:
	# タイマー関連の更新.
	_timer_anim += delta
	_timer_muteki = 0
	_spr.visible = true
	
	# 移動.
	## 重力.
	velocity.y = min(velocity.y + _config.gravity, _config.fall_speed_max)
	_update_horizontal_moving(false, 1)
	move_and_slide()
	
	_update_jump_scale_anim(delta)
	
	# アニメーションを更新.
	_spr.frame = _get_anim()

## 着地した瞬間.
func _just_landing(is_scale_anim:bool) -> void:
	if is_scale_anim:
		# 着地演出.
		_jump_scale = eJumpScale.LANDING
		_jump_scale_timer = JUMP_SCALE_TIME
	_jump_cnt = 0 # ジャンプ回数をリセット.
	_dash_cnt = 0 # ダッシュ回数をリセット.

	
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
func _update_moving(delta:float) -> void:
	# ダッシュタイマー更新.
	if _timer_dash > 0.0:
		_timer_dash -= delta
	if _is_shield():
		# シールド更新.
		_shield.update(delta)
	
	# ダメージ処理.
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
	
	if _is_add_gravity():
		# move_and_slide()で足元のタイルを判定したいので
		# 常に重力を加算.
		velocity.y += _config.gravity
	
	var can_move = true
	if _is_grabbing_ladder() or _is_climbing_wall():
		# 上下ではしご移動 or 壁登り.
		var v = Input.get_axis("ui_up", "ui_down")
		if v != 0:
			velocity.x = 0 # X方向を止める.
			velocity.y = 300 * v
		else:
			velocity.y = 0
		if _is_climbing_wall():
			# 壁のぼり中は左右移動できない.
			can_move = false
		
		if _check_jump():
			# ジャンプ開始.
			var is_wall_jump = _is_climbing_wall()
			_start_jump(is_wall_jump)
			_move_state = eMoveState.AIR
		elif _check_dash():
			# ダッシュ開始.
			_start_dash()
	elif _is_fall_through:
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

	elif _check_jump():
		# ジャンプする.
		_start_jump()
		
	elif _check_dash():
		# ダッシュする.
		_start_dash()
	
	# 左右移動の更新.
	_update_horizontal_moving(can_move)

## ジャンプチェック.
func _check_jump() -> bool:
	if Input.is_action_just_pressed("action") == false:
		# ジャンプボタンを押していない.
		return false
	if _jump_cnt >= _jump_cnt_max:
		# ジャンプ最大回数を超えた.
		return false
	
	if _is_grabbing_ladder():
		# はしご掴まっていればジャンプできる.
		return true
		
	if _is_climbing_wall():
		# 壁登り中もジャンプできる.
		return true
	
	if _jump_cnt == 0:
		if is_on_floor() == false:
			if _jump_cnt_max >= 2:
				_jump_cnt += 1 # 接地していないペナルティ.
				return true # 2段ジャンプ以上あればできる
			# 最初のジャンプは接地していないとできない.
			return false
		
	# ジャンプする.
	return true

## ジャンプ開始.
func _start_jump(is_wall_jump:bool = false) -> void:
	velocity.y = _config.jump_velocity * -1
	Common.play_se("jump")
	
	if is_wall_jump:
		# 壁ジャンプは壁と反対側に移動させないと吸着してしまう.
		var dir = get_wall_normal().x
		_update_horizontal_moving(false, dir, 10.0)
		if Input.is_action_pressed("ui_down"):
			# 下押しながらの場合はY方向への移動はしない.
			velocity.y = 0
	
	# 空中状態にする.
	_move_state = eMoveState.AIR
	
	_jump_cnt += 1 # ジャンプ回数を増やす.
	_jump_scale = eJumpScale.JUMPING
	_jump_scale_timer = JUMP_SCALE_TIME

## ダッシュチェック.
func _check_dash() -> bool:
	if Input.is_action_just_pressed("special") == false:
		return false # ダッシュボタンを押していない.
	
	if _dash_cnt >= _dash_cnt_max:
		return false # ダッシュ回数が足りない.
	
	return true
	
## ダッシュ開始.
func _start_dash() -> void:
	# ダッシュ回数を増やす.
	_dash_cnt += 1
	# ダッシュ方向を設定.
	_dash_direction.x = Input.get_axis("ui_left", "ui_right")
	_dash_direction.y = Input.get_axis("ui_up", "ui_down")
	_dash_direction = _dash_direction.normalized()
	if _dash_direction.length() == 0:
		# 入力がない場合は現在向いている方向にダッシュする.
		_dash_direction = Vector2(_direction, 0)
	
	# タイマー設定.
	_timer_dash = DASH_TIME
	
	position.y -= 1 # 1px浮かす.
	_move_state = eMoveState.AIR

	# シールドを生成.
	if is_instance_valid(_shield):
		# 生成済みの場合は破棄する.
		_shield.queue_free()
	_shield = SHIELD_OBJ.instantiate()
	add_child(_shield)
	# シールドの向きをダッシュ方向にする.
	_shield.rotation = _dash_direction.angle()
	
## ダッシュ中かどうか.
func _is_dash() -> bool:
	return _timer_dash > 0.0

## シールド表示中かどうか.
func _is_shield() -> bool:
	return is_instance_valid(_shield)
	
## 飛び降り判定.
func _check_fall_through() -> bool:
	if Input.is_action_pressed("ui_down"):
		return true # 下.
	
	#if Input.is_action_pressed("action"):
	#	if Input.is_action_pressed("ui_down"):
	#		return true # 下＋ジャンプ.
	return false
	
## 左右移動の更新.
func _update_horizontal_moving(can_move:bool=true, force_direction:int=0, force_direction_multipuly:float=0.0) -> void:
	if can_move:
		# 左右キーで移動できる.
		if Input.is_action_pressed("ui_left"):
			_direction = -1
		elif Input.is_action_pressed("ui_right"):
			_direction = 1
		
	if force_direction != 0:
		# 強制的に方向を指定.
		_direction = force_direction

	var dir = _direction
	if _config.can_stop and can_move:
		# デバッグ用に止まれる.
		if Input.get_axis("ui_left", "ui_right") == 0:
			dir = 0

	var MOVE_SPEED = _config.move_speed
	var AIR_ACC_RATIO = _config.air_acc_ratio
	
	if _is_dash():
		# ダッシュ中.
		var DASH_ACC_RATIO = _config.ground_acc_ratio * DASH_SPEED_RATIO
		velocity = _dash_direction * MOVE_SPEED * DASH_ACC_RATIO
		return
	
	if _is_in_the_air():
		# 空中移動.
		velocity.x = velocity.x * (1.0 - AIR_ACC_RATIO) + dir * MOVE_SPEED * AIR_ACC_RATIO
		return

	# 地上の移動.
	var GROUND_ACC_RATIO = _config.ground_acc_ratio
	var SCROLLPANEL_SPEED = _config.scroll_panel_speed
	# 前回の速度を減衰させる.
	var base = velocity.x * (1.0 - GROUND_ACC_RATIO)
	base += (dir * MOVE_SPEED * GROUND_ACC_RATIO * force_direction_multipuly)
	
	# 踏んでいるタイルごとの処理.
	match _touch_tile:
		Map.eType.NONE, Map.eType.CLIMBBING_WALL: # 普通の床 or 登れる壁.
			velocity.x = base + dir * MOVE_SPEED * GROUND_ACC_RATIO
		Map.eType.SCROLL_L: # ベルト床(左).
			velocity.x = base + (dir * MOVE_SPEED - SCROLLPANEL_SPEED) * GROUND_ACC_RATIO
		Map.eType.SCROLL_R: # ベルト床(右).
			velocity.x = base + (dir * MOVE_SPEED + SCROLLPANEL_SPEED) * GROUND_ACC_RATIO
		Map.eType.SLIP: # すべる床.
			pass # 地上では加速できない.

## アニメーションの更新.
func _update_anim() -> void:
	# ダメージ点滅.
	_spr.visible = true
	if _timer_muteki > 0.0 and _cnt%10 < 5:
		_spr.visible = false
	
	# 向きを更新.
	_update_direction()
	
	# ダッシュ演出.
	if _is_shield() and _cnt%3 == 0:
		var p = ParticleUtil.add(position, ParticleUtil.eType.INO_BLUR, 0, 0, 0.3, 1.0)
		p.flip_h = _spr.flip_h

## 向きを更新.
func _update_direction() -> void:
	_is_right = (_direction >= 0.0)
	_spr.flip_h = _is_right
	_spr.frame = _get_anim()

## アニメーションフレーム番号を取得する.
func _get_anim() -> int:
	var ret = 0
	if is_dead():
		# 死亡.
		var idx = int(_cnt/7.0)%4
		ret = ANIM_DEAD_TBL[idx]
	else:
		# 通常.
		var t = int(_timer_anim * 8)
		ret = ANIM_NORMAL_TBL[t%2]
	
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
	_touch_tile = Map.eType.NONE # 処理するタイル.
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
		
		#if pos.y < position.y:
		#	# プレイヤーよりも上にあるタイルは処理不要.
		#	continue
			
		var d = abs(pos.x - position.x)
		if d < dist:
			# より近い.
			dist = d
			_touch_tile = v

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

# はしごを掴めるかどうか.
func _can_grab_ladder() -> bool:
	return _ladder_count > 0
	
# 移動状態の更新.
func _update_move_state() -> void:
	match _move_state:
		eMoveState.GRABBING_LADDER:
			if _can_grab_ladder() == false:
				# はしごから離れた.
				_move_state = eMoveState.AIR
				velocity.y = 0
			elif is_on_floor():
				_move_state = eMoveState.LANDING
		eMoveState.CLIMBING_WALL:
			if _is_on_wall() == false:
				# 壁から離れた.
				_move_state = eMoveState.AIR
		eMoveState.AIR:
			if is_on_floor():
				_move_state = eMoveState.LANDING
			elif _is_on_wall():
				# 壁に掴まる.
				_move_state = eMoveState.CLIMBING_WALL
				# 着地 (着地アニメなし)
				_just_landing(false)
		eMoveState.LANDING:
			if is_on_floor() == false:
				_move_state = eMoveState.AIR
	
	if _is_grabbing_ladder() == false:
		# はしごチェック.
		if _can_grab_ladder():
			if Input.get_axis("ui_up", "ui_down") != 0:
				# はしご開始.
				_move_state = eMoveState.GRABBING_LADDER
				# 着地 (着地アニメなし)
				_just_landing(false)
	
## 着地しているかどうか.
func _is_landing() -> bool:
	return _move_state == eMoveState.LANDING
	
## 空中かどうか.
func _is_in_the_air() -> bool:
	return _move_state == eMoveState.AIR

## はしごを掴んでいるかどうか.
func _is_grabbing_ladder() -> bool:
	return _move_state == eMoveState.GRABBING_LADDER
	
## 掴める壁に触れているかどうか.
func _is_on_wall() -> bool:
	if is_on_wall() == false:
		return false # 壁に接触していない.
	if _touch_tile != Map.eType.CLIMBBING_WALL:
		return false # 掴まれる壁ではない.
	
	return true

## 壁を掴んでいるかどうか.
func _is_climbing_wall() -> bool:
	return _move_state == eMoveState.CLIMBING_WALL

## 重力の影響を受ける移動状態かどうか.
func _is_add_gravity() -> bool:
	if _is_dash():
		return false # ダッシュ中は重力の影響を受けない.
	
	match _move_state:
		eMoveState.GRABBING_LADDER, eMoveState.CLIMBING_WALL:
			return false
		_:
			return true

## デバッグ用更新.
func _update_debug() -> void:
	_label.visible = true
	_label.text = "move:%s"%(eMoveState.keys()[_move_state])
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
