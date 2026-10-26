extends Node

var winRoundSound = preload("res://sfx/winRound.wav")
var loseRoundSound = preload("res://sfx/loseRound.wav")

var skinColor = preload("res://player/skinColor.tres")

var buyProgression = [
	preload("res://dices/d2.tscn"),
	preload("res://dices/d4.tscn"),
	preload("res://dices/d6.tscn"),
	preload("res://dices/d8.tscn"),
	preload("res://dices/d10.tscn"),
	preload("res://dices/d12.tscn"),
	preload("res://dices/d20.tscn")
]

var buyDiceNames = [
	"D2",
	"D4",
	"D6",
	"D8",
	"D10",
	"D12",
	"D20"
]

func vec3Rand(value : float):
	return (Vector3(randf_range(-1,1),randf_range(-1,1),randf_range(-1,1))\
	.normalized())*value
