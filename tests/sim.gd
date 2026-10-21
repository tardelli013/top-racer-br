extends Node
## Teste automatizado: dirige o Uno com autopiloto simples e imprime o progresso. Uso:
## godot --headless --path . --script res://tests/sim.gd  (ou cena tests/sim.tscn)
const MainScript = preload("res://scripts/main.gd")
var main
var t := 0.0
var shot := false

func _ready() -> void:
	main = MainScript.new()
	add_child(main)
	await get_tree().process_frame
	main.start_game()
	if "--shot" in OS.get_cmdline_user_args():
		shot = true

func _press(k: Key, on: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = on
	Input.parse_input_event(e)

func _process(delta: float) -> void:
	t += delta
	var r = main.race
	if r == null: return
	_press(KEY_W, true)
	# autopiloto: corrige para o centro, contra a curva
	var want: float = clampf(-(r.x - 0.0) * 2.0 + r.player_curve * 0.15, -1, 1)
	_press(KEY_A, want < -0.15)
	_press(KEY_D, want > 0.15)
	if Engine.get_process_frames() % 300 == 0:
		print("t=%.1f state=%d lap=%d dist=%.0f speed=%.0f x=%.2f rank=%d off=%s" % [t, r.state, r.lap, r.dist, r.speed, r.x, r.player_rank(), r.offroad])
	if shot and t > 6.0:
		var img := get_viewport().get_texture().get_image()
		img.save_png("/tmp/top_shot.png")
		get_tree().quit()
	if r.state == 3:
		print("FINISHED pos=%d time=%.1f best=%.1f" % [r.final_position, r.final_time, r.best_lap])
		get_tree().quit()
	if t > 400.0:
		print("TIMEOUT"); get_tree().quit()
