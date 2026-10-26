extends Control

var Player = preload("res://player/player.tscn")
@onready var main = get_parent()

var peer = ENetMultiplayerPeer.new()

var curname
var curcolor

func _on_host_pressed():
	var port = float($c/port.text)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	print("Server Created!")
	peer_connected(1)
	hide()
	main.get_node("gameGui/waiting").show()
	await get_tree().create_timer(1).timeout
	var myPlayer = get_parent().get_node("players").get_node("1")
	myPlayer.admitStats($c/name.text,$c/color.color)

func _on_join_pressed():
	var port = float($c/port.text)
	var ip = $c/ip.text
	if ip == "":
		ip = "localhost"
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	peer.create_client(ip,port)
	multiplayer.multiplayer_peer = peer
	await get_tree().create_timer(1).timeout
	var myPlayer = get_parent().get_node("players").get_node(str(multiplayer.get_unique_id()))
	myPlayer.admitStats($c/name.text,$c/color.color)

func peer_connected(id): #called only on host
	print("Player Connected "+str(id))
	addPlayer(id)
	if main.get_node("players").get_child_count()>=2:
		main.get_node("gameGui/waiting").hide()
		main.get_node("gameGui/startOption").show()

func addPlayer(id): #called only on host
	var player = Player.instantiate()
	player.name = str(id)
	player.dname = $c/name.text
	main.get_node("players").add_child(player,true)
	main.orderPlayers.rpc()

func peer_disconnected(id):
	print("Player Disconnected "+str(id))

func connected_to_server():
	print("Connected to Server!")
	hide()

func connection_failed():
	print("Connection Failed!")
	$connectionFailed.show()

var ip_address :String

func _ready():
	if OS.has_feature("windows"):
		if OS.has_environment("COMPUTERNAME"):
			ip_address = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	#elif OS.has_feature("x11"):
		#if OS.has_environment("HOSTNAME"):
			#ip_address =  IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)
	#elif OS.has_feature("OSX"):
		#if OS.has_environment("HOSTNAME"):
			#ip_address =  IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)
	$IP.text = "Your  IP  Address:  "+ip_address
