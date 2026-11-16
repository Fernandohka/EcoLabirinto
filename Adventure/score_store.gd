extends RefCounted
## Placar local no user:// (não exige conexão ou cadastro).
const PATH: String = "user://ecolabirinto_placar.json"

static func load_records() -> Array:
	if not FileAccess.file_exists(PATH):
		return []
	var f: FileAccess = FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		return parsed
	return []

static func save_record(record: Dictionary) -> void:
	var records: Array = load_records()
	records.append(record)
	# Mantém quantidade razoável mesmo depois de várias demonstrações.
	if records.size() > 250:
		records.remove_at(0)
	var f: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(records, "  "))

static func format_time(seconds: float) -> String:
	var whole: int = maxi(0, int(seconds))
	var min_part: int = whole / 60
	return "%02d:%02d" % [min_part, whole % 60]
