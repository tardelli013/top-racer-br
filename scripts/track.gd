extends RefCounted
## Pista definida em dados: lista de trechos [entrada, manutencao, saida, curvatura].
## Gera segmentos (curvatura), cenario lateral e o tracado do minimapa.

const SEG_LEN := 200.0

# [segmentos de entrada, de manutencao, de saida, curvatura (+ direita / - esquerda)]
const SECTIONS := [
	[0, 70, 0, 0.0],
	[30, 50, 30, 3.0],
	[0, 40, 0, 0.0],
	[20, 40, 20, -4.0],
	[20, 30, 20, 2.5],
	[20, 30, 20, -2.5],
	[0, 70, 0, 0.0],
	[35, 60, 35, 5.0],
	[0, 50, 0, 0.0],
	[25, 50, 25, -3.0],
	[0, 60, 0, 0.0],
	[30, 60, 30, 4.0],
	[20, 30, 20, -2.0],
	[0, 70, 0, 0.0],
]
const LENGTH_FACTOR := 1.5

var curves := PackedFloat32Array()
var sprites: Array = []
var map_pts := PackedVector2Array()
var count := 0
var length := 0.0


func _init() -> void:
	for s in SECTIONS:
		_add_road(int(s[0] * LENGTH_FACTOR), int(s[1] * LENGTH_FACTOR), int(s[2] * LENGTH_FACTOR), s[3])
	while curves.size() % 6 != 0:
		curves.append(0.0)
	count = curves.size()
	length = count * SEG_LEN
	_build_scenery()
	_build_map()


func seg_index(d: float) -> int:
	return int(fposmod(d, length) / SEG_LEN) % count


func _add_road(enter: int, hold: int, leave: int, curve: float) -> void:
	for n in enter:
		var p := float(n) / enter
		curves.append(curve * p * p)
	for n in hold:
		curves.append(curve)
	for n in leave:
		var p := float(n) / leave
		curves.append(curve * (1.0 - (-cos(p * PI) / 2.0 + 0.5)))


func _build_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in count:
		sprites.append([])
	for i in range(3, count, 5):
		var side := 1.0 if (i % 10) < 5 else -1.0
		sprites[i].append({"kind": "palm", "off": side * (1.4 + rng.randf() * 0.9), "w": 520.0, "solid": true, "hit": 0.16})
		if i % 15 == 3:
			sprites[(i + 2) % count].append({"kind": "palm", "off": -side * (1.5 + rng.randf() * 1.2), "w": 520.0, "solid": true, "hit": 0.16})
	for i in range(10, count, 18):
		var side := 1.0 if rng.randf() < 0.5 else -1.0
		sprites[i].append({"kind": "bld%d" % rng.randi_range(0, 2), "off": side * (3.4 + rng.randf() * 2.0), "w": 1500.0 + rng.randf() * 700.0, "solid": false, "hit": 0.0})
	for i in range(2, count):
		if absf(curves[i]) > 1.2 and absf(curves[i - 1]) <= 1.2:
			var kind := "arrow_r" if curves[i] > 0.0 else "arrow_l"
			var at := maxi(i - 4, 0)
			sprites[at].append({"kind": kind, "off": -1.35, "w": 380.0, "solid": true, "hit": 0.1})
			sprites[at].append({"kind": kind, "off": 1.35, "w": 380.0, "solid": true, "hit": 0.1})


func _build_map() -> void:
	var total := 0.0
	for c in curves:
		total += c
	var k := TAU / total if absf(total) > 1.0 else 0.01
	var h := 0.0
	var p := Vector2.ZERO
	var pts := PackedVector2Array()
	for i in count:
		pts.append(p)
		h += curves[i] * k
		p += Vector2(cos(h), sin(h))
	for i in count:
		pts[i] -= p * (float(i) / count)
	var mn := pts[0]
	var mx := pts[0]
	for q in pts:
		mn = Vector2(minf(mn.x, q.x), minf(mn.y, q.y))
		mx = Vector2(maxf(mx.x, q.x), maxf(mx.y, q.y))
	var size := maxf(maxf(mx.x - mn.x, mx.y - mn.y), 0.001)
	var pad := Vector2(size - (mx.x - mn.x), size - (mx.y - mn.y)) * 0.5
	for i in count:
		map_pts.append((pts[i] - mn + pad) / size)
