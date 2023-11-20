extends Control

var boss_health_bar
var healthBar0
var healthBar1
var healthBar2
var healthBar3
var healthBar4
var race_class_text_0
var race_class_text_1
var race_class_text_2
var race_class_text_3
var race_class_text_4
var game_over_panel
var game_over_panel_defeat
var taunt_timer_label
var damage_timer_label
var heal_timer_label

func _ready():
	game_over_panel = get_node("GameOverPanel")
	game_over_panel.visible = false
	
	game_over_panel_defeat = get_node("GameOverPanel_Defeat")
	game_over_panel_defeat.visible = false
	
	boss_health_bar = get_node("BossHealthBarContainer")
	boss_health_bar.visible = false
	
	healthBar0 = get_node("BoxContainer/HeroInformation/Hero_0/Healthbar")
	healthBar1 = get_node("BoxContainer/HeroInformation/Hero_1/Healthbar")
	healthBar2 = get_node("BoxContainer/HeroInformation/Hero_2/Healthbar")
	healthBar3 = get_node("BoxContainer/HeroInformation/Hero_3/Healthbar")
	healthBar4 = get_node("BoxContainer/HeroInformation/Hero_4/Healthbar")
	
	race_class_text_0 = get_node("BoxContainer/HeroInformation/Hero_0/RaceClass")
	race_class_text_1 = get_node("BoxContainer/HeroInformation/Hero_1/RaceClass")
	race_class_text_2 = get_node("BoxContainer/HeroInformation/Hero_2/RaceClass")
	race_class_text_3 = get_node("BoxContainer/HeroInformation/Hero_3/RaceClass")
	race_class_text_4 = get_node("BoxContainer/HeroInformation/Hero_4/RaceClass")
	
	taunt_timer_label = get_node("BoxContainer/HBoxContainer/TauntButton/Cooldown")
	damage_timer_label = get_node("BoxContainer/HBoxContainer/DamageButton/Cooldown")
	heal_timer_label = get_node("BoxContainer/HBoxContainer/HealButton/Cooldown")
	
func update_health_bar_boss (curHp, maxHp, color):
	boss_health_bar.get_node("BossHealthBar").value = (curHp / float(maxHp)) * 100.0
	boss_health_bar.get_node("BossHealthBar").modulate = color
func update_health_bar_0 (curHp, maxHp, color):
	healthBar0.value = (curHp / float(maxHp)) * 100.0
	healthBar0.modulate = color
func update_health_bar_1 (curHp, maxHp, color):
	healthBar1.value = (curHp / float(maxHp)) * 100.0
	healthBar1.modulate = color
func update_health_bar_2 (curHp, maxHp, color):
	healthBar2.value = (curHp / float(maxHp)) * 100.0
	healthBar2.modulate = color
func update_health_bar_3 (curHp, maxHp, color):
	healthBar3.value = (curHp / float(maxHp)) * 100.0
	healthBar3.modulate = color
func update_health_bar_4(curHp, maxHp, color):
	healthBar4.value = (curHp / float(maxHp)) * 100.0
	healthBar4.modulate = color
	
func update_race_class_0(text):
	race_class_text_0.text = text
func update_race_class_1(text):
	race_class_text_1.text = text
func update_race_class_2(text):
	race_class_text_2.text = text
func update_race_class_3(text):
	race_class_text_3.text = text
func update_race_class_4(text):
	race_class_text_4.text = text
	
func update_taunt_timer(time_left):
	taunt_timer_label.text = str(snapped(time_left, 0))
func update_damage_timer(time_left):
	damage_timer_label.text = str(snapped(time_left, 0))
func update_heal_timer(time_left):
	heal_timer_label.text = str(snapped(time_left, 0))
	
