extends RefCounted
## Catálogo de memes ampliável só adicionando arquivos PNG nesta pasta.
const BUILTIN_MEMES = ["sapo_chapeu", "capivara_oculos", "tatu_dourado", "sapo_azul"]

static func meme_names() -> Array[String]:
	var found: Array[String] = []
	for name in BUILTIN_MEMES:
		found.append(str(name))
	var filenames: PackedStringArray = DirAccess.get_files_at("res://Assets/Animals/Memes")
	for filename in filenames:
		if filename.to_lower().ends_with(".png"):
			var key: String = filename.get_basename()
			if not found.has(key):
				found.append(key)
	found.sort()
	return found
