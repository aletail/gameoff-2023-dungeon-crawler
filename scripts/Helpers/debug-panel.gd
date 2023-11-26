extends Label

var debug_list:Dictionary
var debug_string:String

func _process(delta: float) -> void:
	set_text("FPS %d" % Engine.get_frames_per_second())
	
	debug_string = ""
	for data in debug_list:
		debug_string+= data + ": " + debug_list[data] + "\n"
	get_node("DebugInfo").set_text(str(debug_string))
	
func add_debug_text(key:String, value:String):
	debug_list[key] = value
