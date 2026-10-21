extends Control
## HUD em alta resolucao (1280x720): velocidade, posicao, volta, tempo, minimapa, menu e resultado.

const RaceScript = preload("res://scripts/race.gd")

var race
var main
var hud_nodes: Array = []
var overlay: ColorRect
var menu_box: Control
var result_box: Control
var lbl_speed: Label
var lbl_pos: Label
var lbl_lap: Label
var lbl_time: Label
var lbl_center: Label
var lbl_res_pos: Label
var lbl_res_time: Label
var lbl_res_best: Label


func setup(r, m) -> void:
	race = r
	main = m
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	overlay = ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	lbl_speed = _label(self, "000", 80, Vector2(20, 590), Vector2(190, 100), HORIZONTAL_ALIGNMENT_RIGHT, Color("#ffe040"))
	_label(self, "km/h", 28, Vector2(215, 650), Vector2(100, 40), HORIZONTAL_ALIGNMENT_LEFT, Color.WHITE)
	lbl_pos = _label(self, "7º", 110, Vector2(1000, 0), Vector2(250, 130), HORIZONTAL_ALIGNMENT_RIGHT, Color("#ff5a3c"))
	lbl_lap = _label(self, "VOLTA 1/3", 36, Vector2(30, 20), Vector2(400, 50), HORIZONTAL_ALIGNMENT_LEFT, Color.WHITE)
	lbl_time = _label(self, "TEMPO 00:00.00", 30, Vector2(30, 70), Vector2(400, 40), HORIZONTAL_ALIGNMENT_LEFT, Color("#bfe6ff"))
	lbl_center = _label(self, "", 140, Vector2(0, 200), Vector2(1280, 220), HORIZONTAL_ALIGNMENT_CENTER, Color("#ffe040"))
	hud_nodes = [lbl_speed, lbl_pos, lbl_lap, lbl_time]

	_build_menu()
	_build_result()


func _label(parent: Control, text: String, font_size: int, pos: Vector2, sz: Vector2, align: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = sz
	l.horizontal_alignment = align as HorizontalAlignment
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.15))
	l.add_theme_constant_override("outline_size", maxi(2, int(font_size / 8.0)))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _button(parent: Control, text: String, pos: Vector2, sz: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 34)
	b.pressed.connect(main.start_game)
	parent.add_child(b)
	return b


func _build_menu() -> void:
	menu_box = Control.new()
	menu_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu_box)
	_label(menu_box, "TOP GEAR BRASIL", 104, Vector2(0, 70), Vector2(1280, 130), HORIZONTAL_ALIGNMENT_CENTER, Color("#ffb020"))
	_label(menu_box, "Protótipo pseudo-3D  •  Fiat Uno Mille de firma", 30, Vector2(0, 205), Vector2(1280, 40), HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE)
	_button(menu_box, "Iniciar corrida", Vector2(490, 320), Vector2(300, 76))
	_label(menu_box, "W ou Seta para cima: acelerar     S ou Seta para baixo: frear / ré\nA / D ou Setas esquerda / direita: virar\nEsc: pausar     R: reiniciar     Enter: iniciar", 26, Vector2(0, 450), Vector2(1280, 140), HORIZONTAL_ALIGNMENT_CENTER, Color("#d8ecff"))


func _build_result() -> void:
	result_box = Control.new()
	result_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result_box)
	_label(result_box, "CORRIDA FINALIZADA", 84, Vector2(0, 90), Vector2(1280, 110), HORIZONTAL_ALIGNMENT_CENTER, Color("#ffb020"))
	lbl_res_pos = _label(result_box, "", 64, Vector2(0, 220), Vector2(1280, 80), HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE)
	lbl_res_time = _label(result_box, "", 36, Vector2(0, 310), Vector2(1280, 50), HORIZONTAL_ALIGNMENT_CENTER, Color("#bfe6ff"))
	lbl_res_best = _label(result_box, "", 36, Vector2(0, 360), Vector2(1280, 50), HORIZONTAL_ALIGNMENT_CENTER, Color("#bfe6ff"))
	_button(result_box, "Correr novamente", Vector2(450, 460), Vector2(380, 76))


func fmt_time(t: float) -> String:
	return "%02d:%05.2f" % [int(t / 60.0), fmod(t, 60.0)]


func _process(_delta: float) -> void:
	var st: int = race.state
	var menu := st == RaceScript.ST_MENU
	var fin := st == RaceScript.ST_FINISHED
	menu_box.visible = menu
	result_box.visible = fin
	overlay.visible = menu or fin or race.paused
	overlay.color = Color(0.08, 0.02, 0.16, 0.5) if menu else Color(0.0, 0.0, 0.0, 0.55)
	for n in hud_nodes:
		n.visible = not menu and not fin
	lbl_speed.text = "%03d" % int(maxf(race.speed, 0.0) / RaceScript.MAX_SPEED * 240.0)
	lbl_pos.text = "%dº" % race.player_rank()
	lbl_lap.text = "VOLTA %d/%d" % [race.lap, RaceScript.LAPS]
	lbl_time.text = "TEMPO " + fmt_time(race.race_time)
	var msg := ""
	if race.paused:
		msg = "PAUSADO"
	elif st == RaceScript.ST_COUNTDOWN:
		msg = str(int(ceil(race.countdown)))
	elif race.go_timer > 0.0 and st == RaceScript.ST_RACING:
		msg = "VAI!"
	lbl_center.text = msg
	if fin:
		lbl_res_pos.text = "Posição final: %dº de 7" % race.final_position
		lbl_res_time.text = "Tempo total: " + fmt_time(race.final_time)
		lbl_res_best.text = "Melhor volta: " + (fmt_time(race.best_lap) if race.best_lap >= 0.0 else "--")
	queue_redraw()


func _draw() -> void:
	if race == null or race.state == RaceScript.ST_MENU or race.state == RaceScript.ST_FINISHED:
		return
	var segs := 20
	var pct := clampf(race.speed / RaceScript.MAX_SPEED, 0.0, 1.0)
	for i in segs:
		var c := Color.from_hsv(0.33 * (1.0 - float(i) / (segs - 1)), 0.85, 1.0)
		if float(i) >= pct * segs:
			c = Color(c.r * 0.2, c.g * 0.2, c.b * 0.2, 0.7)
		draw_rect(Rect2(30 + i * 14, 570, 11, 14), c)
	var box := Rect2(1090, 540, 160, 160)
	draw_rect(box, Color(0, 0, 0, 0.5))
	draw_rect(box, Color(1, 1, 1, 0.6), false, 2.0)
	var pts: PackedVector2Array = race.track.map_pts
	var line := PackedVector2Array()
	for i in range(0, pts.size(), 6):
		line.append(_map(box, pts[i]))
	line.append(line[0])
	draw_polyline(line, Color("#e8e8f0"), 4.0)
	for c in race.cars:
		draw_circle(_map(box, pts[race.track.seg_index(c.dist)]), 5.0, race.ai_colors[c.color])
	draw_circle(_map(box, pts[race.track.seg_index(race.dist)]), 7.0, Color("#ffffff"))
	draw_circle(_map(box, pts[race.track.seg_index(race.dist)]), 4.0, Color("#ff2a2a"))


func _map(box: Rect2, p: Vector2) -> Vector2:
	return box.position + Vector2(14, 14) + p * (box.size - Vector2(28, 28))
