extends CanvasLayer
## Pause menu. Esc opens/closes it. Lets you save, load, or go back to the start menu.

@onready var root: Control = $Root
@onready var resume_button: Button = %ResumeButton
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var menu_button: Button = %MenuButton
@onready var panel = $Root/SaveLoadPanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	resume_button.pressed.connect(close)
	save_button.pressed.connect(_open_panel.bind("save"))
	load_button.pressed.connect(_open_panel.bind("load"))
	menu_button.pressed.connect(SaveManager.go_to_menu)
	panel.closed.connect(_on_panel_closed)


func _open_panel(mode: String) -> void:
	$Root/Center.visible = false
	panel.open(mode)


func _on_panel_closed() -> void:
	$Root/Center.visible = true
	resume_button.grab_focus()


func open() -> void:
	root.visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	root.visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if panel.visible:
		return   # the save/load panel handles its own Esc
	get_viewport().set_input_as_handled()
	if root.visible:
		close()
	else:
		open()
