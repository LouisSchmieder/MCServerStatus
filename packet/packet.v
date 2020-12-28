module packet

import net
import sio

type PacketData = NoPacketData | PacketInStatusPong | PacketInStatusResponse | PacketOutHandshake |
	PacketOutStatusPing | PacketOutStatusRequest

pub struct Packet {
pub:
	len         int
	id          int
	data        PacketData
	packet_type PacketType
}

pub fn read_packet(sock net.TcpConn, state State) ?(Packet) {
	mut nio := sio.new_net_input_stream(sock)
	len := nio.read_pure_var_int()
	if len <= 0 {
		return error('Packet lenght is $len')
	}
	nio.clear_len()
	pkt_id := nio.read_pure_var_int()
	data, typ := read_packet_data(pkt_id, mut nio, state, len)
	return Packet{
		len: len
		id: pkt_id
		data: data
		packet_type: typ
	}
}

pub fn write_packet(sock net.TcpConn, packet Packet, state State) {
	mut nos := sio.new_net_output_stream(sock)
	write_packet_data(mut nos, packet, state)
}

fn read_packet_data(pkt_id int, mut nio sio.NetInputStream, state State, len int) (PacketData, PacketType) {
	mut packet_data := PacketData(NoPacketData{})
	mut packet_type := PacketType.error
	match state {
		.status {
			match pkt_id {
				0x00 {
					packet_data = PacketData(read_status_response(mut nio))
					packet_type = PacketType.in_status_response
				}
				0x01 {
					packet_data = PacketData(read_status_pong(mut nio))
					packet_type = PacketType.in_status_pong
				}
				else {
					return packet_data, packet_type
				}
			}
		}
		else {}
	}
	return packet_data, packet_type
}

fn write_packet_data(mut nos sio.NetOutputStream, packet Packet, state State) {
	match state {
		.handshake {
			match packet.packet_type {
				.out_handshake {
					write_handshake(mut nos, packet.data as PacketOutHandshake)
				}
				else {
					error('Something went wrong: Unknown packet')
					return
				}
			}
		}
		.status {
			match packet.packet_type {
				.out_status_request {
					write_status_request(mut nos, packet.data as PacketOutStatusRequest)
				}
				.out_status_ping {
					write_status_ping(mut nos, packet.data as PacketOutStatusPing)
				}
				else {
					error('Something went wrong: Unknown packet')
					return
				}
			}
		}
	}
	nos.flush(packet.id)
	nos.write_packet()
}

struct NoPacketData {}

// Out packets
pub struct PacketOutHandshake {
pub:
	protocol_ver int
	host         string
	port         i16
	next_state   State
}

pub struct PacketOutStatusRequest {}

pub struct PacketOutStatusPing {
pub:
	payload i64
}

// In packets
pub struct PacketInStatusResponse {
pub:
	json_response string
}

pub struct PacketInStatusPong {
pub:
	payload i64
}
