extends RefCounted
## EcoLabirinto V7 — uma fonte para cores da interface e dos cinco biomas.
const SHADOW: Color = Color("#111816")
const MOSS: Color = Color("#3a5a40")
const LEAF: Color = Color("#588157")
const EARTH: Color = Color("#382b22")
const CLAY: Color = Color("#5c473e")
const SAGE: Color = Color("#a3b18a")
const IVORY: Color = Color("#dad7cd")
const OCHRE: Color = Color("#dda15e")
const EMBER: Color = Color("#bc6c25")
# Contraste controlado e identidade própria para cada bioma.
const BIOME_COLORS: Array = [
	[Color("#304b39"), Color("#3a5a40"), Color("#588157"), Color("#111816"), Color("#a3b18a")],
	[Color("#62543a"), Color("#706047"), Color("#90784d"), Color("#332c24"), Color("#a9976b")],
	[Color("#36594f"), Color("#426459"), Color("#638479"), Color("#182a29"), Color("#8aa99a")],
	[Color("#2b5146"), Color("#3c6150"), Color("#56816a"), Color("#11221e"), Color("#91ab91")],
	[Color("#52362d"), Color("#654236"), Color("#7a5440"), Color("#211a18"), Color("#bc6c25")]
]
