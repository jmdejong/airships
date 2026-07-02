extends Node3D


@export_multiline("monospace") var ship_spec: String:
	set(val):
		ship_spec = val
		if ship != null:
			ship.queue_free()
		ship = Airship.from_json(JSON.parse_string(ship_spec))
		ship.freeze = true
		add_child(ship)

var ship: Airship
