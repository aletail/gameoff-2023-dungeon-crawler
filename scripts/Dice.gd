extends Node

class_name Dice

func Roll(NumberOfDice:int, MaxDiceValue:int) -> int:
	var value:int = 0
	var rng = RandomNumberGenerator.new()
	for n in range(NumberOfDice, 0, -1):
		value += rng.randi_range(1, MaxDiceValue)
	
	return value
	
