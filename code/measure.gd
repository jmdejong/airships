extends Node


var measurements: Dictionary[String, float] = {}

func start(id: String) -> void:
	measurements[id] = now()
	prints("%5.3f" % measurements[id], "starting", id)

func finish(id: String) -> void:
	var n: float = now()
	if not measurements.has(id):
		prints("%5.3f" % n, "finishing", id, "without starting")
	prints("%5.3f" % n, id, "took", "%5.3f" % (n - measurements[id]))

func mark(text: String) -> void:
	prints("%5.3f" % now(), text)

func now() -> float:
	return float(Time.get_ticks_msec()) / 1000
