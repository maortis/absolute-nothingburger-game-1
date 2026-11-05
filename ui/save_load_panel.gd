extends Control
## Save/Load window with 3 slots. open("load") from the start menu, open("save") in-game.

signal closed

var mode := "load"
var _confirm_delete := -1

@onready var title: Label = %Title
@onready var hint: Label = %Hint
@onready var slots: VBoxContainer = %Slots
@onready var back_button: Button = %BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	back_button.pressed.connect(close)


func open(new_mode: String, hint_text: String = "") -> void:
	mode = new_mode
	title.text = "Save Game" if mode == "save" else "Load Game"
	hint.text = hint_text
	hint.visible = hint_text != ""
	_confirm_delete = -1
	_rebuild()
	visible = true
	var first := slots.get_child(0).get_child(0) as Button
	if first.disabled:
		back_button.grab_focus()
	else:
		first.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func _rebuild() -> void:
	for c in slots.get_children():
		slots.remove_child(c)
		c.queue_free()
	for i in SaveManager.SLOT_COUNT:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var b := Button.new()
		b.theme_type_variation = &"SlotButton"
		b.text = SaveManager.slot_label(i)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(460, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = mode == "load" and not SaveManager.has_save(i)
		b.pressed.connect(_on_slot.bind(i))
		row.add_child(b)
		var del := Button.new()
		del.theme_type_variation = &"SlotButton"
		del.text = "Sure?" if _confirm_delete == i else "Delete"
		del.disabled = not SaveManager.has_save(i)
		del.pressed.connect(_on_delete.bind(i))
		row.add_child(del)
		slots.add_child(row)


func _on_slot(i: int) -> void:
	if mode == "load":
		SaveManager.load_slot(i)
	else:
		if SaveManager.save_to_slot(i):
			hint.text = "Saved to slot %d!" % (i + 1)
		else:
			hint.text = "Couldn't save (no player found)."
		hint.visible = true
		_rebuild()
		(slots.get_child(i).get_child(0) as Button).grab_focus.call_deferred()


func _on_delete(i: int) -> void:
	if _confirm_delete != i:
		_confirm_delete = i   # first press asks "Sure?"
	else:
		SaveManager.delete_slot(i)
		_confirm_delete = -1
	_rebuild()
	(slots.get_child(i).get_child(1) as Button).grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
