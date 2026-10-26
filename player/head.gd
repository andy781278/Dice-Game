extends MeshInstance3D

@export_range(0, 10, 0.01) var sensitivity : float = 1.5

@onready var main = get_parent().get_parent().get_parent()

var lookAt
var lookAtDice = false

func _unhandled_input(event: InputEvent) -> void:
	if !get_parent().is_multiplayer_authority():
		return
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x / 1000 * sensitivity
		rotation.z -= event.relative.y / 1000 * sensitivity
		rotation.z = clamp(rotation.z, PI/-2, PI/2)
		get_parent().get_node("bodyParts/coloredHead").rotation = rotation

func _physics_process(_delta):
	if !get_parent().is_multiplayer_authority() || get_parent().dead:
		return
	if $cam/ray.is_colliding():
		var collider = $cam/ray.get_collider()
		
		if collider==null || !is_instance_valid(collider) || !collider.is_inside_tree():
			return
		
		if collider.is_in_group("dice") && collider.get_parent().get_parent().is_multiplayer_authority():
			collider.highlight()
		elif lookAt != null && lookAt.is_in_group("dice") && collider != lookAt && lookAt.get_parent().get_parent().is_multiplayer_authority():
			lookAt.unhighlight()
			
		if collider.is_in_group("player") && get_parent().yourTurn&&!collider.get_parent().dead && !main.battleReady:
			collider.get_parent().highlight()
		elif lookAt != null && lookAt.is_in_group("player") && collider != lookAt:
			lookAt.get_parent().unhighlight()
		
		if collider.is_in_group("upSign") && collider.get_parent().get_parent().is_multiplayer_authority():
			collider.get_parent().get_parent().highlightup()
		elif lookAt != null && lookAt.is_in_group("upSign") && collider != lookAt && lookAt.get_parent().get_parent().is_multiplayer_authority():
			lookAt.get_parent().get_parent().unhighlightup()
		
		if collider.is_in_group("downSign") && collider.get_parent().get_parent().is_multiplayer_authority():
			collider.get_parent().get_parent().highlightdown()
		elif lookAt != null && lookAt.is_in_group("downSign") && collider != lookAt && lookAt.get_parent().get_parent().is_multiplayer_authority():
			lookAt.get_parent().get_parent().unhighlightdown()
		
		if collider.name == "arrow" && collider.get_parent().get_parent().get_parent().get_parent().is_multiplayer_authority():
			collider.get_parent().get_parent().mouseOnArrow = true
		elif lookAt != null && lookAt.name == "arrow" && collider != lookAt && lookAt.get_parent().get_parent().get_parent().get_parent().is_multiplayer_authority():
			lookAt.get_parent().get_parent().mouseOnArrow = false
		
		lookAt = collider
		
	else:
		if lookAt != null && lookAt.is_in_group("dice"):
			lookAt.unhighlight()
		if lookAt != null && lookAt.is_in_group("player"):
			lookAt.get_parent().unhighlight()
		lookAt = null
