extends Node3D

@rpc("any_peer","call_local")
func setColors(_color): #called by ownr only, for every instance
	print(str(get_parent().name)+" received setColors")
	var transColor = Color(_color.r,_color.g,_color.b,0.3)
	$coloredHead.get_surface_override_material(0).albedo_color = transColor
	$actualTorso.get_surface_override_material(0).albedo_color = _color
	$actualArms.get_surface_override_material(0).albedo_color = _color
