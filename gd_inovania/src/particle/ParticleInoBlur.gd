extends Particle

# ============================================
# プレイヤーの残像.
# @note Spriteのテクスチャは外部から設定する.
# ============================================
## 開始.
func _start() -> void:
	gravity = 0.0 # 重力なし.
	rotate_speed = 0.0 # 回転しない.

## 更新.
func _update(delta:float) -> void:	
	move(delta)

	# 透過で消える.
	var rate = 1 - get_time_rate()
	modulate.a = 0.5 * rate
