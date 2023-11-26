class_name Tile extends Node2D

var id:int
var type:String
var mapx:int
var mapy:int
var cave_id:int

func _ready():
	add_to_group("Objects")
	
func set_type(t:String):
	type = t
	
func make_ground():
	get_node("TileBreakSound").play()
	get_node("TileBreakParticles").set_emitting(true)
	type = "ground"
	get_parent().make_ground(Vector2(mapx, mapy))
	get_node("StaticBody2D/CollisionShape2D").disabled = true
	get_node("StaticBody2D/LightOccluder2D").set_occluder_light_mask(2)
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	get_node("StaticBody2D/AnimatedSprite2D").set_frame(rng.randi_range(1, 8))
