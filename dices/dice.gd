extends RigidBody3D
class_name dice

var maxValue = 2
var upgradePrice = 4
var values
var mesh
var hitPitch
var slidePitch
var mouseOnArrow
@onready var main = get_parent().get_parent().get_parent().get_parent()
@onready var ownr = get_parent().get_parent()

var thrown = false

var checkingForMovement = false
var timer = 0

var seriousCounting = false

@rpc("any_peer","call_local")
func setColors(_color): #called by ownr only, for every instance
	mesh.get_surface_override_material(0).albedo_color = _color

func _physics_process(delta):
	if checkingForMovement:
		if timer>0:
			timer -= delta
		else:
			timer = 0
			checkForStopping()
	
	if Input.is_action_pressed("ui_accept") && mouseOnArrow:
		var rayPos = ownr.get_node("head/cam/ray").get_collision_point()
		var rayPos2D = Vector2(rayPos.x,rayPos.z)
		var pos = global_position
		var pos2D = Vector2(pos.x,pos.z)
		var curDist = pos2D-rayPos2D
		$thrower.look_at(rayPos)
		$thrower.rotation = Vector3(0,$thrower.rotation.y+PI/2,0)
		$thrower.rotation.y = clamp($thrower.rotation.y,PI/2,3*PI/2)
		$thrower/arrowMesh.position.x = curDist.length()
		$thrower/arrowMesh.position.x = clamp($thrower/arrowMesh.position.x,2,6)
		$thrower/arrow.position.x = curDist.length()
		$thrower/arrow.position.x = clamp($thrower/arrow.position.x,2,6)
	
	if global_position.y <= -50:
		global_position = Vector3(0,30,0)
		linear_velocity/=5
		angular_velocity/=5
	
	#if Vector2(linear_velocity.x,linear_velocity.z).length()>1\
	#&& linear_velocity.y < 1 &&\
	#Vector2(angular_velocity.x,angular_velocity.z).length()<5&&\
	#angular_velocity.y > 0.3:
		#$diceSlide.play()

func _input(event):
	if event.is_action_pressed("ui_accept") && mesh.get_child(0).visible && !thrown:
		if (main.battleReady && (main.p1==ownr||main.p2==ownr)):
			seriousCounting = true
			main.stopTimer.rpc_id(1)
		else:
			seriousCounting = false
		throw()
		thrown = true

func throw():
	var targetVec = global_position - $thrower/arrowMesh.global_position
	var magnitude = targetVec.length()
	targetVec.y = magnitude*2
	apply_central_impulse(targetVec*1.5)
	rotation = auto.vec3Rand(2*PI)
	apply_torque_impulse(auto.vec3Rand(1).normalized()*magnitude*3*randf_range(0.5,1.5))
	$thrower.hide()
	$throw.play()
	checkForStopping()

func checkForStopping():
	if checkingForMovement == false:
		checkingForMovement = true
		timer = 1
		return
	if linear_velocity.length() >= 0.01 && angular_velocity.length() >= 0.01:
		checkingForMovement = true
		timer = 1
	else:
		checkingForMovement = false
		var result = getVal()
		if seriousCounting:
			print("SUBMITTING "+str(result)+" "+ownr.name)
			main.submitScore.rpc_id(1,multiplayer.get_unique_id(),result)

func getVal():
	var tallest
	var height = -99999
	for val in values:
		if val.global_position.y > height:
			height = val.global_position.y
			tallest = val
	if tallest.get_index() == maxValue:
		for child in tallest.get_children():
			child.superShine.rpc()
			$critScore.play()
	else:
		for child in tallest.get_children():
			child.shine.rpc()
			$score.play()
	return values.find(tallest)

func highlight():
	if !thrown &&(!main.gameStarted || (main.battleReady && (main.p1==ownr||main.p2==ownr))):
		mesh.get_child(0).show()
func unhighlight():
	mesh.get_child(0).hide()

func instantiateShop():
	showShop()
	var money = get_parent().get_parent().health
	if money <= upgradePrice:
		hideUpArrow()
	if upgradePrice <= 4:
		hideDownarrow()

func closeShop():
	hideShop()
	$shop/upSign.show()
	$shop/upSign/brightUpSign.hide()
	$shop/unUpSign.hide()
	$shop/downSign.show()
	$shop/downSign/brightDownSign.hide()
	$shop/unDownSign.hide()
	unhighlightup()
	unhighlightdown()

func showShop():
	$shop.show()
	$shop.position.y = 0
func hideShop():
	$shop.hide()
	$shop.position.y = -1000
func hideUpArrow():
	$shop/upSign.hide()
	$shop/upSign/brightUpSign.hide()
	$shop/unUpSign.show()
func hideDownarrow():
	$shop/downSign.hide()
	$shop/downSign/brightDownSign.hide()
	$shop/unDownSign.show()
func highlightup():
	if $shop/upSign.visible:
		$shop/upSign/brightUpSign.show()
func unhighlightup():
	$shop/upSign/brightUpSign.hide()
func highlightdown():
	if $shop/downSign.visible:
		$shop/downSign/brightDownSign.show()
func unhighlightdown():
	$shop/downSign/brightDownSign.hide()

func _on_body_entered(body):
	if body.is_in_group("table") && linear_velocity.length()>1:
		$diceHit.pitch_scale = hitPitch*(0.9+angular_velocity.length()/50)
		$diceHit.play()

func _on_mouse_entered():
	mesh.get_child(0).show()
func _on_mouse_exited():
	mesh.get_child(0).hide()
func _on_arrow_mouse_entered(): # change to ray hitting
	mouseOnArrow = true
func _on_arrow_mouse_exited():
	mouseOnArrow = false
