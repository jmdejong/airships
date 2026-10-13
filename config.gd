@tool
extends Node

const config_path: String = "user://config.cfg"

enum Perf {FAST = 1, PRETTY = 9}

var config_file = ConfigFile.new()
var performance: Perf = default_performance()
signal performance_changed

const saved_properties: Array[StringName] = ["performance"]

static func default_performance() -> Perf:
	if OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return Perf.FAST
	else:
		return Perf.PRETTY

func configure_from_file() -> void:
	for property: StringName in saved_properties:
		set(property, config_file.get_value("general", property, get(property)))

func _ready() -> void:
	Measure.start("load_config")
	var err: Error = config_file.load(config_path)
	if err == Error.ERR_FILE_NOT_FOUND:
		print("no config file found; using platform defaults")
		save()
		return
	elif err != Error.OK:
		printerr("Unable to load config file: ", error_string(err), "; using platform defaults")
		return
	else:
		print("config loaded sucessfully")
		configure_from_file()
	Measure.finish("load_config")
	prints("performance config", performance)

func set_performance(perf: Perf) -> void:
	if perf == performance:
		return
	performance = perf
	save()
	performance_changed.emit()

func save() -> void:
	for property: StringName in saved_properties:
		config_file.set_value("general", property, get(property))
	config_file.save(config_path)
