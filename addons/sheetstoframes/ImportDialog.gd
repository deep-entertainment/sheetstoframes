tool
extends Control
class_name ImportDialog


const ImportSettings = preload("res://addons/sheetstoframes/ImportSettings.gd")

const ImportSettingsPreset = preload(\
	"res://addons/sheetstoframes/ImportSettingsPreset.gd"\
)


var _select_spritesheet_dialog: EditorFileDialog = null


var _select_spriteframes_dialog: EditorFileDialog = null


var _select_preset_dialog: EditorFileDialog = null


var _selected_files: PoolStringArray = []


var _current_import_options: Dictionary = {}


func start_import():
	if _select_spritesheet_dialog == null:
		_select_spritesheet_dialog = EditorFileDialog.new()
		_select_spritesheet_dialog.mode = EditorFileDialog.MODE_OPEN_FILES
		_select_spritesheet_dialog.clear_filters()
		_select_spritesheet_dialog.add_filter("*.png")
		_select_spritesheet_dialog.dialog_text = \
				tr("Please select a spritesheet")
		_select_spritesheet_dialog.window_title = tr("Select a spritesheet")
		add_child(_select_spritesheet_dialog)
		_select_spritesheet_dialog.connect(
			"files_selected", 
			self, 
			"_on_import_files_selected"
		)
	
	_select_spritesheet_dialog.popup_centered_ratio(0.75)
	

func import_spritesheets(
	sprite_sheets: PoolStringArray, 
	sprite_frames: String, 
	sprite_options: Dictionary
):
	var _overwritten: bool = false
	var _frames: SpriteFrames
	if ResourceLoader.exists(sprite_frames):
		_overwritten = true
		# SpriteFrames already exist. Load and clean it
		_frames = ResourceLoader.load(sprite_frames, "SpriteFrames")
		for animation in _frames.get_animation_names():
			_frames.remove_animation(animation)
	else:
		_frames = SpriteFrames.new()
	
	for sheet in sprite_sheets:
		var options = sprite_options[sheet.get_file()]
		var _sheet_texture = ResourceLoader.load(sheet) as StreamTexture
		var _width = _sheet_texture.get_width()
		var _height = _sheet_texture.get_height()
		
		var _region_width = ceil(_width / options.columns)
		var _region_height = ceil(_height / options.rows)
		
		var _sheet_name = sheet.get_file().trim_suffix(
			".%s" % sheet.get_extension()
		)
		_frames.add_animation(_sheet_name)
		_frames.set_animation_speed(_sheet_name, options.fps)
		
		for row in range(0, options.rows):
			for col in range (0, options.columns):
				if _frames.get_frame_count(_sheet_name) >= options.max_frames:
					break
				var _texture = AtlasTexture.new()
				_texture.atlas = _sheet_texture
				_texture.region = Rect2(
					col * _region_width,
					row * _region_height,
					_region_width,
					_region_height
				)
				_frames.add_frame(_sheet_name, _texture)
	
	ResourceSaver.save(sprite_frames, _frames)
	
	$ImportCompleted.dialog_text = "The spritesheet was imported successfully."

	if _overwritten:
		$ImportCompleted.dialog_text += "\n\n" +\
				"If you have already opened the SpriteFrames ressource" +\
				"in the inspector, please restart Godot to see the changes."

	$ImportCompleted.popup_centered_minsize()


func _on_import_files_selected(files: PoolStringArray):
	_selected_files = files
	var _grid_container = $ImportSettingsDialog/VBoxContainer/\
			MarginContainer/ScrollContainer/GridContainer
	for child in _grid_container.get_children():
		if not child.is_in_group("_headers"):
			_grid_container.remove_child(child)
	var _first_node = null
	for file in _selected_files:
		var _node_name = _create_node_name(file)
		var _sheet_label = Label.new()
		_sheet_label.name = _node_name
		_sheet_label.text = file.get_file()
		_grid_container.add_child(_sheet_label)
		
		var _sheet_cols = SpinBox.new()
		_sheet_cols.name = "%s_Cols" % _node_name
		_sheet_cols.value = 5
		_sheet_cols.allow_greater = true
		_grid_container.add_child(_sheet_cols)
		_sheet_cols.get_line_edit().connect(
			"focus_entered", 
			self, 
			"_select_all", 
			[_sheet_cols.get_line_edit()]
		)
		_sheet_cols.get_line_edit().connect(
			"gui_input", 
			self, 
			"_lineedit_gui_input", 
			[_sheet_cols.get_line_edit()]
		)
		
		if _first_node == null:
			_first_node = _sheet_cols.get_line_edit()
		
		var _sheet_rows = SpinBox.new()
		_sheet_rows.name = "%s_Rows" % _node_name
		_sheet_rows.value = 5
		_sheet_rows.allow_greater = true
		_grid_container.add_child(_sheet_rows)
		_sheet_rows.get_line_edit().connect(
			"focus_entered", 
			self, 
			"_select_all", 
			[_sheet_rows.get_line_edit()]
		)
		_sheet_rows.get_line_edit().connect(
			"gui_input", 
			self, 
			"_lineedit_gui_input", 
			[_sheet_rows.get_line_edit()]
		)
		
		var _sheet_max_frames = SpinBox.new()
		_sheet_max_frames.name = "%s_MaxFrames" % _node_name
		_sheet_max_frames.value = 25
		_sheet_max_frames.allow_greater = true
		_grid_container.add_child(_sheet_max_frames)
		_sheet_max_frames.get_line_edit().connect(
			"focus_entered", 
			self, 
			"_select_all", 
			[_sheet_max_frames.get_line_edit()]
		)
		_sheet_max_frames.get_line_edit().connect(
			"gui_input", 
			self, 
			"_lineedit_gui_input", 
			[_sheet_max_frames.get_line_edit()]
		)
		
		var _sheet_max_fps = SpinBox.new()
		_sheet_max_fps.name = "%s_FPS" % _node_name
		_sheet_max_fps.value = 5
		_sheet_max_fps.step = 0.1
		_sheet_max_fps.allow_greater = true
		_grid_container.add_child(_sheet_max_fps)
		_sheet_max_fps.get_line_edit().connect(
			"focus_entered", 
			self, 
			"_select_all", 
			[_sheet_max_fps.get_line_edit()]
		)
		_sheet_max_fps.get_line_edit().connect(
			"gui_input", 
			self, 
			"_lineedit_gui_input", 
			[_sheet_max_fps.get_line_edit()]
		)
		
		_sheet_cols.connect(
			"value_changed", 
			self, 
			"_on_cols_rows_changed", 
			[_sheet_cols, _sheet_rows, _sheet_max_frames]
		)
		
		_sheet_rows.connect(
			"value_changed", 
			self, 
			"_on_cols_rows_changed", 
			[_sheet_cols, _sheet_rows, _sheet_max_frames]
		)
		
		
	$ImportSettingsDialog.popup_centered_minsize()
	_first_node.grab_focus()


func _on_ImportDialog_CancelButton_pressed() -> void:
	_selected_files = []
	$ImportSettingsDialog.hide()


func _on_ImportButton_pressed() -> void:
	_current_import_options = _get_options()
	
	$ImportSettingsDialog.hide()
	
	if _select_spriteframes_dialog == null:
		_select_spriteframes_dialog = EditorFileDialog.new()
		_select_spriteframes_dialog.mode = EditorFileDialog.MODE_SAVE_FILE
		_select_spriteframes_dialog.clear_filters()
		_select_spriteframes_dialog.add_filter("*.tres")
		_select_spriteframes_dialog.dialog_text = \
				tr("Please choose the SpriteFrames resource to save")
		_select_spriteframes_dialog.window_title = \
				"Choose a SpriteFrames resource"
		add_child(_select_spriteframes_dialog)
		_select_spriteframes_dialog.connect(
			"file_selected",
			self,
			"_on_resource_file_selected"
		)
	
	_select_spriteframes_dialog.popup_centered_ratio(0.75)
	

func _on_resource_file_selected(file: String):
	import_spritesheets(_selected_files, file, _current_import_options)


func _create_node_name(file: String):
	return "%s_%s" % [
		file.get_file().trim_suffix(
			".%s" % file.get_extension()
		).to_upper(),
		file.get_extension()
	]


func _on_cols_rows_changed(
	_v,
	cols: SpinBox, 
	rows: SpinBox, 
	max_frames: SpinBox
):
	max_frames.value = cols.value * rows.value


func _on_LoadPresetButton_pressed() -> void:
	var dialog = _get_preset_dialog()
	dialog.window_title = tr("Load preset")
	dialog.dialog_text = tr("Please select a preset resource")
	dialog.clear_filters()
	dialog.add_filter("*.tres")
	dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	dialog.popup_centered_ratio(0.75)
	var _preset_filename = yield(dialog, "file_selected")
	var _preset = ResourceLoader.load(
		_preset_filename, 
		"ImportSettingsPreset", 
		true
	) as ImportSettingsPreset
	var _grid_container = $ImportSettingsDialog/VBoxContainer/\
			MarginContainer/ScrollContainer/GridContainer
	for file in _preset.sheets:
		var _node_name = _create_node_name(file)
		if _grid_container.has_node(_node_name):
			_grid_container.get_node("%s_Cols" % _node_name).value = \
					_preset.sheets[file].columns
			_grid_container.get_node("%s_Rows" % _node_name).value = \
					_preset.sheets[file].rows
			_grid_container.get_node("%s_MaxFrames" % _node_name).value = \
					_preset.sheets[file].max_frames
			_grid_container.get_node("%s_FPS" % _node_name).value = \
					_preset.sheets[file].fps


func _on_SavePresetButton_pressed() -> void:
	var dialog = _get_preset_dialog()
	dialog.window_title = tr("Save preset")
	dialog.dialog_text = tr("Please select a preset resource")
	dialog.clear_filters()
	dialog.add_filter("*.tres")
	dialog.mode = EditorFileDialog.MODE_SAVE_FILE
	dialog.popup_centered_ratio(0.75)
	var _preset_filename = yield(dialog, "file_selected")
	var _preset = ImportSettingsPreset.new()
	_preset.sheets = _get_options()
	ResourceSaver.save(_preset_filename, _preset)
	
	
	
func _get_preset_dialog() -> EditorFileDialog:
	if _select_preset_dialog == null:
		_select_preset_dialog = EditorFileDialog.new()
		add_child(_select_preset_dialog)
	return _select_preset_dialog
	


func _get_options() -> Dictionary:
	var options: Dictionary = {}
	for file in _selected_files:
		var _filename = file.get_file()
		var _node_name = _create_node_name(file)
		options[_filename] = ImportSettings.new()
		options[_filename].columns = int(
			$ImportSettingsDialog/VBoxContainer/MarginContainer\
				/ScrollContainer/GridContainer.get_node(
					"%s_Cols" % _node_name
				).value
		)
		options[_filename].rows = int(
			$ImportSettingsDialog/VBoxContainer/MarginContainer\
				/ScrollContainer/GridContainer.get_node(
					"%s_Rows" % _node_name
				).value
		)
		options[_filename].max_frames = int(
			$ImportSettingsDialog/VBoxContainer/MarginContainer\
				/ScrollContainer/GridContainer.get_node(
					"%s_MaxFrames" % _node_name
				).value
		)
		options[_filename].fps = int(
			$ImportSettingsDialog/VBoxContainer/MarginContainer\
				/ScrollContainer/GridContainer.get_node(
					"%s_FPS" % _node_name
				).value
		)
	return options


func _select_all(line: LineEdit) -> void:
	line.select_all()


func _lineedit_gui_input(event: InputEvent, line: LineEdit) -> void:
	if event is InputEventMouseButton and not event.is_pressed():
		_select_all(line)
