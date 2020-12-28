module main

import json
import encoding.base64

struct Status {
	version Version
	description Description
mut:
	players Players
	favicon string
}

struct Version {
	name string
	protocol int
}

struct Players {
	max int
	online int
mut:
	sample []User
}

struct User {
	name string
mut:
	id string
}

struct Description {
	text string
}

fn parse_status(input string) Status {
	mut status := json.decode(Status, input) or { Status{} }
	status.trim_ids()
	return status
}

fn (mut status Status) trim_ids() {
	for i, user in status.players.sample {
		status.players.sample[i].id = user.id.replace('-', '')
	}
}

fn (mut status Status) decode_img() {
	img_data := status.favicon[22..]
	res := base64.decode(img_data)
	status.favicon = res
}