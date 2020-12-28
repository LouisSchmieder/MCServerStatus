module packet

enum State {
	handshake
	status
}

pub fn (state State) to_number() int {
	return if state == .handshake {
		0
	} else {
		1
	}
}
