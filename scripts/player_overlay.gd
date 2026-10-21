extends Node2D
## Desenha o Uno do jogador em resolucao total (1280x720) por cima do viewport pixelado.

const SCALE := 4.0
const STRAIGHT_BOOST := 1.06

var rend
var tex := {}


func setup(r) -> void:
	rend = r
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for k in [[0, ""], [-1, "_esq"], [1, "_dir"]]:
		var path := "res://assets/uno_hd%s.png" % k[1]
		if ResourceLoader.exists(path):
			tex[k[0]] = load(path)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if rend == null or rend.race == null or tex.is_empty():
		return
	var st: Dictionary = rend.player_state()
	var t: Texture2D = tex.get(st.which, tex[0])
	var w := float(t.get_width())
	var h := float(t.get_height())
	if st.which == 0:
		w *= STRAIGHT_BOOST
		h *= STRAIGHT_BOOST
	draw_set_transform(st.pos * SCALE, st.rot, Vector2.ONE)
	draw_texture_rect(t, Rect2(-w * 0.5, -h, w, h), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
