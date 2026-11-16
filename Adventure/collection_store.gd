extends RefCounted
## Bestiário persistente e independente dos recordes/speedruns.
const PATH: String = "user://ecolabirinto_bestiario.json"

static func load_collection() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var file: FileAccess = FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

static func discover(species: String, biome: String, seed: String, secret: bool = false) -> bool:
	var discovered: Dictionary = load_collection()
	if discovered.has(species):
		return false
	discovered[species] = {"biome": biome, "seed": seed, "secret": secret,
		"discovered": Time.get_datetime_string_from_system()}
	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(discovered, "  "))
	return true
