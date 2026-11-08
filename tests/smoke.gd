extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var release_tag := OS.get_environment("TINY_RITUAL_RELEASE_TAG")
	var expected_tag := "v%s" % ProjectSettings.get_setting("application/config/version")
	if not release_tag.is_empty() and release_tag != expected_tag:
		_fail("Release tag %s does not match app version %s." % [release_tag, expected_tag])
		return
	if ProjectSettings.get_setting("application/config/name") != "Tiny Ritual":
		_fail("The project name must be Tiny Ritual.")
		return
	var presets := ConfigFile.new()
	if presets.load("res://export_presets.cfg") != OK:
		_fail("Export presets could not load.")
		return
	var expected_platforms := ["Windows Desktop", "Web", "Android", "iOS"]
	var expected_paths := [
		"build/windows/TinyRitual.exe", "build/web/index.html",
		"build/android/TinyRitual.apk", "build/ios/TinyRitual.zip"
	]
	for index in expected_platforms.size():
		if presets.get_value("preset.%d" % index, "platform", "") != expected_platforms[index]:
			_fail("Missing export platform: %s" % expected_platforms[index])
			return
		if presets.get_value("preset.%d" % index, "export_path", "") != expected_paths[index]:
			_fail("Incorrect export path for %s" % expected_platforms[index])
			return
	if presets.get_value("preset.1.options", "variant/thread_support", true):
		_fail("Web export must remain single-threaded for simple static hosting.")
		return
	var scene: PackedScene = load("res://scenes/main.tscn")
	if scene == null:
		_fail("Main scene could not load.")
		return
	var main: Control = scene.instantiate()
	root.add_child(main)
	await process_frame
	var title_label: Label = main.get_node("Margin/Center/Content/Title")
	if title_label.text != "Tiny Ritual":
		_fail("The scene title must match the project name.")
		return
	var target_button: Button = main.get_node("%Target")
	var count_label: Label = main.get_node("%Count")
	var reset_button: Button = main.get_node("%Reset")
	if count_label.text != "0" or not reset_button.disabled:
		_fail("Initial counter state is incorrect.")
		return
	target_button.pressed.emit()
	target_button.pressed.emit()
	if count_label.text != "2" or reset_button.disabled:
		_fail("Button presses did not update the counter.")
		return
	reset_button.pressed.emit()
	if count_label.text != "0" or not reset_button.disabled:
		_fail("Reset did not restore the initial state.")
		return
	main.queue_free()
	await process_frame
	print("PASS: Tiny Ritual branding, four exports, single-threaded web, scene, input, and reset.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)