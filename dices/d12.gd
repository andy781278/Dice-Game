extends dice

func _ready():
	maxValue = 12
	upgradePrice = 20
	values = $body.get_children()
	mesh = $body
	hitPitch = 0.65
	slidePitch = 0.6

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
