class_name Monster extends Node2D

var State = "Idle"
var Speed = 16
var MoveList:Array = []

func _init():
	pass

func _ready():
	var MonsterScene = load("res://Scenes/Characters/Monster.tscn")
	add_child(MonsterScene.instantiate())

func _process(delta):
	if(State=="Move"):
		if(MoveList.size() > 0):
			var point = MoveList[0]

			var t = delta * Speed
			position = position.lerp(point, t)

			var distance_check = point - position

			# Check to see if we reached our destination, if so we pop the point off the list and continue
			if(distance_check.length() < 0.1):
				position = point
				MoveList.pop_front()
		else:
			MoveList.clear()
			State = "Idle"
	elif(State=="Idle"):
		pass

func Move(pathlist):
	MoveList = pathlist
	State = "Move"	
