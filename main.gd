extends Node3D

signal endTurnSignal

var Player = preload("res://player/player.tscn")
var d4 = preload("res://dices/d4.tscn")

var gameStarted = false
var battleReady = false

var p1
var p2

var host

var Round = 0:
	set(val):
		Round = val
		$gameGui/vbox/round.text = "ROUND   "+str(val) 

func _ready():
	$gameGui.set_multiplayer_authority(1)

func _physics_process(_delta):
	if $players.get_child_count() <= 0 || gameStarted:
		return
	#IF IM THE HOST
	if get_node("players").get_child(0).name == str(multiplayer.get_unique_id()):
		#readying
		var AllReady = true
		for player in $players.get_children():
			if player.Ready == false:
				AllReady = false
		if AllReady == true:
			startGame.rpc()
		#start timer for ending round
		if battleReady&&p1.score>0 && p2.score>0 && $roundOverTimer.is_stopped():
			$roundOverTimer.start()

@rpc("call_local")
func orderPlayers():
	var players = $players.get_children()
	var rad = 26
	var spawnInterval = 2*PI/players.size()
	var curDegree = 0
	for player in players:
		var spawnPos = Vector3(cos(curDegree),0,sin(curDegree))*rad
		if player.is_multiplayer_authority():
			player.position = spawnPos
			player.look_at(Vector3.ZERO)
			player.rotation.y += PI/2
		curDegree += spawnInterval

@rpc("call_local") #Everyone
func startGame():
	print("- - - - STARTING GAME - - - -")
	gameStarted = true
	$bgm.volume_db = -40
	$gameGui/vbox/round.show()
	$gameGui/startOption.hide()
	for player in $players.get_children():
		player.get_node("ready").hide()
	nextRound()

@rpc("any_peer","call_local")
func nextRound():
	Round+=1
	if multiplayer.get_unique_id() != 1:
		return
	# ------ HOST ------ #
	var players = determineTurnOrder()
	if Round == 1:
		for player in players:
			player.resetDices.rpc_id(player.name.to_int(),true)
	cycleTurns(players)

func enterBuyingPhase():
	for player in $players.get_children():
		if player.dead:
			continue
		player.addScore.rpc_id(player.name.to_int(),Round)
		await get_tree().create_timer(0.03).timeout
		player.win.rpc_id(player.name.to_int())
		await get_tree().create_timer(0.03).timeout
		player.addScore.rpc_id(player.name.to_int(),-Round)
		await get_tree().create_timer(0.03).timeout
		player.openShop.rpc_id(player.name.to_int())
	$buyTimer.start()

func exitBuyingPhase():
	for player in $players.get_children():
		if player.dead:
			continue
		player.closeShop.rpc_id(player.name.to_int())

func _on_buy_timer_timeout():
	exitBuyingPhase()
	nextRound()

func cycleTurns(players):#Host only
	for player in players:
		if player.dead:
			continue
		player.startTurn.rpc_id(player.name.to_int())
		await Signal(self,"endTurnSignal")
		print("Received order to start next person's turn")
		await get_tree().create_timer(0.04).timeout
		hideScore.rpc()
		findIfAnyoneWon()
	await get_tree().create_timer(0.03).timeout
	resetBoard()
	await get_tree().create_timer(0.06).timeout
	enterBuyingPhase()

func findIfAnyoneWon():
	var numdead = 0
	var survivor
	for player in $players.get_children():
		if player.dead:
			numdead+=1
		else:
			survivor = player
	if numdead==$players.get_child_count()-1:
		survivor.winGame.rpc_id(survivor.name.to_int())

@rpc("any_peer","call_local")
func emitEndTurnSignal():
	endTurnSignal.emit()

func determineTurnOrder():
	var players = $players.get_children()
	for player in players:
		if player.dead:
			players.erase(player)
	players.shuffle()
	for player in players:
		var order = players.find(player)
		announceTurnOrder.rpc_id(player.name.to_int(),order)
	return players

@rpc("any_peer","call_local")
func announceTurnOrder(order):
	var player = $players.get_node(str(multiplayer.get_unique_id()))
	var turnNode = player.get_node("turnOrder")
	turnNode.show()
	turnNode.text = "Turn  Order :   "+str(order+1)

@rpc("any_peer","call_local")
func setBattlers(_p1, _p2): # Everyone
	p1 = $players.get_node(_p1)
	p2 = $players.get_node(_p2)
	var label = $gameGui/vbox/pvp
	label.text = p1.dname+'('+auto.buyDiceNames[p1.level]+')'+"   vs   "+\
	p2.dname+'('+auto.buyDiceNames[p2.level]+')'
	label.show()
	$announceBattle.play()
	turnOffLights.rpc()
	p1.spotlightShow.rpc_id(p1.name.to_int())
	p2.spotlightShow.rpc_id(p2.name.to_int())
	battleReady = true

@rpc("any_peer","call_local")
func turnOffLights():
	$light1.hide()
	$light2.hide()
	$light3.hide()

@rpc("any_peer","call_local")
func turnOnLights():
	$light1.show()
	$light2.show()
	$light3.show()

@rpc("any_peer","call_local")
func announceBattle(_p1,_p2):#host only
	setBattlers.rpc(_p1,_p2)
	p1.showArrow.rpc_id(p1.name.to_int())
	p2.showArrow.rpc_id(p2.name.to_int())
	p1.hideBlinder.rpc_id(p1.name.to_int())
	p2.hideBlinder.rpc_id(p2.name.to_int())
	p2.resetDices.rpc_id(p2.name.to_int())#reset dices
	p1.resetDices.rpc_id(p1.name.to_int())

@rpc("any_peer","call_local")#host only
func submitScore(pid,score):
	var playerNode = $players.get_node(str(pid))
	playerNode.addScore.rpc_id(pid,score)
	startTimer.rpc_id(1)
	await get_tree().create_timer(0.06).timeout
	showScore.rpc(p1.score,p2.score)

@rpc("any_peer","call_local")
func showScore(score1,score2):
	$gameGui/vbox/pvp2.text = str(score1)+"    vs   "+str(score2)
	$gameGui/vbox/pvp2.show()

@rpc("any_peer","call_local")
func hideScore():
	$gameGui/vbox/pvp2.hide()

@rpc("any_peer","call_local") # host only
func stopTimer():
	$roundOverTimer.stop()

@rpc("any_peer","call_local") # host only
func startTimer():
	$roundOverTimer.start()

func _on_round_over_timer_timeout():# Host Only
	var p1coinSpace = p1.get_node("coinSpace/d2")
	var p2coinSpace = p2.get_node("coinSpace/d2")
	if p1.score==0 || p2.score==0 ||\
	 (p1coinSpace.linear_velocity.length() >= 0.01 && p1coinSpace.angular_velocity.length() >= 0.01)\
	|| (p2coinSpace.linear_velocity.length() >= 0.01 && p2coinSpace.angular_velocity.length() >= 0.01):
		$roundOverTimer.start()
		return
	determineWinner()

func determineWinner():# Host Only
	if p1.score==p2.score:
		resetBattle()
		return
	if p1.score>p2.score:
		p1.win.rpc_id(p1.name.to_int())
		p2.lose.rpc_id(p2.name.to_int(),p1.score)
		announceWinner.rpc(p1.dname,p1.score,p1.color)
	elif p2.score>p1.score:
		p2.win.rpc_id(p2.name.to_int())
		p1.lose.rpc_id(p1.name.to_int(),p2.score)
		announceWinner.rpc(p2.dname,p2.score,p2.color)
		
	await get_tree().create_timer(0.05).timeout
	
	p1.addScore.rpc_id(p1.name.to_int(),-p1.score)
	p2.addScore.rpc_id(p2.name.to_int(),-p2.score)
	
	await get_tree().create_timer(0.05).timeout
	
	p1.stopFight.rpc()
	p2.stopFight.rpc()
	
	turnOnLights.rpc()
	p1.hideSpotlight.rpc_id(p1.name.to_int())
	p2.hideSpotlight.rpc_id(p2.name.to_int())
	
	await get_tree().create_timer(3).timeout
	
	endTurn.rpc()

@rpc("any_peer","call_local")# everyone
func announceWinner(_dname,_score,_color):
	$gameGui/vbox/pvpWinner.text = _dname+"    WIN\n"+str(_score)
	$gameGui/vbox/pvpWinner.set("theme_override_colors/font_color",_color)
	$gameGui/vbox/pvpWinner.show()

func resetBattle():# Host Only
	p1.addScore.rpc_id(p1.name.to_int(),-p1.score)
	p2.addScore.rpc_id(p2.name.to_int(),-p2.score)
	p1.resetDices.rpc_id(p1.name.to_int())
	p2.resetDices.rpc_id(p2.name.to_int())
	p1.showArrow.rpc_id(p1.name.to_int())
	p2.showArrow.rpc_id(p2.name.to_int())

func resetBoard(): # Host Only
	for player in $players.get_children():
		player.addScore.rpc_id(player.name.to_int(),-player.score)
		player.resetDices.rpc_id(player.name.to_int())

@rpc("any_peer","call_local")# everyone
func endTurn():
	battleReady = false
	p1 = null
	p2 = null
	$gameGui/vbox/pvpWinner.hide()

func showDeathFilter():
	$deathFilter.show()
