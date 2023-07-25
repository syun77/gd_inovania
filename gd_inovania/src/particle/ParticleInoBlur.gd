extends Particle

# ============================================
# 残像.
# ============================================
## 開始.
func _start() -> void:
	gravity = 0.0 # 重力なし.
	rotate_speed = 0.0 # 回転しない.

## 更新.
func _update(delta:float) -> void:	
	move(delta)

	var rate = 1 - get_time_rate()
	modulate.a = 0.5 * rate
