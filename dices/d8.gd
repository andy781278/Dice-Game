extends dice

func _ready():
	maxValue = 8
	upgradePrice = 10
	values = $body.get_children()
	mesh = $body
	hitPitch = 0.9
	slidePitch = 0.8

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
