# ==================================
# パーティクル生成のユーティリティ.
# ==================================
class_name ParticleUtil

# ----------------------------------
# objs.
# ----------------------------------
const PARTICLE_OBJ = preload("res://src/particle/Particle.tscn")
const PARTICLE_BLOCK_OBJ = preload("res://src/particle/ParticleBlock.tscn")
const PARTICLE_INO_BLUE_OBJ = preload("res://src/particle/ParticleInoBlur.tscn")

# ----------------------------------
# consts.
# ----------------------------------
enum eType {
	SIMPLE,
	BLOCK,
	INO_BLUR,
}
const TBL = {
	eType.SIMPLE: PARTICLE_OBJ,
	eType.BLOCK: PARTICLE_BLOCK_OBJ,
	eType.INO_BLUR: PARTICLE_INO_BLUE_OBJ,
}

# ----------------------------------
# public functions.
# ----------------------------------
static func add(pos:Vector2, type:eType, deg:float, speed:float, life:float, sc:float=1.0, delay:float=0.97) -> Particle:
	var obj = TBL[type].instantiate() as Particle
	# セットアップ.
	obj.setup(deg, speed, life, sc, delay)
	obj.position = pos
	Common.get_layer("particle").add_child(obj)
	return obj
	
