extends Node
## Simulacao da corrida: jogador, adversarios (IA), voltas, posicao e estados.

const TrackScript = preload("res://scripts/track.gd")

const ST_MENU := 0
const ST_COUNTDOWN := 1
const ST_RACING := 2
const ST_FINISHED := 3

const SEG_LEN := 200.0
const MAX_SPEED := 10000.0
const PLAYER_Z := 840.0
const LAPS := 3
const CENTRIFUGAL := 0.25
const AI_SKILL := [0.86, 0.89, 0.92, 0.84, 0.95, 0.88]
const AI_LANE := [-0.6, 0.5, -0.2, 0.3, 0.7, -0.45]

signal race_finished

var ai_colors: Array = [
	Color("#d62828"), Color("#1d70d6"), Color("#f2c500"),
	Color("#2aa84a"), Color("#7a3fc0"), Color("#ee7d1a"),
]

var track
var state: int = ST_MENU
var paused := false
var cars: Array = []

var dist := 0.0
var speed := 0.0
var x := 0.0
var steer := 0.0
var offroad := false
var bump := 0.0
var player_curve := 0.0
var bg_off := 0.0

var countdown := 0.0
var go_timer := 0.0
var race_time := 0.0
var lap := 1
var max_lap := 1
var lap_start := 0.0
var best_lap := -1.0
var final_position := 0
var final_time := 0.0
var _menu_time := 0.0


func _ready() -> void:
	track = TrackScript.new()
	_reset_cars()


func cam_pos() -> float:
	return fposmod(dist - PLAYER_Z, track.length)


func player_rank() -> int:
	if state == ST_FINISHED:
		return final_position
	var r := 1
	for c in cars:
		if c.dist > dist:
			r += 1
	return r


func start_race() -> void:
	_reset_cars()
	state = ST_COUNTDOWN
	paused = false
	countdown = 3.99
	go_timer = 0.0


func _reset_cars() -> void:
	cars.clear()
	var ai_i := 0
	for k in 7:
		var d := -(k + 1) * 650.0
		var gx := -0.5 if k % 2 == 0 else 0.5
		if k == 4:
			dist = d
			x = gx
		else:
			cars.append({
				"id": ai_i, "dist": d, "speed": 0.0, "x": gx,
				"lane": AI_LANE[ai_i], "skill": AI_SKILL[ai_i], "color": ai_i,
			})
			ai_i += 1
	speed = 0.0
	steer = 0.0
	bump = 0.0
	race_time = 0.0
	lap = 1
	max_lap = 1
	lap_start = 0.0
	best_lap = -1.0
	final_position = 0
	final_time = 0.0


func _process(delta: float) -> void:
	if track == null or paused:
		return
	var dt := minf(delta, 0.05)
	player_curve = track.curves[track.seg_index(dist)]
	bump = maxf(bump - dt, 0.0)
	match state:
		ST_MENU:
			_menu_time += dt
			speed = 4500.0
			dist += speed * dt
			x = 0.3 * sin(_menu_time * 0.4)
			steer = cos(_menu_time * 0.4) * 0.5
		ST_COUNTDOWN:
			countdown -= dt
			if countdown <= 0.0:
				state = ST_RACING
				go_timer = 1.0
		ST_RACING, ST_FINISHED:
			go_timer = maxf(go_timer - dt, 0.0)
			_update_player(dt)
			_update_ai(dt)
			if state == ST_RACING:
				race_time += dt
				_check_laps()
	bg_off += player_curve * clampf(speed / MAX_SPEED, 0.0, 1.0) * dt * 40.0


func _update_player(dt: float) -> void:
	var drive := state == ST_RACING
	var up := drive and (Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	var down := drive and (Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	var left := drive and (Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var right := drive and (Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
	steer = (1.0 if right else 0.0) - (1.0 if left else 0.0)

	var pct := clampf(speed / MAX_SPEED, -0.3, 1.0)
	var dx := dt * 2.2 * pct
	if drive:
		x += dx * steer
	else:
		x = move_toward(x, 0.0, dt * 0.6)
	x -= dx * maxf(pct, 0.0) * player_curve * CENTRIFUGAL

	if not drive:
		speed = move_toward(speed, 0.0, MAX_SPEED * 0.25 * dt)
	else:
		if up:
			speed += MAX_SPEED / 4.0 * dt
		elif down:
			speed -= MAX_SPEED * 0.9 * dt
		else:
			speed = move_toward(speed, 0.0, MAX_SPEED / 6.0 * dt)
		offroad = absf(x) > 1.08
		if offroad and speed > MAX_SPEED * 0.25:
			speed = move_toward(speed, MAX_SPEED * 0.2, MAX_SPEED * 0.7 * dt)
	speed = clampf(speed, -MAX_SPEED * 0.12, MAX_SPEED)
	x = clampf(x, -2.6, 2.6)

	_collide_scenery()
	_collide_cars(dt)
	dist += speed * dt


func _collide_scenery() -> void:
	for s in track.sprites[track.seg_index(dist)]:
		var off: float = s.off
		var hit: float = s.hit
		if s.solid and absf(x - off) < hit:
			if speed > MAX_SPEED * 0.15:
				speed = MAX_SPEED * 0.1
				bump = 0.3
			x = off - signf(off) * (hit + 0.05)


func _collide_cars(dt: float) -> void:
	for c in cars:
		var dz: float = fposmod(c.dist - dist + track.length * 0.5, track.length) - track.length * 0.5
		var dxc: float = c.x - x
		if absf(dz) < 380.0 and absf(dxc) < 0.22:
			var side := signf(x - c.x)
			if side == 0.0:
				side = 1.0
			x += side * dt * 1.5
			c.x -= side * dt * 0.8
			bump = 0.25
			if dz > 0.0:
				speed = minf(speed, c.speed * 0.92)
			else:
				c.speed = minf(c.speed, speed + 400.0)


func _update_ai(dt: float) -> void:
	var all: Array = cars.duplicate()
	all.append({"id": -1, "dist": dist, "x": x, "speed": speed})
	for c in cars:
		var curve: float = track.curves[track.seg_index(c.dist)]
		var skill: float = c.skill
		var target: float = MAX_SPEED * skill * (1.0 - minf(absf(curve) * 0.035, 0.2))
		var gap: float = c.dist - dist
		if gap > 8000.0:
			target *= 0.94
		elif gap < -8000.0:
			target *= 1.05
		var desired: float = c.lane
		for o in all:
			if o.id == c.id:
				continue
			var dz: float = fposmod(o.dist - c.dist + track.length * 0.5, track.length) - track.length * 0.5
			if dz > 0.0 and dz < 1400.0 and absf(o.x - c.x) < 0.32:
				var ox: float = o.x
				var cx: float = c.x
				desired = clampf(ox + (0.45 if cx >= ox else -0.45), -0.85, 0.85)
				if dz < 500.0:
					target = minf(target, maxf(float(o.speed), 0.0) + 600.0)
		var cs: float = c.speed
		var rate := MAX_SPEED * 0.3 if target > cs else MAX_SPEED * 0.6
		c.speed = move_toward(cs, target, rate * dt)
		c.x = move_toward(float(c.x), desired, 0.8 * dt)
		c.dist = float(c.dist) + float(c.speed) * dt


func _check_laps() -> void:
	var total: float = LAPS * track.length
	if dist >= total:
		var lt := race_time - lap_start
		if best_lap < 0.0 or lt < best_lap:
			best_lap = lt
		final_time = race_time
		var r := 1
		for c in cars:
			if c.dist >= total:
				r += 1
		final_position = r
		lap = LAPS
		state = ST_FINISHED
		race_finished.emit()
		return
	var new_lap := maxi(int(floor(dist / track.length)) + 1, 1)
	if new_lap > max_lap:
		var lt2 := race_time - lap_start
		if best_lap < 0.0 or lt2 < best_lap:
			best_lap = lt2
		lap_start = race_time
		max_lap = new_lap
	lap = mini(new_lap, LAPS)
