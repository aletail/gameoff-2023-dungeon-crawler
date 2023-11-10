class_name Monster extends Node2D

var State = "Idle"
var Speed = 64
var MoveList:Array = []
var Body

func _init():
	pass

func _ready():
	Body = get_node("MonsterBody2D")

func _physics_process(delta):
	if(State=="Move"):
		if(MoveList.size() > 0):
			var point = MoveList[0]
			Body.look_at(point)
			Body.velocity = Body.position.direction_to(point) * Speed
			var collision = Body.move_and_collide(Body.velocity * delta)
			if collision:
				#print("I collided with ", collision.get_collider().name)
				if(collision.get_collider().name == "CharacterBody2D"):
					# Collision
					pass
				else:
					Body.velocity = Body.velocity.slide(collision.get_normal())
			
			var d = Body.position.distance_to(point);
			if d < 10:
				Body.velocity = Vector2.ZERO
				MoveList.pop_front()
		else:
			MoveList.clear()
			State = "Idle"
	elif(State=="Dead"):
		visible = false
	
func Move(pathlist):
	MoveList = pathlist
	State = "Move"	
	
func setPosition(pos):
	Body.position = pos
	
func getPosition():
	return Body.position
	
