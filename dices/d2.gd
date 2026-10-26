extends dice

func _ready():
	maxValue = 2
	upgradePrice = 4
	values = $body.get_children()
	mesh = $mesh
	hitPitch = 1
	slidePitch = 1.5

func _on_body_entered(body):
	super(body)
func _on_mouse_entered():
	super()
func _on_mouse_exited():
	super()
func _on_arrow_mouse_entered():
	super()
func _on_arrow_mouse_exited():
	super()
