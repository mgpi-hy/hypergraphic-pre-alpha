class_name ThemeManager
extends RefCounted

## Global brutalist terminal theme. Color constants, font management,
## high contrast mode, panel/button factories, region grid generation.

# --- Constants ---
const COLOR_VOID := Color("#050508")
const COLOR_PANEL := Color("#0A0A0E")
const COLOR_TEXT_MAIN := Color("#E2E2E8")
const COLOR_TEXT_DIM := Color("#4A4A55")
const COLOR_ALERT := Color("#FF1E40")
const COLOR_SUCCESS := Color("#00F090")
const COLOR_SHIELD := Color("#00D0FF")
const COLOR_WARNING := Color("#FFB300")
const COLOR_GOLD := Color("#FFD54F")
const COLOR_INSULATION := Color("#CE93D8")

const FONT_H1: int = 16
const FONT_BODY: int = 14
const FONT_MICRO: int = 12

const COLOR_TEXT_MAIN_HC := Color("#FFFFFF")
const COLOR_TEXT_DIM_HC := Color("#8A8A99")
const COLOR_PANEL_HC := Color("#0E0E14")

# Glyphs ordered: light/sparse first, dense/heavy last (used by _pick_glyph)
const REGION_GLYPHS: Dictionary = {
	"temporal lobe": ["·", "∼", "∿", "≈", "≋", "∽", "〜", "⏦", "⌇", "∮"],
	"broca's area": ["·", "▹", "▸", "▷", "◇", "◊", "⟐", "⊳", "◁", "⊲"],
	"parietal lobe": ["·", "⊡", "⊘", "⊙", "⊕", "⊗", "⊞", "⊟", "⊠", "⊛"],
	"wernicke's area": ["·", "⁕", "⁑", "†", "‡", "※", "§", "¶", "⁂", "⁘"],
	"limbic system": ["·", "◌", "○", "◍", "◑", "◐", "◎", "◒", "◓", "◉"],
	"brainstem": ["·", "⬡", "⬥", "◆", "▲", "✕", "✖", "⚠", "⚡", "☠"],
}

const REGION_COLORS: Dictionary = {
	"temporal lobe": Color("#00F090"),
	"broca's area": Color("#00D0FF"),
	"parietal lobe": Color("#CE93D8"),
	"wernicke's area": Color("#FFD54F"),
	"limbic system": Color("#FF8A65"),
	"brainstem": Color("#FF1E40"),
}

# Palettes: [deep/dark, mid-dark, primary, bright, highlight]
const REGION_PALETTES: Dictionary = {
	"temporal lobe": [Color("#004030"), Color("#008050"), Color("#00F090"), Color("#40FFB0"), Color("#B0FFE0")],
	"broca's area": [Color("#003060"), Color("#0060AA"), Color("#00D0FF"), Color("#60E8FF"), Color("#B0F4FF")],
	"parietal lobe": [Color("#3A1848"), Color("#7840A0"), Color("#CE93D8"), Color("#E0B0E8"), Color("#F0D0F8")],
	"wernicke's area": [Color("#4A3800"), Color("#AA8820"), Color("#FFD54F"), Color("#FFE888"), Color("#FFF4CC")],
	"limbic system": [Color("#4A1800"), Color("#AA4020"), Color("#FF8A65"), Color("#FFAA88"), Color("#FFDDCC")],
	"brainstem": [Color("#400008"), Color("#880010"), Color("#FF1E40"), Color("#FF5060"), Color("#FF90A0")],
}

const REGION_ALIASES: Dictionary = {
	"amygdala": "limbic system",
	"hippocampus": "limbic system",
	"insular cortex": "parietal lobe",
	"angular gyrus": "parietal lobe",
	"arcuate fasciculus": "broca's area",
	"cingulate cortex": "wernicke's area",
	"prefrontal cortex": "broca's area",
	"corpus callosum": "brainstem",
	"frontal lobe": "broca's area",
	"cerebellum": "brainstem",
}

# --- Static Variables ---
static var _high_contrast: bool = false
static var _mono_font: Font = null
static var _grid_cache: Dictionary = {}  # "region|font_size|alpha" -> bbcode string

# --- Public Methods ---

static func set_high_contrast(enabled: bool) -> void:
	_high_contrast = enabled


static func is_high_contrast() -> bool:
	return _high_contrast


static func get_text_main() -> Color:
	if _high_contrast:
		return COLOR_TEXT_MAIN_HC
	return COLOR_TEXT_MAIN


static func get_text_dim() -> Color:
	if _high_contrast:
		return COLOR_TEXT_DIM_HC
	return COLOR_TEXT_DIM


static func get_border_width() -> int:
	if _high_contrast:
		return 2
	return 1


static func get_mono_font() -> Font:
	if _mono_font == null:
		_mono_font = load("res://fonts/CascadiaMono.ttf")
	return _mono_font


static func apply_mono_font(node: Control, size: int = FONT_BODY) -> void:
	var font: Font = get_mono_font()
	if font == null:
		return
	node.add_theme_font_override("font", font)
	node.add_theme_font_size_override("font_size", size)


static func apply_mono_font_rtl(node: RichTextLabel, size: int = FONT_BODY) -> void:
	var font: Font = get_mono_font()
	if font == null:
		return
	node.add_theme_font_override("normal_font", font)
	node.add_theme_font_size_override("normal_font_size", size)
	node.add_theme_font_override("bold_font", font)
	node.add_theme_font_size_override("bold_font_size", size)


static func apply_panel_style(
	node: PanelContainer,
	bg: Color,
	border_color: Color,
	border_width: int = 1,
) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(0)
	style.set_border_width_all(border_width)
	style.border_color = border_color
	node.add_theme_stylebox_override("panel", style)


static func apply_glow_text(label: Control, text_color: Color) -> void:
	label.add_theme_color_override("font_color", text_color)
	var shadow: Color = text_color
	shadow.a = 0.3
	label.add_theme_color_override("font_shadow_color", shadow)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 1)


static func apply_button_style(btn: Button, accent: Color) -> void:
	## Apply full normal/hover/pressed button styling with consistent terminal aesthetic.
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_PANEL
	normal.border_color = accent
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(0)
	normal.content_margin_left = 16.0
	normal.content_margin_right = 16.0
	normal.content_margin_top = 8.0
	normal.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = accent.lightened(0.3)
	hover.bg_color = COLOR_PANEL.lightened(0.05)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = accent
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_color_override("font_hover_color", accent.lightened(0.3))
	btn.add_theme_color_override("font_pressed_color", COLOR_VOID)


# --- StyleBox Factories ---

static func make_morpheme_card_style(pos_color: Color, rarity: String = "common") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.set_corner_radius_all(0)
	var border_width: int = 1
	var border_color: Color = pos_color
	match rarity:
		"uncommon":
			border_width = 2
		"rare":
			border_width = 1
			style.expand_margin_left = 2.0
			style.expand_margin_top = 2.0
			style.expand_margin_right = 2.0
			style.expand_margin_bottom = 2.0
			style.shadow_color = Color("#C0C0C0", 0.8)
			style.shadow_size = 3
		"mythic":
			border_width = 1
			style.expand_margin_left = 2.0
			style.expand_margin_top = 2.0
			style.expand_margin_right = 2.0
			style.expand_margin_bottom = 2.0
			style.shadow_color = Color("#FFD700", 0.8)
			style.shadow_size = 3
		"legendary":
			border_width = 1
			style.expand_margin_left = 3.0
			style.expand_margin_top = 3.0
			style.expand_margin_right = 3.0
			style.expand_margin_bottom = 3.0
			style.shadow_color = Color("#CE93D8", 0.9)
			style.shadow_size = 4
	style.set_border_width_all(border_width)
	style.border_color = border_color
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


static func make_empty_slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_corner_radius_all(0)
	style.set_border_width_all(2)
	style.border_color = COLOR_TEXT_DIM
	return style


static func make_filled_slot_style(pos_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL.lightened(0.05)
	style.set_corner_radius_all(0)
	style.set_border_width_all(2)
	style.border_color = pos_color
	return style


static func make_combat_log_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.set_corner_radius_all(0)
	style.border_width_left = 0
	style.border_width_top = 1
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.border_color = COLOR_TEXT_DIM
	return style


# --- Region Grid ---

static func build_unicode_grid(
	parent: Control,
	region: String,
	font_size: int = 4,
	alpha: float = 0.04,
) -> RichTextLabel:
	var reg: String = region.to_lower()

	var grid := RichTextLabel.new()
	grid.bbcode_enabled = true
	grid.scroll_active = false
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.z_index = -1
	apply_mono_font_rtl(grid, font_size)

	var cache_key: String = "%s|%d|%.3f" % [reg, font_size, alpha]
	var bbcode: String
	if _grid_cache.has(cache_key):
		bbcode = _grid_cache[cache_key]
	else:
		bbcode = _generate_grid_bbcode(reg, alpha)
		_grid_cache[cache_key] = bbcode

	grid.clear()
	grid.append_text(bbcode)
	parent.add_child(grid)
	return grid


# --- Scene-wide Application ---

static func apply_theme_to_scene(root: Control) -> void:
	if root is PanelContainer:
		apply_panel_style(root, COLOR_VOID, COLOR_VOID, 0)
	else:
		var bg := StyleBoxFlat.new()
		bg.bg_color = COLOR_VOID
		root.add_theme_stylebox_override("panel", bg)

	root.add_theme_constant_override("margin_left", 16)
	root.add_theme_constant_override("margin_top", 16)
	root.add_theme_constant_override("margin_right", 16)
	root.add_theme_constant_override("margin_bottom", 16)

	_apply_recursive(root)


# --- Private Methods ---

static func _apply_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is VBoxContainer or child is HBoxContainer:
			child.add_theme_constant_override("separation", 8)
		if child is Label:
			apply_glow_text(child, COLOR_TEXT_MAIN)
		if child.get_child_count() > 0:
			_apply_recursive(child)


static func _generate_grid_bbcode(reg: String, alpha: float) -> String:
	reg = reg.to_lower()
	reg = REGION_ALIASES.get(reg, reg)
	var glyphs: Array = REGION_GLYPHS.get(reg, REGION_GLYPHS["temporal lobe"])
	var color: Color = REGION_COLORS.get(reg, COLOR_TEXT_DIM)
	var cols: int = 60
	var rows: int = 45
	var palette: Array = REGION_PALETTES.get(reg, [color])

	# Pre-seed a deterministic noise table for organic variation
	var noise_table: Array = []
	noise_table.resize(256)
	var seed_rng := RandomNumberGenerator.new()
	seed_rng.seed = hash(reg) & 0x7FFFFFFF
	for i: int in 256:
		noise_table[i] = seed_rng.randf_range(0.65, 1.0)

	var bbcode: String = ""
	for row: int in rows:
		var line: String = ""
		var space_run: int = 0
		for col: int in cols:
			var cell_alpha: float = _pattern_alpha(reg, row, col, rows, cols, alpha)
			if cell_alpha < 0.003:
				space_run += 1
				continue
			# Flush space run
			if space_run > 0:
				line += " ".repeat(space_run)
				space_run = 0
			# Organic jitter from noise table (deterministic per cell)
			var noise_idx: int = ((row * 71 + col * 37) & 0xFF)
			cell_alpha *= noise_table[noise_idx]
			var pal_color: Color = _pick_palette_color(reg, palette, row, col, rows, cols)
			var col_hex: String = pal_color.to_html(false)
			var a_hex: String = "%02x" % clampi(int(cell_alpha * 255.0), 0, 255)
			var glyph: String = _pick_glyph(reg, glyphs, row, col)
			line += "[color=#%s%s]%s[/color]" % [col_hex, a_hex, glyph]
		if space_run > 0:
			line += " ".repeat(space_run)
		bbcode += line + "\n"
	return bbcode


static func _pattern_alpha(
	reg: String,
	r: int,
	c: int,
	rows: int,
	cols: int,
	base: float,
) -> float:
	var nr: float = float(r) / float(rows)
	var nc: float = float(c) / float(cols)
	var cx: float = nc - 0.5
	var cy: float = nr - 0.5

	match reg:
		"temporal lobe":
			var wave1: float = sin(float(c) * 0.25 + float(r) * 0.08) * 0.5 + 0.5
			var wave2: float = sin(float(c) * 0.15 - float(r) * 0.12 + 2.0) * 0.5 + 0.5
			var wave3: float = sin(float(c) * 0.08 + float(r) * 0.25 + 4.5) * 0.3 + 0.35
			var interference: float = wave1 * wave2 * 1.5 + wave3 * 0.4
			var vert_fade: float = 1.0 - nr * 0.6
			var h_fade: float = 1.0 - pow(abs(cx) * 1.8, 2.0)
			h_fade = maxf(h_fade, 0.05)
			return base * interference * vert_fade * h_fade

		"broca's area":
			var diag1: float = fmod(float(r * 2 + c), 14.0)
			var is_on_stream1: bool = diag1 < 1.5
			var diag2: float = fmod(float(r + c * 3), 18.0)
			var is_on_stream2: bool = diag2 < 1.0
			var is_break1: bool = fmod(float(c), 22.0) < 3.0
			var is_break2: bool = fmod(float(r), 16.0) < 2.0
			if is_on_stream1 and is_break1:
				is_on_stream1 = false
			if is_on_stream2 and is_break2:
				is_on_stream2 = false
			var focus_dx: float = nc - 0.35
			var focus_dy: float = nr - 0.45
			var focus: float = exp(-(focus_dx * focus_dx + focus_dy * focus_dy) * 4.0)
			var grad: float = 0.4 + focus * 0.8
			if is_on_stream1:
				return base * grad * 1.8
			if is_on_stream2:
				return base * grad * 1.0
			return base * 0.06 * grad

		"parietal lobe":
			var is_on_h: bool = (r % 8) < 1
			var is_on_v: bool = (c % 10) < 1
			var is_on_h2: bool = (r % 4) == 2
			var is_on_v2: bool = (c % 5) == 3
			var dist: float = sqrt(cx * cx + cy * cy)
			var radial: float = 1.0 - clampf(dist * 1.6, 0.0, 0.7)
			var is_at_node: bool = is_on_h and is_on_v
			var is_at_sub_node: bool = is_on_h2 and is_on_v2
			if is_at_node:
				return base * 3.5 * radial
			if is_on_h or is_on_v:
				return base * 1.3 * radial
			if is_at_sub_node:
				return base * 0.8 * radial
			if is_on_h2 or is_on_v2:
				return base * 0.2 * radial
			return base * 0.03

		"wernicke's area":
			var clusters: Array = [
				Vector2(0.15, 0.2), Vector2(0.45, 0.15), Vector2(0.75, 0.25),
				Vector2(0.1, 0.55), Vector2(0.4, 0.5), Vector2(0.7, 0.55),
				Vector2(0.2, 0.8), Vector2(0.55, 0.78), Vector2(0.85, 0.75),
				Vector2(0.3, 0.35), Vector2(0.6, 0.4),
			]
			var connections: Array[Vector2i] = [
				Vector2i(0, 1), Vector2i(1, 2), Vector2i(0, 3), Vector2i(1, 4),
				Vector2i(2, 5), Vector2i(3, 4), Vector2i(4, 5), Vector2i(3, 6),
				Vector2i(4, 7), Vector2i(5, 8), Vector2i(6, 7), Vector2i(7, 8),
				Vector2i(0, 9), Vector2i(9, 4), Vector2i(9, 10), Vector2i(10, 2),
				Vector2i(10, 5),
			]
			var best_dist: float = 1.0
			for center: Variant in clusters:
				var dx: float = nc - center.x
				var dy: float = nr - center.y
				var d: float = sqrt(dx * dx + dy * dy)
				if d < best_dist:
					best_dist = d
			var cluster_glow: float = exp(-best_dist * best_dist * 50.0) * 2.5
			var filament: float = 0.0
			for conn: Vector2i in connections:
				var a: Vector2 = clusters[conn.x]
				var b: Vector2 = clusters[conn.y]
				var seg: float = _dist_to_segment(nc, nr, a.x, a.y, b.x, b.y)
				if seg < 0.025:
					var line_val: float = (1.0 - seg / 0.025) * 0.8
					if line_val > filament:
						filament = line_val
			return base * (0.03 + cluster_glow + filament)

		"limbic system":
			var origin_x: float = -0.08
			var origin_y: float = 0.05
			var dx: float = cx - origin_x
			var dy: float = cy - origin_y
			var dist: float = sqrt(dx * dx + dy * dy)
			var angle: float = atan2(dy, dx)
			var wobble: float = sin(angle * 3.0) * 0.02 + sin(angle * 7.0) * 0.01
			var eff_dist: float = dist + wobble
			var ring_phase: float = log(maxf(eff_dist, 0.001) * 10.0 + 1.0) * 12.0
			var ring: float = pow(sin(ring_phase) * 0.5 + 0.5, 1.5)
			var fade: float = 1.0 - clampf(dist * 1.5 - 0.1, 0.0, 1.0)
			fade = maxf(fade, 0.05)
			return base * ring * fade * 2.2

		"brainstem":
			var core_x: float = 0.0
			var core_y: float = 0.15
			var dx: float = cx - core_x
			var dy: float = cy - core_y
			var dist: float = sqrt(dx * dx + dy * dy)
			var angle: float = atan2(dy, dx)
			var spoke: float = pow(abs(sin(angle * 4.0)), 8.0)
			var ring: float = pow(sin(dist * 35.0) * 0.5 + 0.5, 2.0)
			var core_glow: float = exp(-dist * dist * 12.0) * 1.5
			var combined: float = spoke * 0.8 + ring * 0.4 + core_glow
			var depth: float = 0.3 + nr * 0.7
			return base * combined * depth

		_:
			return base * 0.3


static func _dist_to_segment(
	px: float,
	py: float,
	ax: float,
	ay: float,
	bx: float,
	by: float,
) -> float:
	var abx: float = bx - ax
	var aby: float = by - ay
	var apx: float = px - ax
	var apy: float = py - ay
	var ab_sq: float = abx * abx + aby * aby
	if ab_sq < 0.0001:
		return sqrt(apx * apx + apy * apy)
	var t: float = clampf((apx * abx + apy * aby) / ab_sq, 0.0, 1.0)
	var proj_x: float = ax + t * abx - px
	var proj_y: float = ay + t * aby - py
	return sqrt(proj_x * proj_x + proj_y * proj_y)


static func _pick_glyph(reg: String, glyphs: Array, r: int, c: int) -> String:
	var gs: int = glyphs.size()
	if gs == 0:
		return " "
	match reg:
		"temporal lobe":
			var wave: float = sin(float(c) * 0.25 + float(r) * 0.08) * 0.5 + 0.5
			var idx: int = clampi(int(wave * float(gs - 1) * 0.7) + 1, 1, gs - 1)
			return glyphs[idx]
		"broca's area":
			var idx: int = 1 + ((r + c) % (gs - 1))
			return glyphs[idx]
		"parietal lobe":
			var is_on_h: bool = (r % 8) < 1
			var is_on_v: bool = (c % 10) < 1
			if is_on_h and is_on_v:
				var idx: int = ((r / 8) + (c / 10)) % (gs - 3) + (gs - 3)
				return glyphs[clampi(idx, 0, gs - 1)]
			if is_on_h or is_on_v:
				var idx: int = 2 + ((r + c) % 3)
				return glyphs[clampi(idx, 0, gs - 1)]
			return glyphs[clampi(1, 0, gs - 1)]
		"wernicke's area":
			var wn_c: float = float(c) / 110.0
			var wn_r: float = float(r) / 90.0
			var clusters: Array = [
				Vector2(0.15, 0.2), Vector2(0.45, 0.15), Vector2(0.75, 0.25),
				Vector2(0.1, 0.55), Vector2(0.4, 0.5), Vector2(0.7, 0.55),
				Vector2(0.2, 0.8), Vector2(0.55, 0.78), Vector2(0.85, 0.75),
				Vector2(0.3, 0.35), Vector2(0.6, 0.4),
			]
			var best_dist: float = 1.0
			for center: Variant in clusters:
				var dx: float = wn_c - center.x
				var dy: float = wn_r - center.y
				var d: float = sqrt(dx * dx + dy * dy)
				if d < best_dist:
					best_dist = d
			if best_dist < 0.06:
				var idx: int = gs - 1 - clampi(int(best_dist * float(gs) * 8.0), 0, gs / 2)
				return glyphs[clampi(idx, gs / 2, gs - 1)]
			var idx: int = 1 + ((r * 3 + c * 7) % 3)
			return glyphs[clampi(idx, 0, gs / 2)]
		"limbic system":
			var dx: float = float(c) / 110.0 - 0.5 - (-0.08)
			var dy: float = float(r) / 90.0 - 0.5 - 0.05
			var dist: float = sqrt(dx * dx + dy * dy)
			var ring_band: int = int(dist * 25.0) % 3
			if ring_band == 0:
				var idx: int = gs - 1 - ((r + c) % 3)
				return glyphs[clampi(idx, gs / 2, gs - 1)]
			var idx: int = 1 + ((r + c) % (gs / 2))
			return glyphs[clampi(idx, 1, gs / 2)]
		"brainstem":
			var bs_nc: float = float(c) / 110.0
			var bs_nr: float = float(r) / 90.0
			var dx: float = bs_nc - 0.5
			var dy: float = bs_nr - 0.65
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist < 0.15:
				var idx: int = gs - 1 - clampi(int(dist * float(gs) * 3.0), 0, 2)
				return glyphs[clampi(idx, gs - 3, gs - 1)]
			if dist < 0.35:
				var idx: int = gs / 2 + ((r + c) % (gs / 2))
				return glyphs[clampi(idx, 0, gs - 1)]
			var idx: int = 1 + ((r * 3 + c) % 3)
			return glyphs[clampi(idx, 1, gs / 2)]
		_:
			return glyphs[(r * 7 + c * 13) % gs]


static func _pick_palette_color(
	reg: String,
	palette: Array,
	r: int,
	c: int,
	rows: int,
	cols: int,
) -> Color:
	var nr: float = float(r) / float(rows)
	var nc: float = float(c) / float(cols)
	var ps: int = palette.size()
	if ps == 0:
		return COLOR_TEXT_DIM

	match reg:
		"temporal lobe":
			var wave: float = sin(float(c) * 0.25 + float(r) * 0.08) * 0.5 + 0.5
			var vert_boost: float = (1.0 - nr) * 0.3
			var t: float = clampf(wave + vert_boost, 0.0, 1.0)
			var idx: int = clampi(int(t * float(ps - 1)), 0, ps - 1)
			return palette[idx]

		"broca's area":
			var focus_dx: float = nc - 0.35
			var focus_dy: float = nr - 0.45
			var focus_dist: float = sqrt(focus_dx * focus_dx + focus_dy * focus_dy)
			if focus_dist < 0.2:
				var idx: int = clampi(ps - 1 - int(focus_dist * float(ps) * 3.0), 2, ps - 1)
				return palette[idx]
			var diag_norm: float = clampf((nc + nr) * 0.5, 0.0, 1.0)
			var idx: int = clampi(int(diag_norm * float(ps - 1)), 0, ps - 2)
			return palette[idx]

		"parietal lobe":
			var is_on_h: bool = (r % 8) < 1
			var is_on_v: bool = (c % 10) < 1
			if is_on_h and is_on_v:
				return palette[ps - 1]
			if is_on_h or is_on_v:
				return palette[2]
			var zone: int = (int(nr * 3.0) + int(nc * 3.0)) % ps
			return palette[clampi(zone, 0, 1)]

		"wernicke's area":
			var clusters: Array = [
				Vector2(0.15, 0.2), Vector2(0.45, 0.15), Vector2(0.75, 0.25),
				Vector2(0.1, 0.55), Vector2(0.4, 0.5), Vector2(0.7, 0.55),
				Vector2(0.2, 0.8), Vector2(0.55, 0.78), Vector2(0.85, 0.75),
				Vector2(0.3, 0.35), Vector2(0.6, 0.4),
			]
			var best_dist: float = 1.0
			for center: Variant in clusters:
				var dx: float = nc - center.x
				var dy: float = nr - center.y
				var d: float = sqrt(dx * dx + dy * dy)
				if d < best_dist:
					best_dist = d
			if best_dist < 0.04:
				return palette[ps - 1]
			if best_dist < 0.08:
				return palette[ps - 2]
			if best_dist < 0.15:
				return palette[2]
			var idx: int = clampi(int(best_dist * 4.0), 0, 1)
			return palette[idx]

		"limbic system":
			var origin_x: float = -0.08
			var origin_y: float = 0.05
			var dx: float = (nc - 0.5) - origin_x
			var dy: float = (nr - 0.5) - origin_y
			var dist: float = sqrt(dx * dx + dy * dy)
			var heat: float = 1.0 - clampf(dist * 2.0, 0.0, 1.0)
			var ring_band: int = int(dist * 25.0) % 2
			var base_idx: int = clampi(int(heat * float(ps - 1)), 0, ps - 1)
			var idx: int = clampi(base_idx + ring_band, 0, ps - 1)
			return palette[idx]

		"brainstem":
			var dx: float = nc - 0.5
			var dy: float = nr - 0.65
			var dist: float = sqrt(dx * dx + dy * dy)
			var angle: float = atan2(dy, dx)
			var spoke: float = pow(abs(sin(angle * 4.0)), 8.0)
			if dist < 0.1:
				return palette[ps - 1]
			if dist < 0.2:
				return palette[clampi(ps - 2, 0, ps - 1)]
			if spoke > 0.5:
				return palette[2]
			var ring_band: int = int(dist * 35.0) % 2
			return palette[ring_band]

		_:
			return palette[(r * 7 + c * 13) % ps]
