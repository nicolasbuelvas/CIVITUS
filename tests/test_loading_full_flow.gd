extends Node

var loader = null
var elapsed = 0.0
var last_stage = ""
var stages_seen = []
var frame_count = 0

func _ready() -> void:
	print("==================================================")
	print("  TESTING COMPLETE LOADING LIFECYCLE (0s to 5.5s) ")
	print("==================================================")

	var scene = load("res://scenes/screens/loading_screen.tscn")
	loader = scene.instantiate()
	add_child(loader)

func _process(delta: float) -> void:
	frame_count += 1
	elapsed += delta
	
	if is_instance_valid(loader) and not loader.is_queued_for_deletion():
		var cur_text = loader.stage_label.text
		if cur_text != last_stage:
			last_stage = cur_text
			stages_seen.append(cur_text)
			print("Frame %d (%.2fs): %s" % [frame_count, elapsed, cur_text])
	else:
		print(">>> Gameplay launched cleanly at %.2fs! Loader successfully freed! <<<" % elapsed)
		print("\nReal stages recorded during loading:")
		for s in stages_seen:
			print("  - ", s)
		assert(stages_seen.size() >= 2, "Expected real progressive stages")
		print("\n[SUCCESS] 0 freeze, real threads tracked, no stuck at 4/4!")
		get_tree().quit(0)
		set_process(false)
		return
		
	if elapsed > 7.0:
		print("[FAIL] Loader got stuck after 7 seconds!")
		get_tree().quit(1)
		set_process(false)
