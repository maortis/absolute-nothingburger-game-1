extends Button
## Text-only menu button (Inmost style): shows "›  text  ‹" when hovered/focused.

var _base := ""


func _ready() -> void:
	_base = text
	focus_entered.connect(_on_highlight.bind(true))
	focus_exited.connect(_on_highlight.bind(false))
	mouse_entered.connect(grab_focus)   # mouse and keyboard share one highlight


func _on_highlight(on: bool) -> void:
	text = ("›  %s  ‹" % _base) if on else _base
