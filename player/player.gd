extends Node3D

signal endTurnSignal

var id = -1
var won = false

@onready var main = get_parent().get_parent()

@export var dname = "ERROR"
@export var Ready = false
@export var yourTurn = false:
	set(val):
		yourTurn = val
		if val:
			$yourTurn.show()
		else:
			$yourTurn.hide()

@export var score = 0

@export var health = 15:
	set(val):
		health = val
		$health.text = str(val)

@export var color = Color(1,1,1,1)

@export var dead = false

@export var level = 1

var returnDice = false
var returnCoin = false

func _enter_tree():
	id = str(name).to_int()
	set_multiplayer_authority(id)
	
func _ready():
	if !is_multiplayer_authority():
		return
	$name.text = dname
	if id==1:
		$gui/hostLabel.show()
	$head/cam.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func admitStats(_dname,_color): #ownr of node
	dname = _dname
	$name.text = dname
	color = _color
	#call [all players but you] to rpc their colors to new people
	for player in main.get_node("players").get_children():
		player.get_node("bodyParts").setColors.rpc(player.color)
		player.get_node("diceSpace").get_child(0).setColors.rpc(player.color)
		player.get_node("coinSpace").get_child(0).setColors.rpc(player.color)
	
func _input(event):
	if !is_multiplayer_authority():
		return
	if event.is_action_pressed("escape"):
		if $gui/pauseMenu.visible:
			$gui/pauseMenu.hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			$gui/pauseMenu.show()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event.is_action_pressed("hit"):
		$anim.stop()
		$anim.play("throw")
		for player in main.get_node("players").get_children():
			if main.battleReady:
				break
			if player.get_node("highlight").visible:
				main.announceBattle.rpc_id(1,str(name),str(player.name))
		var shop = $diceSpace.get_child(0).get_node("shop")
		if shop.visible: #shop stuff
			if shop.get_node("upSign/brightUpSign").visible: #upgrade dice
				health -= $diceSpace.get_child(0).upgradePrice
				level += 1
				await get_tree().create_timer(0.04).timeout
				replaceDice.rpc()
			elif shop.get_node("downSign/brightDownSign").visible: #downgrade dice
				health += $diceSpace.get_child(0).maxValue
				level -= 1
				await get_tree().create_timer(0.04).timeout
				replaceDice.rpc()
	if event.is_action_pressed("reset") && !main.gameStarted:
		resetDices(true)
	if event.is_action_pressed("glitched"):
		$diceSpace.get_child(0).linear_velocity = Vector3.ZERO
		$diceSpace.get_child(0).angular_velocity = Vector3.ZERO
		$coinSpace.get_child(0).linear_velocity = Vector3.ZERO
		$coinSpace.get_child(0).angular_velocity = Vector3.ZERO
		
	if event.is_action_pressed("ready") && get_parent().get_parent().get_node("players").get_child_count()>=2:
		if Ready:
			$sfx_nvm.play()
			Ready = false
			$ready.hide()
		else:
			$sfx_ready.play()
			Ready = true
			$ready.show()

@rpc("any_peer","call_local") #Every instance of this player, callable only by host
func replaceDice():
	var curDice = $diceSpace.get_child(0)
	var upgradedDice = auto.buyProgression[level].instantiate()
	upgradedDice.set_multiplayer_authority(id)
	$diceSpace.remove_child(curDice)
	curDice.queue_free()
	$diceSpace.add_child(upgradedDice)
	await get_tree().create_timer(0.06).timeout
	for player in main.get_node("players").get_children():
		player.get_node("diceSpace").get_child(0).setColors.rpc(player.color)
	if is_multiplayer_authority():
		upgradedDice.instantiateShop()

func _process(_delta):
	if !is_multiplayer_authority():
		return
	if Input.is_action_pressed("zoom"):
		$head/cam.position = Vector3(4,-0.3,0)
	else:
		$head/cam.position = Vector3(1.5,-0.3,0)
	
	if returnDice || returnCoin:
		var dices = [$diceSpace.get_child(0),$coinSpace.get_child(0)]
		var returned = [true, true]
		for Dice in dices:
			if !returnCoin && dices.find(Dice)==1:
				continue
			var pos = Dice.position
			if pos.length() > 0.1:
				Dice.position = Vector3(\
				lerp(pos.x,0.0,0.1),\
				lerp(pos.y,0.0,0.1),\
				lerp(pos.z,0.0,0.1))
				returned[dices.find(Dice)] = false
			else:
				Dice.linear_velocity = Vector3.ZERO
				Dice.angular_velocity = Vector3.ZERO
				Dice.position = Vector3.ZERO
				Dice.rotation = Vector3.ZERO
				Dice.thrown = false
		if returned[0]:
			returnDice = false
		if returned[1]:
			returnCoin = false
	
@rpc("any_peer","call_local") #Owner Only
func startTurn():
	yourTurn = true
	await Signal(self,"endTurnSignal")
	endTurn()

@rpc("any_peer","call_local") #Owner Only
func spotlightShow():
	$spotlight.show()
	$spotlightAnim.stop()
	$spotlightAnim.play("spotlight")

@rpc("any_peer","call_local")
func addScore(amt):
	score += amt

@rpc("any_peer","call_local")
func hideSpotlight():
	$spotlight.hide()

func endTurn(): #Owner Only
	yourTurn = false
	$spotlight.hide()
	main.emitEndTurnSignal.rpc_id(1)

@rpc("any_peer","call_local")
func resetDices(coinToo = false):
	returnDice = true
	returnCoin = coinToo

@rpc("any_peer","call_local")
func win():
	health+=score
	$winLoseRound.stream = auto.winRoundSound
	$winLoseRound.play()
	
@rpc("any_peer","call_local")
func lose(_score):
	health-=_score
	$winLoseRound.stream = auto.loseRoundSound
	$winLoseRound.play()
	if health<=0:
		die()

func die(): #owner
	dead = true
	$head.visible = false
	$sfx_death.play()
	$headBlowUp.emitting = true
	$loseSound.play()
	$die.show()
	main.showDeathFilter()

@rpc("any_peer","call_local")
func stopFight():
	endTurnSignal.emit()

func highlight():
	$highlight.show()
func unhighlight():
	$highlight.hide()

@rpc("any_peer","call_local")#owner
func winGame():
	won = true
	$won.show()
	$winSound.play()

@rpc("any_peer","call_local")#owner
func openShop():
	var Dice = $diceSpace.get_child(0)
	Dice.position = Vector3.ZERO
	Dice.rotation = Vector3.ZERO
	Dice.linear_velocity = Vector3.ZERO
	Dice.angular_velocity = Vector3.ZERO
	Dice.instantiateShop()
	$wall.show()

@rpc("any_peer","call_local")#owner
func closeShop():
	var Dice = $diceSpace.get_child(0)
	Dice.closeShop()

@rpc("any_peer","call_local")#owner
func showArrow():
	$diceSpace.get_child(0).get_node("thrower").show()

@rpc("any_peer","call_local")#owner
func hideBlinder():
	$wall.hide()

func _on_volume_value_changed(value):
	if !is_multiplayer_authority():
		return
	var newVolume = linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), newVolume)
	$gui/pauseMenu/vox/volumeBox/volumeLevel.text = str(value*100)

func _on_sense_value_changed(value):
	if !is_multiplayer_authority():
		return
	$head.sensitivity = value
	$gui/pauseMenu/vox/senseBox/senseLevel.text = str(value)
