class_name PartyManager extends Node2D

var PartyMembers:Array = []
var PartySize = 5

func _ready():
	var PartyScene = load("res://Scenes/PartyManager.tscn")
	add_child(PartyScene.instantiate())
	
	for n in PartySize:
		var partymember = Character.new()
		partymember.ID = n
		partymember.position = Vector2i(0, 16 * n)
		#partymember.position = Vector2i(0, 0)
		add_child(partymember)
		PartyMembers.push_back(partymember)
		
	var previous_member = null
	for m in PartyMembers:
		if(previous_member != null):
			previous_member.Follower = m
		previous_member = m

func getLeader():
	if(PartyMembers.size() > 0):
		return PartyMembers[0]
	else:
		return null	
