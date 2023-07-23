extends Area2D
# ==========================================
# シールド.
# ==========================================
class_name Shield

# ------------------------------------------
# signals.
# ------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	if not body is Block:
		return # 念のため.
	
	var block = body as Block
	block.vanish()
	block.queue_free()
	
