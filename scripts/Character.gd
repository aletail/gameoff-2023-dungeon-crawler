class_name Character extends Node2D

var id:int
var race:String
var class_type:String
var state:String = "Idle"
var speed:int = 64
var attack_speed:int = 1
var hitpoints:int = 30
var max_hitpoints:int = 30

var move_list:Array = []
var follower = null
var character_body:CharacterBody2D
var target = null
var target_object = null
var combat_cooldown:String = "Ready"
var combat_global_timer:Timer

var sprite_color

func _ready():
	character_body = get_node("CharacterBody2D")
	
	# Setup global combat timer
	combat_global_timer = Timer.new()
	add_child(combat_global_timer)
	combat_global_timer.autostart = false
	combat_global_timer.wait_time = attack_speed
	combat_global_timer.connect("timeout", self.reset_combat_global_timer)

# Reset the combat timer
func reset_combat_global_timer():
	combat_cooldown = "Ready"
	combat_global_timer.start()

# Update the combat cooldown state, starts the timer
func set_combat_cooldown_state(state:String):
	if(state=="Cooldown"):
		combat_cooldown = state
		combat_global_timer.start()

# Sets the characters move list and sets the state to "Move"
func move(pathlist:Array):
	move_list = pathlist
	set_state("Move")
	
# Get the position of CharacterBody2D
func getPosition():
	return character_body.position

# Sets the position of CharacterBody2D
func setPosition(pos:Vector2):
	character_body.position = pos

# Sets the state of the character
func set_state(s:String):
	state = s

# Updates the sprite color
func update_color(color:Color):
	get_node("CharacterBody2D/Sprite2D").modulate = color
	sprite_color = color
