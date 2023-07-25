extends Resource
# =================================
# config.tres にアタッチするスクリプト.
# =================================
class_name Config

const FPS = 60

# ---------------------------------
@export_category("プレイヤー")
## 初期HP.
@export var hp_init = 3
## 移動速度.
@export var move_speed = 480.0
## 地面での加速係数.
@export var ground_acc_ratio = 0.04
## 空中での加速係数.
@export var air_acc_ratio = 0.01
## ジャンプ力.
@export var jump_velocity = 960.0
## 重力加速度.
@export var gravity = 48.0
## 落下の最高速度.
@export var fall_speed_max = 400.0
## ライフの回復インターバル.
@export var life_ratio = 400.0 / FPS # 6.666sec
## ダメージ時の無敵タイマー.
@export var muteki_time = 50.0 / 60.0 # 0.8333sec
## デバッグ用に左右移動を停止するフラグ
@export var can_stop = true
## ハシゴの上下移動の速度.
@export var ladder_move_speed = 300.0

# ---------------------------------
@export_category("地形")
## ベルト床の速度.
@export var scroll_panel_speed = 400.0#2.0
