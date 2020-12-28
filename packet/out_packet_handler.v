module packet

import sio

fn write_handshake(mut nos sio.NetOutputStream, data PacketOutHandshake) {
	nos.write_var_int(data.protocol_ver)
	nos.write_var_string(data.host)
	nos.write_i16(data.port)
	nos.write_var_int(data.next_state.to_number())
}

fn write_status_request(mut nos sio.NetOutputStream, data PacketOutStatusRequest) {}

fn write_status_ping(mut nos sio.NetOutputStream, data PacketOutStatusPing) {
	nos.write_i64(data.payload)
}
