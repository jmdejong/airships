extends ColorRect

var lo: float = -0.5
var hi: float = 1
var val: float = -.3

func set_(val: float, lo: float, hi: float) -> void:
	self.val = val
	self.lo = lo
	self.hi = hi
	queue_redraw()

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var area: Rect2 = get_viewport_rect()
	var s: float = area.size.y / (hi - lo)
	var zero: float = -lo * s
	var vy: float = (val - lo) * s
	if val > 0:
		draw_rect(Rect2(0, zero, area.size.x, vy - zero), Color.RED)
	else:
		draw_rect(Rect2(0, vy, area.size.x, zero - vy), Color.RED)
	draw_line(Vector2(0, zero), Vector2(area.size.x, zero), Color.BLACK, 3)
	draw_rect(get_viewport_rect(), Color.BLACK, false, 4.0)
