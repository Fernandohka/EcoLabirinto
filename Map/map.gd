extends Node2D

class Wall:
	var x: int
	var y: int
	var hasUpPath: bool = false
	var hasRightPath: bool = false
	var hasDownPath: bool = false
	var hasLeftPath: bool = false
	var wasPassad: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func createMap(width: int, height: int, xStart: int, yStart: int, xEnd: int, yEnd: int, primaryWall: baseWall):
	var map = Array([], TYPE_OBJECT, "RefCounted", Wall)
	
	for i in range(width):
		for j in range(height):
			pass
