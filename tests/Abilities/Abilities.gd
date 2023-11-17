extends Node2D

var map
var character_manager
var camera
var ui

var button_taunt
var TauntCooldownState = "Ready"
var TauntTimer

func _ready():
	ui = get_node("CanvasLayer/Control")
	
	camera = get_node("Camera2D")
	
	map = Map.new(Vector2i(16,16), Vector2i(200,50))
	add_child(map)
	
	character_manager = CharacterManager.new(map)
	add_child(character_manager)

	character_manager.SpawnParty(map.get_spawn_point(), ui)
	
	button_taunt = get_node("CanvasLayer/Control/BoxContainer/HBoxContainer/TauntButton")
	button_taunt.pressed.connect(self.TauntButtonPressed)
	
	TauntTimer = Timer.new()
	add_child(TauntTimer)
	TauntTimer.autostart = false
	TauntTimer.wait_time = 5
	TauntTimer.connect("timeout", self.ResetTauntTimer)
	
func ResetTauntTimer():
	TauntCooldownState = "Ready"
	button_taunt.disabled = false
	
func setTauntCooldownState(state):
	if(state=="Cooldown"):
		TauntCooldownState = state
		TauntTimer.start()
	
func _process(delta):
	if(character_manager.PartyPosition):
		camera.position = camera.position.lerp(character_manager.PartyPosition, delta * 5)
		
	ui.update_health_bar_0(character_manager.Heroes[0].Hitpoints, character_manager.Heroes[0].MaxHitpoints)
	ui.update_health_bar_1(character_manager.Heroes[1].Hitpoints, character_manager.Heroes[1].MaxHitpoints)
	ui.update_health_bar_2(character_manager.Heroes[2].Hitpoints, character_manager.Heroes[2].MaxHitpoints)
	ui.update_health_bar_3(character_manager.Heroes[3].Hitpoints, character_manager.Heroes[3].MaxHitpoints)
	ui.update_health_bar_4(character_manager.Heroes[4].Hitpoints, character_manager.Heroes[4].MaxHitpoints)
			
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var start = Vector2i(character_manager.Heroes[0].getPosition()) / map.cell_size
			var end = Vector2i(get_global_mouse_position()) / map.cell_size
			character_manager.Heroes[0].Move(map.FindPath(start, end))
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			SpawnMonster()
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_2:
			SpawnBossMonster()

func TauntButtonPressed():
	button_taunt.disabled = true
	setTauntCooldownState("Cooldown")
	character_manager.AddTauntDebuff()
	# Clear all monster targets
	# split monster targets to the tank classes
	# Add a debuff to monsters, they can't switch targets until it expires
			
	# Taunt
	# When the taunt ability is used, it will tell the system to have all monsters target the tanks of the party
	# - We could add a range component here, but for simplicity just have it effect all monsters
	# - How long does this effect last? I dont think monsters will switch targets, maybe if range is too far
	
	# Damage
	# When the damage ability is used, it will tell the system to amplify all attacks by a certain percentage.
	# The buff will be on a timer, so the damage will only last so long
	
	# Heal
	# When the heal ability is used, it will tell the system to restore a percentage of health to all party members
	# - How much it restores is to be determined
	# - Maybe it targets those below a certain threshold and prioritizes those first?
	# - Maybe it has X amount of healing to be distributed between all members
			
func SpawnMonster():
	var p = map.get_offscreen_spawn_point(character_manager.PartyPosition)
	if p:
		character_manager.SpawnMonster(p)
	else:
		print("No spawn position found")
		
func SpawnBossMonster():
	var p = map.get_offscreen_spawn_point(character_manager.PartyPosition)
	if p:
		character_manager.SpawnBossMonster(p)
	else:
		print("No spawn position found")

