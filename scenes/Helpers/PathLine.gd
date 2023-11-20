extends Node2D

var path_line_timer:Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	path_line_timer = Timer.new()
	add_child(path_line_timer)
	path_line_timer.autostart = false
	path_line_timer.wait_time = 3
	path_line_timer.connect("timeout", self.clear_path_line)
	
	get_node("TargetMarker").visible=false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_line(points):
	$Line2D.points = points
	path_line_timer.start()
	get_node("TargetMarker").visible=true
	get_node("TargetMarker").position = points[points.size()-1]
	
func clear_path_line():
	path_line_timer.stop()
	$Line2D.clear_points()
	get_node("TargetMarker").visible=false
