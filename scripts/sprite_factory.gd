extends RefCounted
## Gera todos os sprites pixel art proceduralmente (arte original, sem assets externos).


static func _new_img(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), c)


## Carro visto de tras (40x32). Com `rack` = true tem bagageiro e escada de aluminio (Uno do jogador).
static func make_car(body: Color, rack: bool) -> ImageTexture:
	var img := _new_img(40, 32)
	var dark := Color("#14141a")
	var shade := body.darkened(0.3)
	var light := body.lightened(0.35)
	var glass := Color("#1f2c3d")
	var alu := Color("#e0e8f0")
	var alu_d := Color("#8d99a6")
	_r(img, 2, 30, 36, 2, Color(0, 0, 0, 0.45))
	# rodas
	_r(img, 3, 23, 7, 8, dark)
	_r(img, 30, 23, 7, 8, dark)
	_r(img, 5, 25, 3, 2, Color("#59606c"))
	_r(img, 32, 25, 3, 2, Color("#59606c"))
	# cabine trapezoidal
	for y in range(3, 14):
		var t := float(y - 3) / 10.0
		var l := 9 - int(t * 3.0)
		_r(img, l - 1, y, 40 - 2 * (l - 1), 1, dark)
		_r(img, l, y, 40 - 2 * l, 1, body if y > 3 else light)
	for y in range(5, 13):
		var t := float(y - 5) / 7.0
		var l := 11 - int(t * 3.0)
		_r(img, l, y, 40 - 2 * l, 1, glass)
	_r(img, 12, 6, 8, 1, Color(0.5, 0.65, 0.8))
	_r(img, 11, 7, 4, 1, Color(0.5, 0.65, 0.8))
	# carroceria
	_r(img, 3, 13, 34, 15, dark)
	_r(img, 4, 14, 32, 13, body)
	_r(img, 4, 14, 32, 1, light)
	_r(img, 4, 23, 32, 4, shade)
	_r(img, 4, 19, 32, 1, shade)
	# lanternas
	_r(img, 4, 15, 8, 5, dark)
	_r(img, 5, 16, 6, 3, Color("#e8222a"))
	_r(img, 5, 16, 6, 1, Color("#ffb090"))
	_r(img, 28, 15, 8, 5, dark)
	_r(img, 29, 16, 6, 3, Color("#e8222a"))
	_r(img, 29, 16, 6, 1, Color("#ffb090"))
	# para-choque e placa
	_r(img, 4, 25, 32, 4, Color("#2a2a32"))
	_r(img, 4, 25, 32, 1, Color("#4a4a56"))
	_r(img, 15, 20, 10, 5, dark)
	_r(img, 16, 21, 8, 3, Color("#f2f2e0"))
	_r(img, 17, 22, 6, 1, Color("#7a7a88"))
	if rack:
		_r(img, 8, 3, 2, 4, alu_d)
		_r(img, 30, 3, 2, 4, alu_d)
		_r(img, 5, 0, 30, 1, alu)
		_r(img, 5, 3, 30, 1, alu)
		for rx in range(7, 34, 4):
			_r(img, rx, 0, 1, 4, alu_d)
	return ImageTexture.create_from_image(img)


## Fiat Uno Mille branco de firma visto de tras (64x48), com bagageiro e escada laranja/aluminio.
static func make_uno(variant: String = "") -> Texture2D:
	var path := "res://assets/uno_game%s.png" % variant
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded
	return make_uno_procedural()


static func make_uno_procedural() -> ImageTexture:
	var img := _new_img(64, 48)
	var outline := Color("#16161c")
	var white := Color("#f4f4f0")
	var white_s := Color("#c9ccd2")
	var white_d := Color("#9ea3ae")
	var glass := Color("#1b2736")
	var glass_h := Color("#4d6783")
	var orange := Color("#ee8a1e")
	var orange_d := Color("#a85a10")
	var alu := Color("#dfe6ee")
	var alu_d := Color("#8d99a6")
	var red := Color("#d3202a")
	var red_l := Color("#ff6a5a")
	var amber := Color("#ff9a1e")
	# sombra
	_r(img, 3, 46, 58, 2, Color(0, 0, 0, 0.45))
	# escada (dois trilhos laranja + degraus de aluminio)
	# escada deitada no sentido do carro (frente-tras): vista de tras, dois trilhos
	# que convergem para a frente, com degraus em perspectiva entre eles
	for y in range(1, 13):
		var t := float(y - 1) / 11.0
		var lx := 21 - int(t * 5.0)
		var rx2 := 41 + int(t * 5.0)
		_r(img, lx, y, 3, 1, orange)
		_r(img, lx, y, 1, 1, orange_d)
		_r(img, rx2, y, 3, 1, orange)
		_r(img, rx2 + 2, y, 1, 1, orange_d)
	for y in [3, 5, 7, 9, 11]:
		var t2 := float(y - 1) / 11.0
		var l2 := 24 - int(t2 * 5.0)
		var r2 := 41 + int(t2 * 5.0)
		_r(img, l2, y, r2 - l2, 1, alu)
	# bagageiro: barras transversais pretas sobre o teto
	_r(img, 11, 10, 42, 2, outline)
	_r(img, 14, 12, 3, 2, outline)
	_r(img, 47, 12, 3, 2, outline)
	# cabine trapezoidal
	for y in range(11, 26):
		var t := float(y - 11) / 14.0
		var l := 13 - int(t * 4.0)
		var r := 51 + int(t * 4.0)
		_r(img, l - 1, y, r - l + 3, 1, outline)
		_r(img, l, y, r - l + 1, 1, white if y < 24 else white_s)
	# vidro traseiro
	for y in range(13, 24):
		var t := float(y - 13) / 10.0
		var l := 16 - int(t * 3.0)
		var r := 48 + int(t * 3.0)
		_r(img, l, y, r - l + 1, 1, glass)
	_r(img, 18, 14, 10, 1, glass_h)
	_r(img, 17, 15, 6, 1, glass_h)
	_r(img, 26, 21, 12, 1, Color("#2c3d52"))
	# carroceria
	_r(img, 4, 25, 56, 15, outline)
	_r(img, 5, 25, 54, 14, white)
	_r(img, 5, 34, 54, 5, white_s)
	_r(img, 5, 38, 54, 1, white_d)
	_r(img, 5, 25, 54, 1, white_s)
	# friso preto lateral / abertura do porta-malas
	_r(img, 14, 29, 36, 1, white_d)
	# lanternas
	_r(img, 5, 26, 10, 9, outline)
	_r(img, 6, 27, 8, 7, red)
	_r(img, 6, 27, 8, 2, amber)
	_r(img, 6, 30, 3, 3, red_l)
	_r(img, 49, 26, 10, 9, outline)
	_r(img, 50, 27, 8, 7, red)
	_r(img, 50, 27, 8, 2, amber)
	_r(img, 55, 30, 3, 3, red_l)
	# emblema e macaneta
	_r(img, 30, 27, 4, 3, red)
	_r(img, 31, 28, 2, 1, white)
	_r(img, 26, 29, 12, 1, white_d)
	# para-choque preto
	_r(img, 3, 38, 58, 7, outline)
	_r(img, 4, 38, 56, 1, Color("#3a3a44"))
	_r(img, 5, 40, 54, 3, Color("#25252d"))
	# placa
	_r(img, 25, 33, 14, 7, outline)
	_r(img, 26, 34, 12, 5, Color("#e4e6e8"))
	_r(img, 27, 36, 10, 1, Color("#9aa0aa"))
	# rodas
	_r(img, 6, 41, 10, 6, outline)
	_r(img, 48, 41, 10, 6, outline)
	_r(img, 9, 43, 4, 3, alu_d)
	_r(img, 51, 43, 4, 3, alu_d)
	_r(img, 10, 44, 2, 1, alu)
	_r(img, 52, 44, 2, 1, alu)
	return ImageTexture.create_from_image(img)


static func make_palm() -> ImageTexture:
	var img := _new_img(32, 48)
	var trunk := Color("#7a4a22")
	var trunk_l := Color("#b07a40")
	var trunk_d := Color("#4e2d14")
	for y in range(14, 48):
		var xo := 14 + int(sin(y * 0.13) * 2.0)
		_r(img, xo - 1, y, 5, 1, trunk_d)
		_r(img, xo, y, 3, 1, trunk)
		_r(img, xo, y, 1, 1, trunk_l)
		if y % 4 == 0:
			_r(img, xo, y, 3, 1, trunk_d)
	var cx := 15
	var cy := 12
	# folhas: arcos caindo para os lados (escuro por baixo, claro por cima)
	for dir in [-1, 1]:
		for k in [0.0, 0.45, 0.9, 1.35]:
			var flen: float = 13.0 - k * 2.0
			for s in range(0, int(flen) + 1):
				var px: int = cx + dir * s
				var py: int = cy - int(sin(float(s) / flen * PI * 0.5) * (7.0 - k * 2.0)) + int(pow(float(s) / flen, 2.0) * (6.0 + k * 7.0))
				_r(img, px, py + 1, 1, 2, Color("#16602a"))
				_r(img, px, py, 1, 2, Color("#2a9440"))
				_r(img, px, py - 1, 1, 1, Color("#5ed46a"))
	for s in range(-3, 4):
		_r(img, cx + s, cy - 7 + abs(s), 1, 3, Color("#2a9440"))
	_r(img, cx - 2, cy - 1, 2, 2, Color("#5a3416"))
	_r(img, cx + 1, cy - 1, 2, 2, Color("#5a3416"))
	return ImageTexture.create_from_image(img)


static func make_arrow(right: bool) -> ImageTexture:
	var img := _new_img(16, 24)
	_r(img, 7, 12, 2, 12, Color("#555566"))
	_r(img, 0, 0, 16, 12, Color("#14141a"))
	_r(img, 1, 1, 14, 10, Color("#f5c400"))
	_r(img, 3, 5, 10, 2, Color("#14141a"))
	for k in 4:
		var x := 13 - k if right else 2 + k
		_r(img, x, 6 - k, 1, 2 * k + 1, Color("#14141a"))
	return ImageTexture.create_from_image(img)


static func make_building(w: int, h: int, color: Color) -> ImageTexture:
	var img := _new_img(w, h)
	_r(img, 0, 0, w, h, color.darkened(0.5))
	_r(img, 1, 2, w - 2, h - 2, color)
	_r(img, w - 4, 2, 3, h - 2, color.darkened(0.2))
	_r(img, 1, 2, 2, h - 2, color.lightened(0.15))
	_r(img, 0, 0, w, 3, color.darkened(0.3))
	_r(img, w / 2 - 3, 0, 6, 1, color.lightened(0.2))
	for wy in range(6, h - 10, 6):
		_r(img, 2, wy + 3, w - 4, 1, color.darkened(0.2))
		for wx in range(4, w - 6, 6):
			var v := (wx * 7 + wy * 13) % 3
			var wc := Color("#ffe58a") if v == 0 else Color("#3f5f8c")
			_r(img, wx - 1, wy - 1, 4, 4, color.darkened(0.45))
			_r(img, wx, wy, 2, 2, wc)
			_r(img, wx, wy, 1, 1, wc.lightened(0.3))
	_r(img, w / 2 - 3, h - 8, 6, 8, Color("#2a1c14"))
	_r(img, w / 2 - 2, h - 7, 4, 2, Color("#6a8aaa"))
	return ImageTexture.create_from_image(img)
