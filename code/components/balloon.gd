extends Node3D

var radius = 10
var volume = 4/3 * PI * radius * radius * radius

func displaced_volume() -> float:
	return volume

func mass() -> float:
	return 10
