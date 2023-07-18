extends Node2D

const MAP_WIDTH = 20
const MAP_HEIGHT = 15

@onready var _map = $BgLayer/TileMap

## 開始.
func _ready() -> void:
	Map.setup(_map, MAP_WIDTH, MAP_HEIGHT)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
