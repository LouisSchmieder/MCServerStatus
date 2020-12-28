module packet

import sio

fn read_status_response(mut nis sio.NetInputStream) PacketInStatusResponse {
	json_response := nis.read_mc_string()
	return PacketInStatusResponse{
		json_response: json_response
	}
}

fn read_status_pong(mut nis sio.NetInputStream) PacketInStatusPong {
	payload := nis.read_i64()
	return PacketInStatusPong{
		payload: payload
	}
}
