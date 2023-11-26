extends Node

class_name Dice

func roll(number_of_dice:int, max_dice_value:int) -> int:
	var value:int = 0
	var rng = RandomNumberGenerator.new()
	for n in range(number_of_dice, 0, -1):
		value += rng.randi_range(1, max_dice_value)
	
	return value
	
