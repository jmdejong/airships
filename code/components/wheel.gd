extends BaseComponent


func _ready() -> void:
	$WheelRay.ship = get_ship()

func _enter_tree() -> void:
	if $WheelRay != null:
		$WheelRay.ship = get_ship()
