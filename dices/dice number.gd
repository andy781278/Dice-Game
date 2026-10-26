extends Label3D

func _process(_delta):
	$copy.text = text

@rpc("call_local")
func shine():
	$animations.current_animation = "boom"
	$animations.play()

@rpc("call_local")
func superShine():
	$animations.current_animation = "crit"
	$animations.play()
