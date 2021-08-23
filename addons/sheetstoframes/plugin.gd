tool
extends EditorPlugin


# The importer scene
var _importer: ImportDialog


func _enter_tree() -> void:
	add_tool_menu_item("Import Spritesheets", self, "_on_import_menu_clicked")
	_importer = preload("res://addons/sheetstoframes/ImportDialog.tscn").instance()
	get_editor_interface().get_editor_viewport().add_child(_importer)


# remove the singleton and the import menu button
func _exit_tree():
	remove_tool_menu_item("Import Spritesheets")
	get_editor_interface().get_editor_viewport().remove_child(_importer)
	
# Show the importer on the tool menu
func _on_import_menu_clicked(_ud):
	_importer.start_import()
