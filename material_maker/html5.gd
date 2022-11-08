# Most of that code is stolen from Pixelorama

extends Node


signal in_focus
signal file_loaded(file_name, file_type, file_data)


func _ready() -> void:
	if OS.get_name() == "HTML5" and OS.has_feature("JavaScript"):
		JavaScript.eval(
			"""
				var fileData;
				var fileType;
				var fileName;
				var canceled;
				function loadFile() {
					canceled = true;
					var input = document.createElement('INPUT');
					input.setAttribute("type", "file");
					input.click();
					input.addEventListener('change', event => {
						if (event.target.files.length > 0) {
							canceled = false;
						}
						var file = event.target.files[0];
						var reader = new FileReader();
						fileType = file.type;
						fileName = file.name;
						reader.readAsArrayBuffer(file);
						reader.onloadend = function (evt) {
							if (evt.target.readyState == FileReader.DONE) {
								fileData = evt.target.result;
							}
						}
					});
				}
			""",
			true
		)

func _notification(notification: int) -> void:
	if notification == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		emit_signal("in_focus")

func load_file(load_directly : bool = true):
	if OS.get_name() != "HTML5" or !OS.has_feature("JavaScript"):
		return

	JavaScript.eval("loadFile();", true)

	yield(self, "in_focus")  # Wait until JS prompt is closed

	yield(get_tree().create_timer(0.5), "timeout")  # Give some time for async JS data load

	if JavaScript.eval("canceled;", true):  # If File Dialog closed w/o file
		return

	# Use data from png data
	var file_data
	while true:
		file_data = JavaScript.eval("fileData;", true)
		if file_data != null:
			break
		yield(get_tree().create_timer(1.0), "timeout")  # Need more time to load data

	var file_name = JavaScript.eval("fileName;", true)
	var file_type = JavaScript.eval("fileType;", true)

	emit_signal("file_loaded", file_name, file_type, file_data.get_string_from_ascii())
