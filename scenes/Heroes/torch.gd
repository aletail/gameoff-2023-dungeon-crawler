extends PointLight2D

var flicker_timer:Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	flicker_timer = Timer.new()
	add_child(flicker_timer)
	flicker_timer.autostart = true
	flicker_timer.start()
	flicker_timer.wait_time = 0.1
	flicker_timer.connect("timeout", self.torch_flicker)

func torch_flicker():
	var rng = RandomNumberGenerator.new()
	energy = rng.randf_range(0.25, 0.75)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
