extends StaticBody2D
# ======================================
# 壊せるブロック.
# ======================================
class_name Block

# --------------------------------------
# public functions.
# --------------------------------------
## ブロック破壊演出
func vanish(deg:float) -> void:
	var type = ParticleUtil.eType.BLOCK
	for i in range(8):
		var deg2 = deg + randf_range(-60, 60)
		var spd = randf_range(500, 1000)
		ParticleUtil.add(position, type, deg2, spd, 1.0, 0.3, 0.97)
