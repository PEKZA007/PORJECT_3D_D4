extends SceneTree

func _initialize() -> void:
	var progress = preload("res://scripts/mode_progress.gd").new()
	progress.load_progress()
	var valid: bool = progress.unlocked and progress.anomalies.size() == 27 and progress.endings.has("normal") and progress.endings.has("true")
	print("SAVE UNLOCK: ", "PASS" if valid else "FAIL")
	quit(0 if valid else 1)
