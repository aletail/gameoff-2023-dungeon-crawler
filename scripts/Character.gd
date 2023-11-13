class_name Character extends Node2D

var ID = ""
var State = "Idle"
var Speed = 64
var MoveList:Array = []
var Follower = null
var Body
var Target
var SpriteColor
var CombatCooldown = "Ready"
var CombatGlobalTimer
var Hitpoints = 20

func _ready():
	Body = get_node("CharacterBody2D")
	
	# Setup global combat timer
	CombatGlobalTimer = Timer.new()
	add_child(CombatGlobalTimer)
	CombatGlobalTimer.autostart = false
	CombatGlobalTimer.wait_time = 1
	CombatGlobalTimer.connect("timeout", self.ResetCombatGlobalTimer)
	
func ResetCombatGlobalTimer():
	CombatCooldown = "Ready"
	CombatGlobalTimer.start()
	
func setCombatCooldownState(state):
	if(state=="Cooldown"):
		CombatCooldown = state
		CombatGlobalTimer.start()

func Move(pathlist):
	MoveList = pathlist
	setState("Move")
	
func getPosition():
	return Body.position
	
func setPosition(pos):
	Body.position = pos
	
func setState(s):
	State = s
