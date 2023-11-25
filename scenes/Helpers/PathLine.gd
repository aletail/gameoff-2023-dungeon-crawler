extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("TargetMarker").visible=false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_line(points):
	if points:
		$Line2D.points = points
		get_node("TargetMarker").visible=true
		get_node("TargetMarker").position = points[points.size()-1]
	
func clear_path_line():
	$Line2D.clear_points()
	get_node("TargetMarker").visible=false
