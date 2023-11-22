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
	type = "ground"
	get_parent().make_ground(Vector2(mapx, mapy))
	get_node("StaticBody2D/CollisionShape2D").disabled = true
	get_node("StaticBody2D/Ground").visible = true
	get_node("StaticBody2D/Wall").visible = false
