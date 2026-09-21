extends CharacterBody2D

const SPEED = 400.0

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("A", "D", "W", "S");
	
	if direction:
		velocity = direction * SPEED
		if(Input.is_action_pressed("Shift")):
			velocity *= 3
	else:
		velocity = Vector2.ZERO;
	
	move_and_slide()
	
	#for i in get_slide_collision_count():
		#var collision = get_slide_collision(i)
		#var objeto_colidido = collision.get_collider()
		#
		#if (objeto_colidido.has_method("setFire") and objeto_colidido.isOnFire == true):
			#objeto_colidido.setFire(false)
