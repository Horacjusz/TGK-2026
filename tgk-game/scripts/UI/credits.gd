extends UI

@onready var credits_label: RichTextLabel = $Credits/CreditsLabel

const CREDITS_PATH := "res://assets/credits/credits.json"

func _ready() -> void:
	load_credits()


func load_credits() -> void:
	var file := FileAccess.open(CREDITS_PATH, FileAccess.READ)

	if file == null:
		push_error("Could not open credits file: " + CREDITS_PATH)
		return

	var text := file.get_as_text()
	var json := JSON.new()
	var result := json.parse(text)

	if result != OK:
		push_error("Could not parse credits JSON: " + json.get_error_message())
		return

	var data: Dictionary = json.data

	credits_label.bbcode_enabled = true
	credits_label.text = build_credits_bbcode(data)


func build_credits_bbcode(data: Dictionary) -> String:
	var output := ""

	var title: String = data.get("title", "Credits")

	output += "[center]"
	output += "[font_size=42][b][color=#ffffff]" + escape_bbcode(title) + "[/color][/b][/font_size]"
	output += "\n\n"

	var sections: Array = data.get("sections", [])

	for section in sections:
		var section_name: String = section.get("name", "Unknown")
		var color: String = section.get("color", "#ffffff")
		var people: Array = section.get("people", [])

		output += "[font_size=28][b][color=" + color + "]"
		output += escape_bbcode(section_name)
		output += "[/color][/b][/font_size]\n"

		for person in people:
			output += "[font_size=22][color=#dddddd]"
			output += escape_bbcode(str(person))
			output += "[/color][/font_size]\n"

		output += "\n"

	output += "[/center]"

	return output


func escape_bbcode(value: String) -> String:
	return value \
		.replace("[", "\\[") \
		.replace("]", "\\]")


func _on_return_pressed() -> void:
	return_to_parent_menu()
	pass # Replace with function body.
