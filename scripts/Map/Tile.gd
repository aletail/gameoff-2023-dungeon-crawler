class_name Tile extends Node2D

var id:int
var type:String
var mapx:int
var mapy:int
var cave_id:int

func _ready():
	add_to_group("Objects")
	#get_node("Label").text = str(cave_id)
	
func set_type(t:String):
	type = t
	
func make_ground():
	type = "ground"
	get_parent().make_ground(Vector2(mapx, mapy))
	get_node("StaticBody2D/CollisionShape2D").disabled = true
	#get_node("StaticBody2D/Sprite2D").modulate = Color(131/255.0, 121/255.0, 110/255.0)
