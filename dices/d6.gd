extends dice

func _ready():
	maxValue = 6
	upgradePrice = 8
	values = $body.get_children()
	mesh = $body
	hitPitch = 1
	slidePitch = 1

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
