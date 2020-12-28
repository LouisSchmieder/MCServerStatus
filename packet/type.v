module packet

enum PacketType {
	error
	// OUT
	out_handshake
	out_status_request
	out_status_ping
	// In
	in_status_response
	in_status_pong
}
