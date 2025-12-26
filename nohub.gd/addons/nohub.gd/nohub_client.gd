class_name NohubClient

## Base class for nohub clients
## This class provides the common interface for nohub clients.
## Specific implementations should extend this class and implement the required methods.

var _reactor: TrimsockReactor

func _is_ready() -> bool:
	push_error("_is_ready() must be implemented by subclass")
	return false

<< << << < HEAD
func _get_reactor() -> TrimsockReactor:
	return _reactor
== == == =

## Construct a client using the specified [param connection]
func _init(connection: StreamPeerTCP):
	_connection = connection
	_connection.set_no_delay(true)

	_reactor = TrimsockTCPClientReactor.new(connection)
	_setup_webrtc_reactor()

## Poll the client
## [br][br]
## This will poll the underlying connection and process any incoming commands.
func poll() -> void:
	_reactor.poll()
>> >> >> > 1400b8c(feat: webrtcsetupreactor and signalingmodule)

## Specify the game ID used by this client
## [br][br]
## See [url=https://foxssake.github.io/nohub/understanding-nohub/concepts.html#games]Games[/url].
func set_game(id: String) -> NohubResult:
<< << << < HEAD
	if not _is_ready():
		return NohubResult.of_error("NotConnected", "Client is not connected to server")
	
	var request := TrimsockCommand.request("session/set-game") \
== == == =
	var request := TrimsockCommand.request("session/set-game") \
>> >> >> > 1400b8c(feat: webrtcsetupreactor and signalingmodule)
		.with_params([id])
	return await _bool_request(request)

## Create a lobby
func create_lobby(address: String, data: Dictionary = {}) -> NohubResult.Lobby:
<< << << < HEAD
	if not _is_ready():
		return NohubResult.of_error("NotConnected", "Client is not connected to server")
	
	var request := TrimsockCommand.request("lobby/create") \
== == == =
	var request := TrimsockCommand.request("lobby/create") \
>> >> >> > 1400b8c(feat: webrtcsetupreactor and signalingmodule)
		.with_params([address])
	for key in data:
		request.with_kv_pairs([TrimsockCommand.pair_of(key, data[key])])

	var xchg: TrimsockExchange = _get_reactor().submit_request(request)
	var response: TrimsockCommand = await xchg.read()

	if response.is_success():
		return NohubResult.Lobby.of_value(_command_to_lobby(response))
	else:
		return _command_to_error(response)

## Query a lobby by ID
## [br][br]
## If [param properties] is specified, only the listed properties will be
## returned from the lobby's custom data.
func get_lobby(id: String, properties: Array[String] = []) -> NohubResult.Lobby:
<< << << < HEAD
	if not _is_ready():
		return NohubResult.of_error("NotConnected", "Client is not connected to server")
	
	var request := TrimsockCommand.request("lobby/get") \
== == == =
	var request := TrimsockCommand.request("lobby/get") \
>> >> >> > 1400b8c(feat: webrtcsetupreactor and signalingmodule)
		.with_params([id] + properties)
	var xchg: TrimsockExchange = _get_reactor().submit_request(request)
	var response: TrimsockCommand = await xchg.read()

	if response.is_success():
		return NohubResult.Lobby.of_value(_command_to_lobby(response))
	else:
		return _command_to_error(response)

## List lobbies by ID
## [br][br]
## If [param properties] is specified, only the listed properties will be
## returned from the lobby's custom data.
func list_lobbies(properties: Array[String] = []) -> NohubResult.LobbyList:
	if not _is_ready():
		return NohubResult.of_error("NotConnected", "Client is not connected to server")
	
	var result := [] as Array[NohubLobby]
	var request := TrimsockCommand.request("lobby/list") \
		.with_params(properties)

	var xchg: TrimsockExchange = _get_reactor().submit_request(request)
	while xchg.is_open():
		var cmd: TrimsockCommand = await xchg.read()

		if cmd.is_error():
			return _command_to_error(cmd)
		if not cmd.is_stream_chunk():
			continue

		result.push_back(_command_to_lobby(cmd))

	return NohubResult.LobbyList.of_value(result)

## Delete a lobby using its ID
## [br][br]
## Only the lobby's owner can delete the lobby.
func delete_lobby(lobby_id: String) -> NohubResult:
<< << << < HEAD
	if not _is_ready():
		return NohubResult.of_error("NotConnected", "Client is not connected to server")
	
	var request := TrimsockCommand.request("lobby/delete") \
== == == =
	var request := TrimsockCommand.request("lobby/delete") \
>> >> >> > 1400b8c(feat: webrtcsetupreactor and signalingmodule)
		.with_params([lobby_id])
	return await _bool_request(request)

## Join a lobby using its ID
## [br][br]
## The response will contain the lobby's address. This string can be used to
## connect.
func join_lobby(lobby_id: String) -> NohubResult.Address:
<< << << < HEAD
	if not _is_ready():
		return NohubResult.of_error("NotConnected", "Client is not connected to server")
	
	var request := TrimsockCommand.request("lobby/join") \
== == == =
	var request := TrimsockCommand.request("lobby/join") \
>> >> >> > 1400b8c(feat: webrtcsetupreactor and signalingmodule)
		.with_params([lobby_id])

	var xchg: TrimsockExchange = _get_reactor().submit_request(request)
	var response: TrimsockCommand = await xchg.read()
	
	if response.is_success():
		return NohubResult.Address.of_value(response.params[0])
	else:
		return _command_to_error(response)

## Lock the lobby, preventing others from joining
## [br][br]
## Only the lobby's owner can lock the lobby.
func lock_lobby(lobby_id: String) -> NohubResult:
<< << << < HEAD
	if not _is_ready():
		return NohubResult.of_error("NotConnected", "Client is not connected to server")
	
	var request := TrimsockCommand.request("lobby/lock") \
== == == =
	var request := TrimsockCommand.request("lobby/lock") \
>> >> >> > 1400b8c(feat: webrtcsetupreactor and signalingmodule)
		.with_params([lobby_id])
	return await _bool_request(request)

## Unlock the lobby, allowing others to join
## [br][br]
## Only the lobby's owner can unlock the lobby. Lobbies are unlocked by default.
func unlock_lobby(lobby_id: String) -> NohubResult:
<< << << < HEAD
	if not _is_ready():
		return NohubResult.of_error("NotConnected", "Client is not connected to server")
	
	var request := TrimsockCommand.request("lobby/unlock") \
== == == =
	var request := TrimsockCommand.request("lobby/unlock") \
>> >> >> > 1400b8c(feat: webrtcsetupreactor and signalingmodule)
		.with_params([lobby_id])
	return await _bool_request(request)

## Hide lobby, making it invisible when listing lobbies
## [br][br]
## Only the lobby's owner can hide the lobby.
func hide_lobby(lobby_id: String) -> NohubResult:
<< << << < HEAD
	if not _is_ready():
		return NohubResult.of_error("NotConnected", "Client is not connected to server")
	
	var request := TrimsockCommand.request("lobby/hide") \
== == == =
	var request := TrimsockCommand.request("lobby/hide") \
>> >> >> > 1400b8c(feat: webrtcsetupreactor and signalingmodule)
		.with_params([lobby_id])
	return await _bool_request(request)

## Pulbish lobby, making it visible when listing lobbies
## [br][br]
## Only the lobby's owner can hide the lobby. Lobbies are visible by default.
func publish_lobby(lobby_id: String) -> NohubResult:
<< << << < HEAD
	if not _is_ready():
		return NohubResult.of_error("NotConnected", "Client is not connected to server")
	
	var request := TrimsockCommand.request("lobby/publish") \
== == == =
	var request := TrimsockCommand.request("lobby/publish") \
>> >> >> > 1400b8c(feat: webrtcsetupreactor and signalingmodule)
		.with_params([lobby_id])
	return await _bool_request(request)

## Set the lobby's custom data
## [br][br]
## Note that this method updates the data, instead of adding to it. Only the 
## lobby's owner can update the lobby's custom data.
func set_lobby_data(lobby_id: String, data: Dictionary) -> NohubResult:
<< << << < HEAD
	if not _is_ready():
		return NohubResult.of_error("NotConnected", "Client is not connected to server")
	
	var request := TrimsockCommand.request("lobby/set-data") \
		.with_params([lobby_id]) \
== == == =
	var request := TrimsockCommand.request("lobby/set-data") \
		.with_params([lobby_id]) \
>> >> >> > 1400b8c(feat: webrtcsetupreactor and signalingmodule)
		.with_kv_map(data)
	return await _bool_request(request)

## Return the client's address, as seen by the nohub server
## [br][br]
## This can be used to get the client's public IP address. Note that depending
## on its configuration, the server might not be able to return a useful address
## - e.g. when running from Docker using a bridge network.
func whereami() -> String:
	if not _is_ready():
		return ""
	
	var request := TrimsockCommand.request("whereami")
	var xchg: TrimsockExchange = _get_reactor().submit_request(request)
	var response: TrimsockCommand = await xchg.read()
	
	if response.is_success():
		return response.text
	else:
		return ""

func _bool_request(request: TrimsockCommand) -> NohubResult:
	var xchg: TrimsockExchange = _get_reactor().submit_request(request)
	var response: TrimsockCommand = await xchg.read()
	if response.is_success():
		return NohubResult.of_success()
	else:
		return _command_to_error(response)

func _command_to_lobby(command: TrimsockCommand) -> NohubLobby:
	var lobby := NohubLobby.new()
	lobby.id = command.params[0]
	lobby.is_locked = command.params.find("locked", 1) >= 0
	lobby.is_visible = command.params.find("hidden", 1) < 0
	lobby.data = command.kv_map
	return lobby

func _command_to_error(command: TrimsockCommand) -> NohubResult:
	if command.is_error() and command.params.size() >= 2:
		return NohubResult.of_error(command.params[0], command.params[1])
	else:
		return NohubResult.of_error(command.name, "")

#region WebRTC

# TODO: Determine the best place to define these signals. They are used in the browser
signal signal_webrtc_create_new_peer_connection(id)
signal signal_webrtc_message(type, data)

## Setup the events for negotiating WebRTC connections using the signalling module
## [br][br]
## When a lobby host starts a lobby (or a peer asks for an offer, answer, or candidate):
## these events will emit signals that the clients use to initialize WebRTC peer connections
## NOTE: This function is based on the _setup_reactor example in this file:
## https://github.com/foxssake/trimsock/blob/main/trimsock.gd/examples/server/server.gd
func _setup_webrtc_reactor() -> void:
	_reactor.on("webrtc/start", func(_cmd: TrimsockCommand, xchg: TrimsockExchange):
		var players = _cmd.kv_map['players'] as String
		for peer_id in players.split(',', false):
			signal_webrtc_create_new_peer_connection.emit(int(peer_id.strip_edges()))
	).on("webrtc/get/offer", func(_cmd, xchg: TrimsockExchange):
		signal_webrtc_message.emit(WEBRTC_ACTION.Offer, _cmd)
	).on("webrtc/get/answer", func(_cmd, xchg: TrimsockExchange):
		signal_webrtc_message.emit(WEBRTC_ACTION.Answer, _cmd)
	).on("webrtc/get/candidate", func(_cmd, xchg: TrimsockExchange):
		signal_webrtc_message.emit(WEBRTC_ACTION.Candidate, _cmd)
	).on_unknown(func(cmd, xchg: TrimsockExchange):
		_log("[srv] Unknown command: %s" % cmd)
		return TrimsockCommand.error_from(cmd, "error", ["Unknown command", cmd.name])
	)

	# TODO: Necessary?
	_reactor.on_attach.connect(func(src: StreamPeerTCP):
		var id := _session_id()
		_log("[srv] New connection: " + id)
		src.set_no_delay(true)

		_reactor.set_session(src, id)
		_reactor.send(src, TrimsockCommand.simple("ohai"))
	)

	_reactor.on_detach.connect(func(src):
		_log("[srv] Connection closed!")
	)

func _log(what: String) -> void:
	prints(what)

func _session_id(length: int = 4) -> String:
	const charset := "abcdefghijklmnopqrstuvwxyz" + "ABCDEFGHIJKLMNOPQRSTUVWXYZ" + "0123456789"
	var id := ""
	for i in length:
		id += charset[randi() % charset.length()]
	return id


## Start lobby, kicking off joining
## [br][br]
## Only the lobby's owner can start the lobby. 
func start_lobby(lobby_id: String) -> NohubResult.LobbyMessage:
	var request := TrimsockCommand.request("webrtc/lobby/start") \
		.with_params([lobby_id])

	var xchg := _reactor.submit_request(request)
	var response := await xchg.read()

	if response.is_success():
		return NohubResult.LobbyMessage.of_value(response.params[0])
	else:
		return _command_to_error(response)

## Leave the lobby
## [br][br]
func leave_lobby(lobby_id: String) -> NohubResult.LobbyMessage:
	var request := TrimsockCommand.request("lobby/leave") \
		.with_params([lobby_id])

	var xchg := _reactor.submit_request(request)
	var response := await xchg.read()

	if response.is_success():
		return NohubResult.LobbyMessage.of_value(response.params[0])
	else:
		return _command_to_error(response)

func get_session() -> String:
	var request := TrimsockCommand.request("getid")
	var xchg := _reactor.submit_request(request)
	var response := await xchg.read()
	if response.is_success():
		return response.text
	else:
		return ""

enum WEBRTC_ACTION {
	Offer,
	Answer,
	Candidate
}

func send_webrtc_message(type: WEBRTC_ACTION, id: String, data: Dictionary = {}) -> NohubResult:
	var request

	match type:
		WEBRTC_ACTION.Offer:
			request = TrimsockCommand.request("webrtc/offer").with_params([id])
		WEBRTC_ACTION.Answer:
			request = TrimsockCommand.request("webrtc/answer").with_params([id])
		WEBRTC_ACTION.Candidate:
			request = TrimsockCommand.request("webrtc/candidate").with_params([id])

	request.with_kv_map(data)

	var xchg := _reactor.submit_request(request)
	var response := await xchg.read()

	if response.is_success():
		return NohubResult.LobbyMessage.of_value('send success')
	else:
		return _command_to_error(response)

#endregion
