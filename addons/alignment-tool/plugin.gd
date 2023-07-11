@tool
extends EditorPlugin

const Alignment2D = preload("Alignment2D.gd")
const Alignment3D = preload("Alignment3D.gd") 

var tool2d : Alignment2D
var tool3d : Alignment3D

func _enter_tree():
	if not tool2d:
		tool2d = Alignment2D.new(self)
		add_child(tool2d)
	if not tool3d:
		tool3d = Alignment3D.new(self)
		add_child(tool3d)


func _exit_tree():
	if tool2d:
		tool2d.queue_free()
		tool2d = null
	if tool3d:
		tool3d.queue_free()
		tool3d = null
