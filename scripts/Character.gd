class_name Character extends Node2D

var ID = ""
var State = "Idle"
var Speed = 16
var MoveList:Array = []
var Follower = null

func _ready():
	var CharacterScene = load("res://Scenes/Characters/Character.tscn")
	add_child(CharacterScene.instantiate())
	
	get_node("character/CharacterBody2D/Label").text = str(ID)

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
				# If we have a follower, send point to them and trigger a move state
				if(Follower):
					# Checking for greater then one, will stop this before it reaches the character it is following
					if(MoveList.size() > 1):
						MoveList.pop_front()
						Follower.MoveList.push_back(point)
						Follower.State = "Move"
				else:
					MoveList.pop_front()
		else:
			MoveList.clear()
			State = "Idle"

func Move(pathlist):
	MoveList = pathlist
	State = "Move"	
