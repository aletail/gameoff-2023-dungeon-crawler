class_name Tile extends Node2D

var id
var type
var mapx
var mapy

func _ready():
	add_to_group("Objects")
	
func set_type(t):
	type = t
