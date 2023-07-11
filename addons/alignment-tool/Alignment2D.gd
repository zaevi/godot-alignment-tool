@tool
extends Node

var interface : EditorInterface
var selection : EditorSelection
var plugin : EditorPlugin

var tool_btn

###

func _init(_plugin : EditorPlugin):
	self.plugin = _plugin
	interface = plugin.get_editor_interface()
	selection = interface.get_selection()

	tool_btn = preload("AlignToolButton.tscn").instantiate()
	tool_btn.setup_2d()
	tool_btn.align_btn_toggled.connect(_align_btn_toggled)
	tool_btn.align_pressed.connect(_align_pressed)
	plugin.add_control_to_container(plugin.CONTAINER_CANVAS_EDITOR_MENU, tool_btn)
	
	tool_btn.disabled = true
	selection.selection_changed.connect(_selection_changed)
	_selection_changed()


func _exit_tree():
	selection.selection_changed.disconnect(_selection_changed)
	plugin.remove_control_from_container(plugin.CONTAINER_CANVAS_EDITOR_MENU, tool_btn)
	tool_btn.queue_free()

###

var current_align_data = {}

func _selection_changed():
	tool_btn.disabled = get_selected_nodes_2d().size() < 2


func _align_btn_toggled(toggled):
	if !toggled:
		current_align_data = null
		return

	var nodes_data = []
	var sr = null
	for node in get_selected_nodes_2d():
		if node is CanvasItem:
			var d = {
				node = node,
				original_position = node.global_position,
				global_rect = node.get_global_transform() * node.call("_edit_get_rect")
			}
			nodes_data.append(d)
			sr = sr.merge(d.global_rect) if sr else d.global_rect

	current_align_data = {
		selection_rect = sr,
		nodes_data = nodes_data
	}

###

func _align_pressed(align_type):
	var ur = plugin.get_undo_redo()
	ur.create_action("Align")
	make_align_action(ur, current_align_data, align_type)
	ur.commit_action()


func make_align_action(ur : EditorUndoRedoManager, align_data, align_type):
	var axis = 0 if align_type < 4 else 1 # x y
	var align = align_type % 4 # min center max space

	var sr = align_data.selection_rect
	var align_value = get_rect_align_value(sr, align)[axis]

	if align < 3: # min center max
		for data in align_data.nodes_data:
			var gp = data.node.global_position
			ur.add_undo_property(data.node, "global_position", gp)
			gp[axis] = (data.original_position - get_rect_align_value(data.global_rect, align))[axis] + align_value
			ur.add_do_property(data.node, "global_position", gp)
	else: # space
		var nodes_data = align_data.nodes_data.duplicate()
		nodes_data.sort_custom(func(a,b): return a.global_rect.position[axis] < b.global_rect.position[axis])
		var axis_size = nodes_data.reduce(func(accum, data): return accum + data.global_rect.size[axis], 0)
		var space = (sr.size[axis] - axis_size) / (nodes_data.size() - 1)
		for data in nodes_data:
			var gp = data.node.global_position
			ur.add_undo_property(data.node, "global_position", gp)
			gp[axis] = (data.original_position - data.global_rect.position)[axis] + align_value
			ur.add_do_property(data.node, "global_position", gp)
			align_value += data.global_rect.size[axis] + space

###

func get_rect_align_value(rect : Rect2, align):
	match align:
		0: return rect.position
		1: return rect.get_center()
		2: return rect.end
		3: return rect.position


func get_selected_nodes_2d():
	var selected = selection.get_transformable_selected_nodes()
	var nodes = []
	for node in selected:
		if node is CanvasItem:
			nodes.append(node)
	return nodes
