class_name UI
extends Node

const MOUSE_SENSITIVITY: float = 0.003
@export var build: Build = null
@onready var move_joystick: TouchJoystick = %MoveJoystick
signal press
signal move_view(delta: Vector2)

enum MouseMode {Unfocused, Play, SelectBuild, Build, Remove, Help}

var mouse_mode: MouseMode = MouseMode.Unfocused:
	set(value):
		mouse_mode = value
		if value == MouseMode.Unfocused or value == MouseMode.SelectBuild or value == MouseMode.Help:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		%BuildTab.visible = mouse_mode == MouseMode.SelectBuild
		%HelpMenu.visible = mouse_mode == MouseMode.Help
		build.show_preview(mouse_mode == MouseMode.Build)
		if value == MouseMode.Remove:
			%CrosshairTexture.texture = preload("res://textures/ui/break.png")
		else:
			%CrosshairTexture.texture = preload("res://textures/ui/crosshair.png")

func set_info_text(text: String) -> void:
	%Info.text = text

func show_tooltip(target: Node) -> void:
	if target != null and target.has_method("mouseover_description") and mouse_mode == MouseMode.Play:
		%Tooltip.text = target.mouseover_description()
		%Tooltip.visible = true
	else:
		%Tooltip.visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag and event.index != %UI.move_joystick.touch_index:
		move_view.emit(-event.relative / get_window().size.y)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		move_view.emit(event.relative * MOUSE_SENSITIVITY)

func _unhandled_input(_event: InputEvent):
	
	if Input.is_action_just_pressed("toggle_build"):
		if mouse_mode == MouseMode.SelectBuild:
			mouse_mode = MouseMode.Play
		else:
			mouse_mode = MouseMode.SelectBuild
	
	if mouse_mode == MouseMode.Build and Input.is_action_just_released("rotate_left") or Input.is_action_just_released("rotate_right"):
		var d: int = int(Input.is_action_just_released("rotate_left")) - int(Input.is_action_just_released("rotate_right"))
		if Input.is_action_pressed("rotate_roll"):
			build.roll_rotation_mode += d
		elif Input.is_action_pressed("rotate_pitch"):
			build.pitch_rotation_mode += d
		else:
			build.yaw_rotation_mode += d
	
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("escape"):
		mouse_mode = MouseMode.Unfocused
	if Input.is_action_just_pressed("click"):
		click()
	if Input.is_action_just_pressed("cancel_click"):
		mouse_mode = MouseMode.Play
	if Input.is_action_just_pressed("switch_render"):
		var vp := get_viewport()
		vp.debug_draw = (vp.debug_draw + 1) % 6 as Viewport.DebugDraw
	if Input.is_action_just_pressed("toggle_help"):
		toggle_help()


func toggle_help() -> void:
	if mouse_mode == MouseMode.Help:
		mouse_mode = MouseMode.Play
	else:
		mouse_mode = MouseMode.Help

func click() -> void:
	if mouse_mode == MouseMode.Play:
		press.emit()
	elif mouse_mode == MouseMode.Build:
		build.try_build()
	elif mouse_mode == MouseMode.Remove:
		build.try_remove()
	else:
		mouse_mode = MouseMode.Play

func enable_touch() -> void:
	mouse_mode = MouseMode.Play

func _on_build_tab_select_build(component: ComponentBlueprint) -> void:
	mouse_mode = MouseMode.Build
	build.select_build(component)

func _on_build_tab_select_remove() -> void:
	mouse_mode = MouseMode.Remove
