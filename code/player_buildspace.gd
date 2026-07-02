extends Camera3D

var speed = 5
const sprint_multiplier: float = 5
var view_movement: Vector2 = Vector2.ZERO
var build: ComponentBlueprint = null

enum MouseMode {Build, Remove, View, Select}
var mode: MouseMode = MouseMode.Select:
	set(value):
		mode = value
		if value == MouseMode.Select:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif not %TouchUi.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		%Build.show_preview(mode == MouseMode.Build)

func _physics_process(delta: float) -> void:
	
	if view_movement != Vector2.ZERO:
		rotation.x = clamp(rotation.x - view_movement.y, -PI/2, PI/2)
		rotate_y(-view_movement.x)
		view_movement = Vector2.ZERO
	
	var input_movement: Vector2 = (Input.get_vector("left", "right", "forwards", "backwards") + %MoveJoystick.touch_value()).limit_length()
	var y_movement: float = Input.get_axis("down", "up")
	var movement: Vector3 = (Vector3(input_movement.x, y_movement, input_movement.y) * speed) \
		.rotated(Vector3(0, 1, 0), rotation.y)
	
	if Input.is_action_pressed("sprint"):
		movement *= sprint_multiplier
		
	position += movement * delta


func _on_ui_move_view(delta: Vector2) -> void:
	view_movement += delta

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag and event.index != %MoveJoystick.touch_index:
		view_movement += -event.relative / get_window().size.y
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		view_movement += event.relative * Global.MOUSE_SENSITIVITY
	if Input.is_action_just_pressed("toggle_build"):
		if mode == MouseMode.Select:
			mode = MouseMode.View
		else:
			mode = MouseMode.Select

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("click"):
		click()


func click() -> void:
	if mode == MouseMode.Build:
		%Build.try_build()
	elif mode == MouseMode.Remove:
		$Build.try_remove()
	else:
		mode = MouseMode.View


func _on_build_tab_select_build(blueprint: ComponentBlueprint) -> void:
	mode = MouseMode.Build
	%Build.select_build(blueprint)


func _on_build_tab_select_remove() -> void:
	mode = MouseMode.Remove
