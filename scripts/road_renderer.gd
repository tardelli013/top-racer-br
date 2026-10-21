extends Node2D
## Renderizador pseudo-3D por segmentos (estilo OutRun / Top Gear) em 320x180.
## Desenha fundo em parallax, pista, sprites laterais, adversarios e o carro do jogador.

const RaceScript = preload("res://scripts/race.gd")
const SpriteFactory = preload("res://scripts/sprite_factory.gd")

const W := 320.0
const H := 180.0
const HZ := 84.0
const DRAW_DIST := 200
const SEG_LEN := 200.0
const ROAD_W := 2000.0
const CAM_H := 1000.0
const CAM_DEPTH := 0.84
const CAR_W := 420.0

const MOUNTAIN := [
	[0, 0], [30, 12], [60, 22], [85, 14], [105, 5], [125, 10], [140, 2], [146, 16],
	[156, 34], [170, 44], [184, 44], [196, 34], [204, 16], [212, 4], [240, 14],
	[270, 20], [300, 8], [320, 0],
]
const HILLS := [[0, 0], [40, 8], [80, 13], [130, 6], [180, 12], [240, 7], [290, 13], [320, 0]]
const CLOUDS := [
	[40, 16, 8], [52, 18, 10], [66, 16, 7],
	[170, 26, 9], [184, 24, 11], [198, 27, 7],
	[270, 12, 7], [282, 13, 9],
]

var race
var tex := {}
var car_tex: Array = []
var player_tex: Texture2D
var player_tex_l: Texture2D
var player_tex_r: Texture2D
var sxs := PackedFloat32Array()
var sys := PackedFloat32Array()
var sws := PackedFloat32Array()
var scs := PackedFloat32Array()
var czs := PackedFloat32Array()
var buildings: Array = []
var time := 0.0

var c_fog := Color(0.62, 0.83, 0.95)
var c_sky_top := Color(0.16, 0.42, 0.85)
var c_sky_bot := Color(0.72, 0.9, 1.0)
var c_road: Array = [Color("#7b7b88"), Color("#6a6a77")]
var c_grass: Array = [Color("#43b04c"), Color("#339a41")]
var c_rumble: Array = [Color("#f2f2f2"), Color("#b4b4c0")]
var c_zebra: Array = [Color("#e52d2d"), Color("#f4f4f4")]
var c_lane := Color("#f2f2f2")
var c_bld: Array = [Color("#d9c9b8"), Color("#b8c4d6"), Color("#e7b9a0")]


func setup(r) -> void:
	race = r
	sxs.resize(DRAW_DIST + 2)
	sys.resize(DRAW_DIST + 2)
	sws.resize(DRAW_DIST + 2)
	scs.resize(DRAW_DIST + 2)
	czs.resize(DRAW_DIST + 2)
	tex["palm"] = SpriteFactory.make_palm()
	tex["arrow_l"] = SpriteFactory.make_arrow(false)
	tex["arrow_r"] = SpriteFactory.make_arrow(true)
	tex["bld0"] = SpriteFactory.make_building(32, 64, Color("#d9c9b8"))
	tex["bld1"] = SpriteFactory.make_building(36, 88, Color("#b8c4d6"))
	tex["bld2"] = SpriteFactory.make_building(28, 48, Color("#e7b9a0"))
	player_tex = SpriteFactory.make_uno()
	player_tex_l = SpriteFactory.make_uno("_esq")
	player_tex_r = SpriteFactory.make_uno("_dir")
	for c in race.ai_colors:
		car_tex.append(SpriteFactory.make_car(c, false))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var bx := 0.0
	while bx < W:
		var bw := rng.randf_range(10.0, 22.0)
		buildings.append({"x": bx, "w": bw, "h": rng.randf_range(10.0, 32.0), "c": rng.randi_range(0, 2)})
		bx += bw + rng.randf_range(0.0, 3.0)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	if race == null or race.track == null:
		return
	_draw_background()
	var track = race.track
	var count: int = track.count
	var cam_pos: float = race.cam_pos()
	var base := int(cam_pos / SEG_LEN)
	var frac := fposmod(cam_pos, SEG_LEN) / SEG_LEN
	var cam_x: float = race.x * ROAD_W
	var acc := 0.0
	var dx: float = -(frac * track.curves[base % count])
	for n in range(DRAW_DIST + 2):
		var z := float(base + n) * SEG_LEN - cam_pos
		czs[n] = z
		if z > 0.5:
			var sc := CAM_DEPTH / z
			scs[n] = sc
			sxs[n] = W * 0.5 + sc * (acc - cam_x) * W * 0.5
			sys[n] = HZ + sc * CAM_H * H * 0.5
			sws[n] = sc * ROAD_W * W * 0.5
		else:
			scs[n] = 0.0
		acc += dx
		dx += track.curves[(base + n) % count]

	var by_seg := {}
	if race.state != RaceScript.ST_MENU:
		for c in race.cars:
			var k: int = track.seg_index(c.dist)
			if not by_seg.has(k):
				by_seg[k] = []
			by_seg[k].append(c)

	for n in range(DRAW_DIST - 1, -1, -1):
		if scs[n] <= 0.0 or czs[n] <= CAM_DEPTH:
			continue
		var si := (base + n) % count
		_draw_segment(n, si)
		var fade := clampf(float(DRAW_DIST - n) / 30.0, 0.0, 1.0)
		for s in track.sprites[si]:
			_draw_scenery(n, s, fade)
		if by_seg.has(si):
			for c in by_seg[si]:
				_draw_ai_car(n, c, fade)
	_draw_player()


func _trap(xa1: float, xb1: float, y1: float, xa2: float, xb2: float, y2: float, col: Color) -> void:
	if (xb1 - xa1) + (xb2 - xa2) < 0.2:
		return
	draw_colored_polygon(PackedVector2Array([Vector2(xa1, y1), Vector2(xb1, y1), Vector2(xb2, y2), Vector2(xa2, y2)]), col)


func _draw_segment(n: int, si: int) -> void:
	var f := pow(float(n) / float(DRAW_DIST), 2.0) * 0.85
	var k := 0 if (si % 6) < 3 else 1
	var curve: float = race.track.curves[si]
	var zebra := absf(curve) > 1.4
	var rum: Color = (c_zebra[k] if zebra else c_rumble[k])
	rum = rum.lerp(c_fog, f)
	var road: Color = c_road[k]
	road = road.lerp(c_fog, f)
	var grass: Color = c_grass[k]
	grass = grass.lerp(c_fog, f)
	var x1 := sxs[n]
	var y1 := sys[n]
	var w1 := sws[n]
	var x2 := sxs[n + 1]
	var y2 := sys[n + 1]
	var w2 := sws[n + 1]
	if y2 > y1 - 0.5:
		y2 = y1 - 0.5
	draw_rect(Rect2(0.0, y2, W, y1 - y2), grass)
	var r1 := w1 * 0.12
	var r2 := w2 * 0.12
	_trap(x1 - w1 - r1, x1 - w1, y1, x2 - w2 - r2, x2 - w2, y2, rum)
	_trap(x1 + w1, x1 + w1 + r1, y1, x2 + w2, x2 + w2 + r2, y2, rum)
	_trap(x1 - w1, x1 + w1, y1, x2 - w2, x2 + w2, y2, road)
	if k == 0:
		var lc := c_lane.lerp(c_fog, f)
		for lane in [-0.33, 0.33]:
			var a1: float = x1 + w1 * lane
			var a2: float = x2 + w2 * lane
			_trap(a1 - w1 * 0.02, a1 + w1 * 0.02, y1, a2 - w2 * 0.02, a2 + w2 * 0.02, y2, lc)
	if si < 2:
		for j in 8:
			var a := -1.0 + j * 0.25
			var b := a + 0.25
			var col := Color(0.95, 0.95, 0.95) if (j + si) % 2 == 0 else Color(0.1, 0.1, 0.12)
			_trap(x1 + w1 * a, x1 + w1 * b, y1, x2 + w2 * a, x2 + w2 * b, y2, col.lerp(c_fog, f))


func _draw_scenery(n: int, s: Dictionary, fade: float) -> void:
	var sc := scs[n]
	var wpx: float = sc * float(s.w) * W * 0.5
	if wpx < 1.0:
		return
	var sx: float = sxs[n] + sc * float(s.off) * ROAD_W * W * 0.5
	if sx + wpx * 0.5 < 0.0 or sx - wpx * 0.5 > W:
		return
	var t: Texture2D = tex[s.kind]
	var hpx := wpx * float(t.get_height()) / float(t.get_width())
	draw_texture_rect(t, Rect2(sx - wpx * 0.5, sys[n] - hpx, wpx, hpx), false, Color(1, 1, 1, fade))


func _draw_ai_car(n: int, c: Dictionary, fade: float) -> void:
	var f := fposmod(float(c.dist), SEG_LEN) / SEG_LEN
	var sc := lerpf(scs[n], scs[n + 1], f)
	var wpx := sc * CAR_W * W * 0.5
	if wpx < 1.0:
		return
	var sx := lerpf(sxs[n], sxs[n + 1], f) + sc * float(c.x) * ROAD_W * W * 0.5
	var sy := lerpf(sys[n], sys[n + 1], f)
	var hpx := wpx * 32.0 / 40.0
	draw_rect(Rect2(sx - wpx * 0.5, sy - hpx * 0.06, wpx, maxf(hpx * 0.1, 1.0)), Color(0, 0, 0, 0.35 * fade))
	draw_texture_rect(car_tex[c.color], Rect2(sx - wpx * 0.5, sy - hpx, wpx, hpx), false, Color(1, 1, 1, fade))


func _draw_player() -> void:
	if race.offroad and race.speed > 1500.0:
		for i in 6:
			draw_rect(Rect2(W * 0.5 - 30.0 + randf() * 60.0, H - 6.0 - randf() * 10.0, 2, 2), Color(0.75, 0.6, 0.38))


## Dados do carro do jogador (em px do viewport 320x180) para o overlay em alta resolucao.
func player_state() -> Dictionary:
	var which := 0
	if race.steer < -0.3:
		which = -1
	elif race.steer > 0.3:
		which = 1
	var pct := clampf(race.speed / RaceScript.MAX_SPEED, 0.0, 1.0)
	var shake := 0.0
	if race.offroad and race.speed > 1500.0:
		shake = sin(time * 90.0) * 1.5
	elif pct > 0.6:
		shake = sin(time * 70.0) * 0.5
	if race.bump > 0.0:
		shake += sin(time * 100.0) * 2.0
	var pos := Vector2(W * 0.5 + race.steer * pct * 2.0 + shake * 0.4, H - 2.0 + absf(shake) * 0.5)
	return {"which": which, "pos": pos, "rot": race.steer * 0.02 * pct}


func _poly_tile(pts: Array, ox: float, col: Color) -> void:
	var poly := PackedVector2Array()
	for p in pts:
		poly.append(Vector2(ox + p[0], HZ - p[1]))
	draw_colored_polygon(poly, col)


func _draw_background() -> void:
	for i in 28:
		draw_rect(Rect2(0.0, i * 3.0, W, 3.0), c_sky_top.lerp(c_sky_bot, pow(i / 27.0, 0.8)))
	var sun_x := 235.0 - fposmod(race.bg_off * 0.03, 400.0)
	draw_circle(Vector2(sun_x, 50.0), 20.0, Color(1.0, 0.95, 0.7, 0.35))
	draw_circle(Vector2(sun_x, 50.0), 13.0, Color(1.0, 0.95, 0.65))
	for t in 2:
		var ox := -fposmod(race.bg_off * 0.08, W) + t * W
		for c in CLOUDS:
			draw_circle(Vector2(ox + c[0], c[1]), c[2], Color(1, 1, 1, 0.92))
		draw_rect(Rect2(ox + 34.0, 18.0, 46.0, 7.0), Color(1, 1, 1, 0.92))
		draw_rect(Rect2(ox + 164.0, 28.0, 46.0, 6.0), Color(1, 1, 1, 0.92))
	draw_rect(Rect2(0.0, HZ - 9.0, W, 13.0), Color("#1f78c8"))
	draw_rect(Rect2(0.0, HZ - 9.0, W, 2.0), Color("#8fd0f0"))
	for i in 3:
		draw_rect(Rect2(0.0, HZ - 7.0 + i * 3.0, W, 1.0), Color("#4aa0e6"))
	for i in 14:
		var gx := fposmod(float(i) * 23.0 + time * (4.0 + (i % 3) * 2.0), W)
		draw_rect(Rect2(gx, HZ - 6.0 + (i % 3) * 3.0, 4.0 + (i % 2) * 2.0, 1.0), Color(1, 1, 1, 0.7))
	for t in 2:
		var mo := -fposmod(race.bg_off * 0.15, W) + t * W
		_poly_tile(MOUNTAIN, mo + 3.0, Color("#3d6592"))
		_poly_tile(MOUNTAIN, mo, Color("#6f9bc8"))
	for t in 2:
		var ho := -fposmod(race.bg_off * 0.3, W) + t * W
		_poly_tile(HILLS, ho + 2.0, Color("#2a6e48"))
		_poly_tile(HILLS, ho, Color("#47a068"))
	for t in 2:
		var ox := -fposmod(race.bg_off * 0.5, W) + t * W
		for b in buildings:
			var col: Color = c_bld[b.c]
			var bx: float = ox + b.x
			var bh: float = b.h
			draw_rect(Rect2(bx - 1.0, HZ - bh - 1.0, b.w + 2.0, bh + 1.0), col.darkened(0.55))
			draw_rect(Rect2(bx, HZ - bh, b.w, bh), col)
			draw_rect(Rect2(bx + b.w - 3.0, HZ - bh, 3.0, bh), col.darkened(0.18))
			draw_rect(Rect2(bx, HZ - bh, b.w, 2.0), col.darkened(0.3))
			var wy := HZ - bh + 5.0
			var wi := 0
			while wy < HZ - 3.0:
				var wx := bx + 2.0
				while wx < bx + b.w - 4.0:
					var lit := (wi * 5 + int(b.x)) % 4 == 0
					draw_rect(Rect2(wx, wy, 2.0, 2.0), Color("#ffe58a") if lit else col.darkened(0.4))
					wx += 4.0
					wi += 1
				wy += 4.0
	draw_rect(Rect2(0.0, HZ, W, H - HZ), c_grass[0])
