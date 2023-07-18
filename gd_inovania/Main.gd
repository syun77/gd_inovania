extends Node2D

const MAP_WIDTH = 20
const MAP_HEIGHT = 15

@onready var _map = $BgLayer/TileMap
@onready var _player = $MainLayer/Player
@onready var _camera = $Camera2D

@onready var _bg_layer = $BgLayer
@onready var _main_layer = $MainLayer

## 開始.
func _ready() -> void:
	var layers = {
		"bg": _bg_layer,
		"main": _main_layer,
	}
	Common.setup(layers, _player, _camera)
	
	Map.setup(_map, MAP_WIDTH, MAP_HEIGHT)
	
	_player.start()

func _physics_process(delta: float) -> void:
	_player.update(delta)	
