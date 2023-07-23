extends Sprite2D

# ============================================
# パーティクル基底クラス.
# ============================================
class_name Particle

# --------------------------------------------
# vars.
# --------------------------------------------
var color = Color.WHITE
var gravity = 9.8 * 2
var rotate_speed = 10.0

var _cnt = 0 # move呼び出し回数.
var _anim_cnt = 0 # アニメーション用カウンタ.
var _deg = 0.0 # 移動方向.
var _speed = 0.0 # 移動速度.
var _decay = 0.97 # 減衰率.
var _life = 1.0 # 生存時間.
var _timer = 0.0 # 経過時間.
var _is_auto_destroy = true

# --------------------------------------------
# public functions.
# --------------------------------------------

## セットアップ.
func setup(deg:float, speed:float, life:float, sc:float=1.0, decay:float=0.97):
	_deg = deg
	_speed = speed
	_life = life
	scale = Vector2(sc, sc)
	_decay = decay

## 移動量を取得する.
func get_velocity() -> Vector2:
	var rad = deg_to_rad(_deg)
	var v = Vector2(
		_speed * cos(rad),
		_speed * -sin(rad)
	)
	return v

# 移動量を設定する.
func set_velocity(v:Vector2) -> void:
	var rad = atan2(-v.y, v.x)
	_deg = rad_to_deg(rad)
	_speed = v.length()

## 移動量を加算する.
func add_velocity(v:Vector2) -> void:
	var spd = get_velocity()
	set_velocity(spd + v)	

## 移動する.
func move(delta:float) -> void:
	_cnt += 1
	_anim_cnt += 1
	
	# 重力を加算する.
	add_velocity(Vector2(0, gravity))
	
	_speed *= _decay
	var v = get_velocity()
	position += v * delta
	
	_timer += delta
	
	# 回転する.
	rotation_degrees += rotate_speed
	
	if _is_auto_destroy and is_end():
		# 自動で消滅.
		queue_free()
	
## 経過時間を 0.0 〜 1.0 で取得する.
func get_time_rate() -> float:
	var rate = _timer / _life
	if rate > 1:
		return 1
	return rate

## 終了したかどうか.
func is_end() -> bool:
	return _timer >= _life

# --------------------------------------------
# private functions.
# --------------------------------------------
## 初期化 (オーバーライド用).
func _start() -> void:
	pass
	
## 開始.
func _ready() -> void:
	_anim_cnt = randi()
	_start()

## 更新.
func _physics_process(delta: float) -> void:
	delta *= Common.get_slow_rate()

	_update(delta)
	
	if is_end():
		# 終了したので消去する.
		queue_free()

## 更新(オーバーライド用)
func _update(delta:float) -> void:
	move(delta)
	
	var rate = 1 - get_time_rate()
	if rate < 0.5:
		visible = _anim_cnt%4 < 2
