extends Control

var boss_health_bar
var horde_health_bar
var healthBar0
var healthBar1
var healthBar2
var healthBar3
var healthBar4

var game_over_panel
var game_over_panel_defeat
var taunt_timer_label
var taunt_timer_progress
var damage_timer_label
var damage_timer_progress
var heal_timer_label
var heal_timer_progress

var chat_bubble_object
var active_chat_bubble = false
var chat_bubble_timer:Timer

func _ready():
	game_over_panel = get_node("GameOverPanel")
	game_over_panel.visible = false
	
	game_over_panel_defeat = get_node("GameOverPanel_Defeat")
	game_over_panel_defeat.visible = false
	
	boss_health_bar = get_node("BossHealthBarContainer")
	boss_health_bar.visible = false
	
	horde_health_bar = get_node("HordeHealthBarContainer")
	horde_health_bar.visible = false
	
	healthBar0 = get_node("BoxContainer/HeroInformation/Hero_0/Healthbar")
	healthBar1 = get_node("BoxContainer/HeroInformation/Hero_1/Healthbar")
	healthBar2 = get_node("BoxContainer/HeroInformation/Hero_2/Healthbar")
	healthBar3 = get_node("BoxContainer/HeroInformation/Hero_3/Healthbar")
	healthBar4 = get_node("BoxContainer/HeroInformation/Hero_4/Healthbar")
	
	taunt_timer_progress = get_node("BoxContainer/HBoxContainer/TauntButtonContainer/CooldownProgress")
	damage_timer_progress = get_node("BoxContainer/HBoxContainer/DamageButtonContainer/CooldownProgress")
	heal_timer_progress = get_node("BoxContainer/HBoxContainer/HealButtonContainer/CooldownProgress")
	
	chat_bubble_timer = Timer.new()
	add_child(chat_bubble_timer)
	chat_bubble_timer.autostart = false
	chat_bubble_timer.wait_time = 5
	chat_bubble_timer.connect("timeout", self.hide_chat_bubble)
	
func update_health_bar_boss (curHp, maxHp, color):
	boss_health_bar.get_node("BossHealthBar").value = (curHp / float(maxHp)) * 100.0
	boss_health_bar.get_node("BossHealthBar").modulate = color
func update_health_bar_horde (curHp, maxHp, color):
	horde_health_bar.get_node("HealthBar").value = (curHp / float(maxHp)) * 100.0
	horde_health_bar.get_node("HealthBar").modulate = color
func update_health_bar_0 (curHp, maxHp, color):
	healthBar0.value = (curHp / float(maxHp)) * 100.0
	healthBar0.set_tint_progress(color)
func update_health_bar_1 (curHp, maxHp, color):
	healthBar1.value = (curHp / float(maxHp)) * 100.0
	healthBar1.set_tint_progress(color)
func update_health_bar_2 (curHp, maxHp, color):
	healthBar2.value = (curHp / float(maxHp)) * 100.0
	healthBar2.set_tint_progress(color)
func update_health_bar_3 (curHp, maxHp, color):
	healthBar3.value = (curHp / float(maxHp)) * 100.0
	healthBar3.set_tint_progress(color)
func update_health_bar_4(curHp, maxHp, color):
	healthBar4.value = (curHp / float(maxHp)) * 100.0
	healthBar4.set_tint_progress(color)
	
func update_taunt_timer(time_left, maxvalue):
	taunt_timer_progress.value = maxvalue - snapped(time_left, 0)
func update_damage_timer(time_left, maxvalue):
	damage_timer_progress.value = maxvalue - snapped(time_left, 0)
func update_heal_timer(time_left, maxvalue):
	heal_timer_progress.value = maxvalue - snapped(time_left, 0)
	
func _process(delta):
	# If active chat bubble, update position with its target object
	if active_chat_bubble:
		get_node("ChatBubbleContainer").position = chat_bubble_object.get_viewport_transform() * (chat_bubble_object.get_global_transform() * chat_bubble_object.getPosition())
	
func hide_chat_bubble():
	get_node("ChatBubbleContainer").visible = false
	get_node("ChatBubbleContainer/RichTextLabel").text = ""
	chat_bubble_timer.stop()

# Returns random chatter based on even passed in		
func show_chat_bubble(event:String, object):
	chat_bubble_timer.start()
	active_chat_bubble = true
	chat_bubble_object = object
	get_node("ChatBubbleContainer").visible = true
	var rng = RandomNumberGenerator.new()
	randomize()
	var game_start_chats = [
		"I Hope you packed your sleeping bags",
		"Lets proceed with caution...",
		"Stick together...",
		"Anyone been here before?"
	]
	var boss_battle_chats = [
		"Did you hear that? sounds large...",
		"I hear something big...",
		"The ground is shaking...",
		"I have a bad feeling about this..."
	]
	var horde_battle_chats = [
		"Did you hear that?",
		"I heard something this way...",
		"Something smells rotten here...",
		"The air is heavy here..."
	]
	var before_battle_chats = [
		"Here they come!",
		"So it begins!",
		"Ready yourselves!",
		"Arm yourselves!",
		"To arms!"
	]
	var after_battle_chats = [
		"That was a good fight!",
		"Form up!",
		"Lets keep moving!",
		"I got twelve that time..."
	]
	var enter_cave_chats = [
		"Let's see where this goes...",
		"Whats down here..."
	]
	if event == "Game Start":
		get_node("ChatBubbleContainer/RichTextLabel").text = game_start_chats[rng.randi_range(0, game_start_chats.size()-1)]
	elif event == "Boss Battle":
		get_node("ChatBubbleContainer/RichTextLabel").text = boss_battle_chats[rng.randi_range(0, boss_battle_chats.size()-1)]
	elif event == "Horde Battle":
		get_node("ChatBubbleContainer/RichTextLabel").text = horde_battle_chats[rng.randi_range(0, horde_battle_chats.size()-1)]
	elif event == "Before Battle":
		get_node("ChatBubbleContainer/RichTextLabel").text = before_battle_chats[rng.randi_range(0, before_battle_chats.size()-1)]
	elif event == "After Battle":
		get_node("ChatBubbleContainer/RichTextLabel").text = after_battle_chats[rng.randi_range(0, after_battle_chats.size()-1)]
	elif event == "Enter Cave":
		get_node("ChatBubbleContainer/RichTextLabel").text = enter_cave_chats[rng.randi_range(0, enter_cave_chats.size()-1)]
