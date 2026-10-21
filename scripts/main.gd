extends Node
## Monta a cena por codigo: viewport pixelado 320x180 + HUD em 1280x720.

const RaceScript = preload("res://scripts/race.gd")
const RendererScript = preload("res://scripts/road_renderer.gd")
const OverlayScript = preload("res://scripts/player_overlay.gd")
const HudScript = preload("res://scripts/hud.gd")

var race
var hud


func _ready() -> void:
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.stretch_shrink = 4
	cont.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(cont)
	cont.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vp := SubViewport.new()
	vp.size = Vector2i(320, 180)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	cont.add_child(vp)

	race = RaceScript.new()
	add_child(race)

	var rend := RendererScript.new()
	vp.add_child(rend)
	rend.setup(race)

	var pl_layer := CanvasLayer.new()
	pl_layer.layer = 0
	add_child(pl_layer)
	var ov := OverlayScript.new()
	pl_layer.add_child(ov)
	ov.setup(rend)

	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	hud = HudScript.new()
	layer.add_child(hud)
	hud.setup(race, self)


func start_game() -> void:
	race.start_race()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var st: int = race.state
	match key.keycode:
		KEY_ESCAPE:
			if st == RaceScript.ST_COUNTDOWN or st == RaceScript.ST_RACING:
				race.paused = not race.paused
		KEY_R:
			if st != RaceScript.ST_MENU:
				race.start_race()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if st == RaceScript.ST_MENU or st == RaceScript.ST_FINISHED:
				race.start_race()
