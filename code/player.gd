extends CharacterBody3D

const MOUSE_SENSITIVITY: float = 0.003
const speed: float = 4
const sprint_speed: float = 40
const jump_speed: float = 10

var gravity_enabled: bool = true

enum MouseMode {Unfocused, Play, Select, Build, Remove}
var build_component: Component = null
var preview: Area3D = null

var mouse_mode: MouseMode = MouseMode.Unfocused:
	set(value):
		mouse_mode = value
		if value == MouseMode.Unfocused or value == MouseMode.Select:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		$BuildTab.visible = mouse_mode == MouseMode.Select
		%BuildPreview.visible = mouse_mode == MouseMode.Build

var build_mode: bool = false:
	set(value):
		build_mode = value
		$BuildTab.visible = build_mode
		

signal viewpoint_changed(pos: Vector3)

func adjust_direction() -> void:
	var down = get_gravity()
	if down.length_squared() == 0:
		down = Vector3(0, -1, 0)
	look_at(global_position + (quaternion * Vector3.RIGHT).cross(down).normalized(), -down.normalized())
	

func _physics_process(delta: float) -> void:
	var input_movement: Vector2 = Input.get_vector("left", "right", "forwards", "backwards")
	var s: float = speed
	if Input.is_action_pressed("sprint"):
		s = sprint_speed
	var movement: Vector3 = (Vector3(input_movement.x, 0, input_movement.y) * s)
	if gravity_enabled:
		movement.y = velocity.y - Atmosphere.gravity() * delta
		if Input.is_action_pressed("up"):
			movement.y = s
	else:
		movement.y = s * (float(Input.is_action_pressed("up")) - float(Input.is_action_pressed("down")))
	velocity = movement.rotated(Vector3(0, 1, 0), rotation.y)
	move_and_slide()
	
	try_interact()
	place_preview()
	
	viewpoint_changed.emit(position)

func _unhandled_input(event: InputEvent):
	if Input.is_action_just_pressed("toggle_gravity"):
		gravity_enabled = !gravity_enabled
	
	if Input.is_action_just_pressed("toggle_build"):
		if mouse_mode == MouseMode.Select:
			mouse_mode = MouseMode.Play
		else:
			mouse_mode = MouseMode.Select
	
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("escape"):
		mouse_mode = MouseMode.Unfocused
	if Input.is_action_just_pressed("click"):
		if mouse_mode == MouseMode.Play:
			try_press()
		elif mouse_mode == MouseMode.Build:
			try_build()
		elif mouse_mode == MouseMode.Remove:
			try_remove()
		else:
			mouse_mode = MouseMode.Play
	if Input.is_action_just_pressed("cancel_click"):
		mouse_mode = MouseMode.Play

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		$Head.rotation.x = clamp($Head.rotation.x - event.relative.y * MOUSE_SENSITIVITY, -PI/2, PI/2)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)


func try_interact() -> void:
	var collider = %EyeCast.get_collider()
	if collider != null and collider.has_method("mouseover_description") and mouse_mode == MouseMode.Play:
		%Tooltip.text = collider.mouseover_description()
		%Tooltip.visible = true
	else:
		%Tooltip.visible = false

func place_preview() -> void:
	var collider = %BuildCast.get_collider()
	if collider != null and collider.has_method("build_target") and mouse_mode == MouseMode.Build:
		%BuildPreview.global_rotation = collider.global_rotation
		var cpos: Vector3 = collider.to_local(%BuildCast.get_collision_point() + %BuildCast.get_collision_normal() * 0.24).snappedf(0.5)
		%BuildPreview.global_position = collider.to_global(cpos)
		preview.valid = !preview.has_overlapping_bodies()
	else:
		%BuildPreview.rotation = Vector3.ZERO
		%BuildPreview.position = Vector3(0, 0, -2)
		if preview and preview.valid:
			preview.valid = false
	
func try_press() -> void:
	var collider = %EyeCast.get_collider()
	if collider != null and collider.has_method("press"):
		collider.press()

func try_build() -> void:
	var collider = %BuildCast.get_collider()
	if collider != null and collider.has_method("build_target") and mouse_mode == MouseMode.Build:
		%BuildPreview.global_rotation = collider.global_rotation
		var cpos: Vector3 = collider.to_local(%BuildCast.get_collision_point() + %BuildCast.get_collision_normal() * 0.24).snappedf(0.5)
		%BuildPreview.global_position = collider.to_global(cpos)
		preview.valid = !preview.has_overlapping_bodies()
		if preview.valid:
			collider.build_component(cpos, build_component)

func try_remove() -> void:
	var collider: CollisionObject3D = %BuildCast.get_collider()
	if collider == null:
		return
	var shape: CollisionShape3D = collider.shape_owner_get_owner(collider.shape_find_owner(%BuildCast.get_collider_shape()))
	var component: Node3D = shape.get_meta("component")
	component.get_parent().remove_child(component)
	component.changed.emit()
	component.queue_free()

func _on_build_tab_select_build(component: Component) -> void:
	build_component = component
	mouse_mode = MouseMode.Build
	preview = component.preview.instantiate()
	%BuildPreview.add_child(preview)


func _on_build_tab_select_remove() -> void:
	mouse_mode = MouseMode.Remove
