extends baseWall

var isOnFire: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(randi() % 100 < 20):
		setFire(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setFire(onFire: bool) -> void:
	if (onFire):
		isOnFire = true
		$Sprite2D.modulate = Color(1.0, 0.0, 0.0, 1.0)
	else:
		isOnFire = false
		$Sprite2D.modulate = Color(0.435, 1.0, 0.239)


func _on_fire_range_body_entered(body: Node2D) -> void:
	if (body.is_class('CharacterBody2D')):
		setFire(false)
