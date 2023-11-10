class_name Character extends CharacterBody2D

var ID = ""
var State = "Idle"
var Speed = 64
var MoveList:Array = []
var Follower = null
var Body

func _ready():
	var CharacterScene = load("res://Scenes/Characters/Character.tscn")
	add_child(CharacterScene.instantiate())
	
	get_node("Node2D/CharacterBody2D/Label").text = str(ID)
	
	Body = get_node("Node2D/CharacterBody2D")

func _physics_process(delta):
	if(State=="Move"):
		if(MoveList.size() > 0):
			var point = MoveList[0]
			Body.velocity = Body.position.direction_to(point) * Speed
			var collision = Body.move_and_collide(Body.velocity * delta)
			
			# If a collision is detected, check what we collided with
			if collision:
				if(collision.get_collider().name == "MonsterBody2D"):
					# TEMP - This will be updated to set combat states
					collision.get_collider().get_parent().State = "Dead"
				else:
					# Slide
					Body.velocity = Body.velocity.slide(collision.get_normal())
			
			# Check distance to our point, if less then one - remove point from list and update any followers
			var d = Body.position.distance_to(point);
			if d < 1:
				Body.position = point
				Body.velocity = Vector2.ZERO
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
	elif(State=="Idle"):
		pass
	elif(State=="Dead"):
		get_node("/root").visible = false

func Move(pathlist):
	MoveList = pathlist
	State = "Move"	
	
func getPosition():
	return Body.position
