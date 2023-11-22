extends Control

var boss_health_bar
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
	
	taunt_timer_progress = get_node("BoxContainer/HBoxContainer/TauntButtonContainer/CooldownProgress")
	damage_timer_progress = get_node("BoxContainer/HBoxContainer/DamageButtonContainer/CooldownProgress")
	heal_timer_progress = get_node("BoxContainer/HBoxContainer/HealButtonContainer/CooldownProgress")
	
func update_health_bar_boss (curHp, maxHp, color):
	boss_health_bar.get_node("BossHealthBar").value = (curHp / float(maxHp)) * 100.0
	boss_health_bar.get_node("BossHealthBar").modulate = color
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
	
