extends dice

func _ready():
	maxValue = 20
	upgradePrice = 999999999
	values = $body.get_children()
	mesh = $body
	hitPitch = 0.2
	slidePitch = 0.5

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
