@tool
extends EditorPlugin

var _bottom_container:Control
var _toolbar_container:Control
var _docks:Array[TabContainer]

var minify_alt_icon_names = {
	"FileSystem": "Filesystem",
	"Scene":"PlayScene",
	"Inspector":"Edit",
	"Import": "ResourcePreloader",
	"Debugger": "Debug", 
	"Audio": "AudioStream",
	"Shader Editor": "Shader",
	"EditorDebugger": "GodotMonochrome",
	"TODO": "CheckBox",
	"Signal Visualizer": "Signals",
	"ItchDeploy": "ArrowUp",
	"Instances": "Instance",
	"Search Results": "Search",
}

func _enter_tree():
	await get_tree().process_frame
	await get_tree().process_frame
	_minify_toolbar()
	_minify_bottom_container()
	_minify_all_tabs()


func _minify_bottom_container():
	if not _bottom_container:
		var temp = add_control_to_bottom_panel(Control.new(), "TEMP")
		_bottom_container = temp.get_parent()
		remove_control_from_bottom_panel(temp)
		temp.queue_free()
	_minify_buttons(_bottom_container, false)



func _minify_toolbar():
	if not _toolbar_container:
		var temp = Control.new()
		add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, temp)
		_toolbar_container = temp.get_parent()
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, temp)
		temp.queue_free()
		
	_minify_buttons(_toolbar_container, true)

func _on_dock_child_added(child):
	_minify_tabs(child.get_parent())

func _minify_all_tabs():
	if not _docks:
		_docks = []	
		for dock_slot in range(EditorPlugin.DOCK_SLOT_MAX):
			var temp = Control.new()
			add_control_to_dock(dock_slot, temp)
			var _tab_bar = temp.get_parent() as TabContainer
			_docks.append(_tab_bar)
			_tab_bar.child_entered_tree.connect(_on_dock_child_added, CONNECT_DEFERRED|CONNECT_REFERENCE_COUNTED)

			remove_control_from_docks(temp)
			temp.queue_free.call_deferred()

		for _tab_bar in _docks:
			_minify_tabs(_tab_bar)
	
				
func _find_child_of_type(node:Node, child_type, include_internal:bool=false, recurse:bool=false):
	for i in node.get_child_count(include_internal):
		var child = node.get_child(i,include_internal)
		if is_instance_of(child, child_type):
			return child
	if recurse:
		for i in node.get_child_count(include_internal):
			var child = node.get_child(i,include_internal)
			var result =_find_child_of_type(child, child_type, include_internal, true)
			if result:
				return result;


func _exit_tree():
	_deminify_buttons(_toolbar_container)
	_deminify_buttons(_bottom_container)
	pass

func _get_icon(icon_name:String):
	if icon_name in minify_alt_icon_names:
		icon_name = minify_alt_icon_names[icon_name]

	var _icon_path = "res://addons/godot_editor_mini/icons/%s.png" % icon_name;
	var _gui = EditorInterface.get_base_control()
	return load(_icon_path) if ResourceLoader.exists(_icon_path) \
			 else _gui.get_theme_icon(icon_name, "EditorIcons") if _gui.has_theme_icon(icon_name, "EditorIcons") \
			 else null

func _minify_text(text:String):
	if text.length() >= 3:
		return {
			"text" : text.substr(0, 3),
			"icon" : _get_icon(text)
		}
	

func _minify_tabs(tab_bar:TabContainer):
	if not is_instance_valid(tab_bar): return
	for _tab in tab_bar.get_tab_count():
		var _tab_title = tab_bar.get_tab_title(_tab)
		var _minify = _minify_text(_tab_title)
		if _minify:
			if _minify.icon:
				tab_bar.set_tab_icon(_tab, _minify.icon)
				tab_bar.set_tab_title(_tab, "")
			else:
				tab_bar.set_tab_title(_tab, _minify.text)


func _minify_buttons(container, collapse_to_icon):
	if is_instance_valid(container):
		for _child in container.get_children():
			if not _child is Control: continue
			_minify_buttons(_child, collapse_to_icon)
			if not _child is Button: continue
			var _minify = _minify_text(_child.text)
			if _minify:
				if _child.icon:
					_child.tooltip_text = _child.text
					_child.text = ""
				else:	
					_child.tooltip_text = _child.text
					_child.text = _minify.text if not _minify.icon else ""
					_child.icon = _minify.icon


func _deminify_buttons(container):
	if is_instance_valid(container):
		for child in container.get_children():
			if not child is Control: continue
			_deminify_buttons(child)
			if child is Button and child.text.length() <= 3 and not child.tooltip_text.is_empty():
				child.text = child.tooltip_text
				child.tooltip_text = ""
