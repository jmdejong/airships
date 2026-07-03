class_name UI
extends Node

@export var build: Build = null
@onready var move_joystick: TouchJoystick = %MoveJoystick
signal press
signal move_view(delta: Vector2)

enum UiMode {Unfocused, Active, SelectBuild, Help}
enum CursorMode {Play, Build, Remove}

var ui_mode: UiMode = UiMode.Unfocused:
	set(value):
		ui_mode = value
		if value != UiMode.Active:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif not $TouchUi.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		%BuildTab.visible = ui_mode == UiMode.SelectBuild
		%HelpMenu.visible = ui_mode == UiMode.Help
		if ui_mode != UiMode.Help:
			get_viewport().gui_release_focus()

var cursor_mode: CursorMode = CursorMode.Play:
	set(value):
		cursor_mode = value
		build.show_preview(cursor_mode == CursorMode.Build)
		if value == CursorMode.Remove:
			%CrosshairTexture.texture = preload("res://textures/ui/break.png")
		else:
			%CrosshairTexture.texture = preload("res://textures/ui/crosshair.png")

#var mouse_mode: MouseMode = MouseMode.Unfocused:
	#set(value):
		#mouse_mode = value
		#if value == MouseMode.Unfocused or value == MouseMode.SelectBuild or value == MouseMode.Help:
			#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#elif not $TouchUi.visible:
			#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		#%BuildTab.visible = mouse_mode == MouseMode.SelectBuild
		#%HelpMenu.visible = mouse_mode == MouseMode.Help
		#build.show_preview(mouse_mode == MouseMode.Build)
		#if value == MouseMode.Remove:
			#%CrosshairTexture.texture = preload("res://textures/ui/break.png")
		#else:
			#%CrosshairTexture.texture = preload("res://textures/ui/crosshair.png")
		#if mouse_mode != MouseMode.Help:
			#get_viewport().gui_release_focus()

func set_info_text(text: String) -> void:
	%Info.text = text

func show_tooltip(target: Node, player: Player) -> void:
	if ui_mode == UiMode.Active and cursor_mode == CursorMode.Play and target != null and target.has_method("mouseover_description"):
		%Tooltip.text = target.mouseover_description(player)
		%Tooltip.visible = %Tooltip.text != ""
	else:
		%Tooltip.visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag and event.index != move_joystick.touch_index:
		move_view.emit(-event.relative / get_window().size.y)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		move_view.emit(event.relative * Global.MOUSE_SENSITIVITY)
	if Input.is_action_just_pressed("toggle_build"):
		if ui_mode == UiMode.SelectBuild:
			ui_mode = UiMode.Active
		else:
			ui_mode = UiMode.SelectBuild

func _unhandled_input(_event: InputEvent):
	
	if cursor_mode == CursorMode.Build and Input.is_action_just_released("rotate_left") or Input.is_action_just_released("rotate_right"):
		var d: int = int(Input.is_action_just_released("rotate_left")) - int(Input.is_action_just_released("rotate_right"))
		if Input.is_action_pressed("rotate_roll"):
			build.roll_rotation_mode += d
		elif Input.is_action_pressed("rotate_pitch"):
			build.pitch_rotation_mode += d
		else:
			build.yaw_rotation_mode += d
	
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("escape"):
		ui_mode = UiMode.Unfocused
	if Input.is_action_just_pressed("click"):
		click()
	if Input.is_action_just_pressed("cancel_click"):
		ui_mode = UiMode.Active
		cursor_mode = CursorMode.Play
	if Input.is_action_just_pressed("switch_render"):
		var vp := get_viewport()
		vp.debug_draw = (vp.debug_draw + 1) % 6 as Viewport.DebugDraw
	if Input.is_action_just_pressed("toggle_help"):
		toggle_help()


func toggle_help() -> void:
	if ui_mode == UiMode.Help:
		ui_mode = UiMode.Active
	else:
		ui_mode = UiMode.Help

func click() -> void:
	if ui_mode == UiMode.Active:
		if cursor_mode == CursorMode.Play:
			press.emit()
		elif cursor_mode == CursorMode.Build:
			build.try_build()
		elif cursor_mode == CursorMode.Remove:
			build.try_remove()
	else:
		ui_mode = UiMode.Active
		cursor_mode = CursorMode.Play

func enable_touch() -> void:
	ui_mode = UiMode.Active

func _on_build_tab_select_build(component: ComponentBlueprint) -> void:
	ui_mode = UiMode.Active
	cursor_mode = CursorMode.Build
	build.select_build(component)

func _on_build_tab_select_remove() -> void:
	ui_mode = UiMode.Active
	cursor_mode = CursorMode.Remove

func set_lifeline_attached(attached: bool) -> void:
	if attached:
		%LifelineStatus.texture = preload("res://art/ui/hook_attached.svg")
	else:
		%LifelineStatus.texture = preload("res://art/ui/hook_detached.svg")
