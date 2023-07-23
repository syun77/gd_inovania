extends Area2D
# ==========================================
# シールド.
# ==========================================
class_name Shield

# ------------------------------------------
# const.
# ------------------------------------------
## シールドタイマー.
const SHIELD_TIME = 0.3

# ------------------------------------------
# vars.
# ------------------------------------------
## シールドタイマー.
var _timer_shield = 0.0

# ------------------------------------------
# public functions.
# ------------------------------------------
func update(delta: float) -> void:
	# シールドタイマーの更新.
	if _timer_shield > 0.0:
		_timer_shield -= delta
	
	if _timer_shield <= 0.0:
		queue_free()

# ------------------------------------------
# private functions.
# ------------------------------------------
func _ready() -> void:
	_timer_shield = SHIELD_TIME

# ------------------------------------------
# signals.
# ------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	if not body is Block:
		return # 念のため.
	
	var block = body as Block
	block.vanish()
	block.queue_free()
	
