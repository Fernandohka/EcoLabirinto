extends Node2D

class Wall:
	var x: int
	var y: int
	var hasUpPath: bool = false
	var hasRightPath: bool = false
	var hasDownPath: bool = false
	var hasLeftPath: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func createMap(width: int, height: int, xStart: int, yStart: int, xEnd: int, yEnd: int, primaryWall: baseWall):
	var map: Dictionary = {}
	
	for i in range(width):
		for j in range(height):
			var wall = Wall.new()
			wall.x = i
			wall.y = j
			map[Vector2i(i, j)] = wall
	
	var currentWall: Wall = map.get([Vector2i(xStart, yStart)])
	var remainingWalls: Array[Wall] = []
	
	while true:
		if (currentWall.x > 1 and !remainingWalls.has(Vector2i(xStart - 1, yStart))):
			remainingWalls.append(map.get([Vector2i(xStart - 1, yStart)]))
		
		if (currentWall.x < width and !remainingWalls.has(Vector2i(xStart + 1, yStart))):
			remainingWalls.append(map.get([Vector2i(xStart + 1, yStart)]))
		
		if (currentWall.y > 1 and !remainingWalls.has(Vector2i(xStart, yStart - 1))):
			remainingWalls.append(map.get([Vector2i(xStart, yStart - 1)]))
		
		if (currentWall.y < height and !remainingWalls.has(Vector2i(xStart, yStart + 1))):
			remainingWalls.append(map.get([Vector2i(xStart, yStart + 1)]))
		
		var availablePaths: Array[Wall] = []
		
		if (map.has(Vector2i(currentWall.x + 1, currentWall.y))):
			availablePaths.append(map.has(Vector2i(currentWall.x + 1, currentWall.y)))
		
		if (map.has(Vector2i(currentWall.x - 1, currentWall.y))):
			availablePaths.append(map.has(Vector2i(currentWall.x - 1, currentWall.y)))
		
		if (map.has(Vector2i(currentWall.x, currentWall.y + 1))):
			availablePaths.append(map.has(Vector2i(currentWall.x, currentWall.y + 1)))
		
		if (map.has(Vector2i(currentWall.x, currentWall.y - 1))):
			availablePaths.append(map.has(Vector2i(currentWall.x, currentWall.y - 1)))
		
		if (!availablePaths.is_empty()):
			var path: Wall = availablePaths.pick_random()
			map.get(Vector2i(currentWall.x, currentWall.y))
			
		
		
		
		
		
		
		
		
		
		
		
		
		
		
