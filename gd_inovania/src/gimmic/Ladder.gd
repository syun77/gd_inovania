extends Area2D
# =========================================
# はしご
# =========================================
class_name Ladder

# -----------------------------------------
# signals.
# -----------------------------------------
## PhysicsBody2Dが接触.
func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return # プレイヤー以外何もしない
	
	var player = body as Player
	# はしご接触数をカウントアップ.
	player.increase_ladder_count()

## PhysicsBody2Dが離れた.
func _on_body_exited(body: Node2D) -> void:
	if not body is Player:
		return # プレイヤー以外何もしない
	
	var player = body as Player
	# はしご接触数を減らす.
	player.decrease_ladder_count()
