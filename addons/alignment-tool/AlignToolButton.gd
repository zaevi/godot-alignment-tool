@tool
extends Button

signal align_btn_toggled(toggled)
signal align_pressed(align_type)

enum ALIGN {
	X_MIN = 0, X_CENTER, X_MAX, X_SPACE,
	Y_MIN = 4, Y_CENTER, Y_MAX, Y_SPACE,
	Z_MIN = 8, Z_CENTER, Z_MAX, Z_SPACE,
}


@onready var popup = $Popup


func _ready():
	toggled.connect(_on_toggled)
	popup.visibility_changed.connect(_on_popup_visibility_changed)
	for btn in popup.find_children("*", "Button"):
		btn.pressed.connect(_btn_pressed.bind(ALIGN[btn.name]))


func setup_2d():
	var label_x : Label = $Popup/VBox/AlignX/Header/Label
	var label_y : Label = $Popup/VBox/AlignY/Header/Label
	var vbox_align_z : VBoxContainer = $Popup/VBox/AlignZ
	var btn_y_min : Button = $Popup/VBox/AlignY/HBox/Y_MIN
	var btn_y_max : Button = $Popup/VBox/AlignY/HBox/Y_MAX
	
	label_x.text = "Horizontal"
	label_y.text = "Vertical"
	vbox_align_z.hide()
	btn_y_min.icon = preload("./icons/VTop.svg")
	btn_y_max.icon = preload("./icons/VBottom.svg")


func _btn_pressed(align_type):
	align_pressed.emit(align_type)


func _on_toggled(button_pressed):
	if not button_pressed:
		return
	var size = self.size * get_viewport().get_canvas_transform().get_scale()

	popup.size = Vector2(size.x, 0)
	var gp = get_screen_position()
	gp.y += size.y
	if is_layout_rtl():
		gp.x += size.x - popup.size.x
	popup.position = gp
	popup.popup()


func _on_popup_visibility_changed():
	align_btn_toggled.emit(popup.visible)
	button_pressed = popup.visible
