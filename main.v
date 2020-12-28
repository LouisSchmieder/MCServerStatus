module main

import net
import packet
import time
import vweb

const (
	s_port = 8080
)

struct App {
pub mut:
	vweb vweb.Context
}

fn main() {
	vweb.run<App>(s_port)
}

pub fn (mut app App) init_once() {
	app.vweb.serve_static('/main.css', './main.css', 'text/css')
}

pub fn (mut app App) init() {
}

pub fn (mut app App) index() vweb.Result {
	return $vweb.html()
}

[post]
['/status']
pub fn (mut app App) request_status() vweb.Result {
	ip := app.vweb.form['ip']
	if ip == '' {
		app.vweb.error('Empty ip address')
		return app.vweb.redirect('/')
	}
	return app.vweb.redirect('/status/$ip')
}

['/status/:ip']
pub fn (mut app App) status(ip string) vweb.Result {
	arr := ip.split(':')
	host := arr[0]
	mut port := i16(25565)
	if arr.len == 2 {
		port = arr[1].i16()
	}
	server_status := get_server_status(host, port)
	return $vweb.html()
}

pub fn (mut app App) error() vweb.Result {
	return $vweb.html()
}

fn get_server_status(host string, port i16) Status {
	sock := net.dial_tcp('$host:$port') or { return Status{} }
	mut status := packet.State.handshake

	// Handshake
	packet.write_packet(sock, packet.Packet{
		id: 0x00
		data: packet.PacketOutHandshake{
			protocol_ver: 754
			host: host
			port: port
			next_state: .status
		}
		packet_type: .out_handshake
	}, status)
	status = .status

	// Status
	packet.write_packet(sock, packet.Packet{
		id: 0x00
		data: packet.PacketOutStatusRequest{}
		packet_type: .out_status_request
	}, status)
	mut p := packet.read_packet(sock, status) or { return Status{} }
	if p.packet_type != .in_status_response {
		return Status{}
	}
	data := p.data as packet.PacketInStatusResponse
	json_data := data.json_response
	// Ping
	now := i64(time.now().unix)
	packet.write_packet(sock, packet.Packet{
		id: 0x01
		data: packet.PacketOutStatusPing{
			payload: now
		}
		packet_type: .out_status_ping
	}, status)

	p = packet.read_packet(sock, status) or { return Status{} }
	if p.packet_type != .in_status_pong {
		return Status{}
		
	}
	d1 := p.data as packet.PacketInStatusPong
	if now != d1.payload {
		return Status{}
		
	}

	mut server_status := parse_status(json_data)
	//server_status.decode_img()
	return server_status
}