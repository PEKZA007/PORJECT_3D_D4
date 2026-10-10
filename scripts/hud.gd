extends CanvasLayer
## Presentation only. Text, colors and margins can be changed without gameplay code.
signal primary_pressed
signal title_requested
signal restart_pressed
signal debug_requested(id: int)
signal volume_changed(value: float)
signal music_volume_changed(value: float)
signal sensitivity_changed(value: float)
signal collection_requested
signal language_changed
signal ending_replay_requested(id: String)
const INK := Color("0b0d0c")
const PAPER := Color("e0ddd3")
const MUTED := Color("9c9e97")
const ACCENT := Color("b74e48")
var menu_content: VBoxContainer
var settings_page: VBoxContainer
var settings_button: Button
var title_button: Button
var volume_slider: HSlider
var music_volume_slider: HSlider
var sensitivity_slider: HSlider
var fullscreen: CheckButton
var settings_origin: String = "title"
var preferences := ConfigFile.new()
var final_room: int = 7
var note_rules: String = ""
var rules_label: Label
var rules_heading: Label
var screen: Control
var overlay: ColorRect
var fade: ColorRect
var room_label: Label
var bell_label: Label
var prompt: Label
var notice: Label
var crosshair: Label
var menu_title: Label
var menu_subtitle: Label
var menu_body: Label
var primary: Button
var restart: Button
var debug_panel: PanelContainer
var debug_picker: OptionButton
var notice_remaining: float = 0.0
var mode: String = "title"
var ambience: ColorRect
var menu_tween: Tween
var result_body: String = ""
var note_page: CenterContainer
var note_text: Label
var note_close: Button
var mode_picker: OptionButton
var mode_description: Label
var record_label: Label
var copy_stats: Button
var hint_label: Label
var endless_status: Label
var share_text := ""
var collection_page: VBoxContainer
var collection_list: VBoxContainer
var collection_summary: Label
var collection_origin := "title"
var collection_button: Button
var collection_back: Button
var resolution_picker: OptionButton
var brightness_slider: HSlider
var brightness_filter: ColorRect
var brightness_material: ShaderMaterial
var settings_path := "user://settings.cfg"
var editor_embedded := OS.get_cmdline_args().has("--wid") or OS.get_cmdline_args().has("--embedded")
var credits_page: VBoxContainer
var credits_button: Button
var credits_back: Button
var credits_origin := "title"
var language_picker: OptionButton
var stamina_panel: HBoxContainer
var stamina_bar: ProgressBar
var stamina_active := false
const TEAM_CREDITS := [
	["นาย กฤตภัค สร้อยแก้ว", "683380281-1", "Level Design & Anomaly Design"],
	["นางสาวธวัลรัตน์ นิยมพงษ์", "683380081-9", "Story Design & Project Manager"],
	["นายปีติภัทร มีคำนิล", "683380306-1", "Programmer & Tester"]
]
const RESOLUTIONS := [Vector2i(960, 600), Vector2i(1152, 720), Vector2i(1280, 800), Vector2i(1440, 900), Vector2i(1600, 900), Vector2i(1920, 1080)]

func _ready() -> void:
	preferences.load(settings_path)
	preload("res://scripts/localization.gd").language = str(preferences.get_value("display", "language", "th"))
	build()

func text(parent: Node, content: String, size: int, color := PAPER) -> Label:
	var l := Label.new()
	l.text = content
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func style(fill: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(1 if border.a > 0 else 0)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func button(parent: Node, content: String, prominent: bool = false) -> Button:
	var b := Button.new()
	b.text = content
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y = 52
	b.add_theme_font_size_override("font_size", 21)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", style(Color("532424") if prominent else Color(0.06,0.065,0.06,0.75), Color("783b36") if prominent else Color("333833")))
	b.add_theme_stylebox_override("hover", style(Color("76332e") if prominent else Color("252b26"), ACCENT))
	b.add_theme_stylebox_override("focus", style(Color.TRANSPARENT, ACCENT))
	b.add_theme_color_override("font_color", PAPER)
	b.add_theme_color_override("font_hover_color", PAPER)
	b.add_theme_stylebox_override("pressed", style(Color("391d1c"), ACCENT))
	b.add_theme_color_override("font_pressed_color", PAPER)
	parent.add_child(b)
	return b

func build() -> void:
	screen = Control.new()
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Leelawadee UI", "Noto Sans Thai", "Tahoma"])
	theme.default_font = font
	theme.default_font_size = 18
	screen.theme = theme
	var veil := ColorRect.new()
	screen.add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){vec2 p=UV-vec2(.5);float v=smoothstep(.22,.72,length(p));COLOR=vec4(.015,.035,.04,v*.52);}"
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	veil.material = shader_material
	var top := HBoxContainer.new()
	screen.add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 36
	top.offset_top = 26
	top.offset_right = -36
	top.hide() # Decorative branding is hidden during gameplay.
	room_label = text(top, "JUBUTSU", 23)
	room_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bell_label = text(top, "EAST WING  /  17:08", 17, ACCENT)
	crosshair = text(screen, "·", 30)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position -= Vector2(5, 15)
	prompt = text(screen, "", 21)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.offset_top = -116
	prompt.offset_bottom = -78
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice = text(screen, "", 22, ACCENT)
	notice.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	notice.offset_top = 88
	notice.offset_bottom = 126
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamina_panel = HBoxContainer.new()
	screen.add_child(stamina_panel)
	stamina_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stamina_panel.position = Vector2(36, -62)
	stamina_panel.add_theme_constant_override("separation", 14)
	text(stamina_panel, "STAMINA", 16, MUTED)
	stamina_bar = ProgressBar.new()
	stamina_panel.add_child(stamina_bar)
	stamina_bar.custom_minimum_size = Vector2(190, 12)
	stamina_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stamina_bar.show_percentage = false
	stamina_bar.add_theme_stylebox_override("background", style(Color("242a26")))
	var fill := StyleBoxFlat.new()
	fill.bg_color = PAPER
	stamina_bar.add_theme_stylebox_override("fill", fill)
	stamina_panel.hide()
	hint_label = text(screen, "", 21, PAPER)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_left = 50
	hint_label.offset_right = -50
	hint_label.offset_top = -185
	hint_label.offset_bottom = -135
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	endless_status = text(screen, "", 18, PAPER)
	endless_status.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	endless_status.offset_top = 30
	endless_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var controls := text(screen, preload("res://scripts/localization.gd").t("ESC  พัก"), 16, MUTED)
	controls.hide()
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	controls.offset_left = 36
	controls.offset_top = -49
	controls.offset_bottom = -22
	overlay = ColorRect.new()
	screen.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.015, 0.02, 0.018, 0.60)
	ambience = ColorRect.new()
	overlay.add_child(ambience)
	ambience.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ambience.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var menu_shader := Shader.new()
	menu_shader.code = "shader_type canvas_item; float noise(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);} void fragment(){float grain=noise(FRAGCOORD.xy+floor(TIME*8.0));float shade=mix(.98,.17,smoothstep(.22,.95,UV.x));float edge=smoothstep(.25,.74,length(UV-.5));COLOR=vec4(vec3(.016,.022,.019)+grain*.018,clamp(shade+edge*.20,0.,.99));}"
	var menu_material := ShaderMaterial.new()
	menu_material.shader = menu_shader
	ambience.material = menu_material
	var margin := MarginContainer.new()
	overlay.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 84)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 52)
	var vertical := VBoxContainer.new()
	margin.add_child(vertical)
	vertical.add_theme_constant_override("separation", 18)
	menu_content = vertical
	text(vertical, preload("res://scripts/localization.gd").t("J U B U T S U     /     เรื่องเล่าหลังเลิกเรียน"), 15, ACCENT)
	var separator := ColorRect.new()
	separator.color = Color("382a28")
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	separator.custom_minimum_size.y = 1
	vertical.add_child(separator)
	var columns := HBoxContainer.new()
	vertical.add_child(columns)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 70)
	var left := VBoxContainer.new()
	columns.add_child(left)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.0
	left.custom_minimum_size.x = 480
	left.add_theme_constant_override("separation", 10)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10
	left.add_child(spacer)
	menu_title = text(left, "JUBUTSU", 74)
	var title_font := SystemFont.new()
	title_font.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	title_font.font_weight = 700
	menu_title.add_theme_font_override("font", title_font)
	menu_title.add_theme_color_override("font_shadow_color", Color(.3,.035,.025,.65))
	menu_title.add_theme_constant_override("shadow_offset_x", 3)
	menu_title.add_theme_constant_override("shadow_offset_y", 2)
	menu_subtitle = text(left, "THE SEVENTH ROOM", 23, ACCENT)
	menu_body = text(left, preload("res://scripts/localization.gd").t("เลิกเรียนแล้ว… แต่ทางเดินยังไม่สิ้นสุด"), 22, MUTED)
	menu_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	primary = button(left, preload("res://scripts/localization.gd").t("เข้าสู่ทางเดิน     →"), true)
	primary.pressed.connect(func(): primary_pressed.emit())
	restart = button(left, preload("res://scripts/localization.gd").t("เริ่มใหม่ที่ห้อง 1"))
	restart.pressed.connect(func(): restart_pressed.emit())
	restart.hide()
	settings_button = button(left, preload("res://scripts/localization.gd").t("ตั้งค่า"))
	settings_button.pressed.connect(open_settings)
	collection_button = button(left, preload("res://scripts/localization.gd").t("สมุดสะสม"))
	collection_button.pressed.connect(func(): collection_requested.emit())
	credits_button = button(left, preload("res://scripts/localization.gd").t("เครดิตทีมงาน"))
	credits_button.pressed.connect(open_credits)
	title_button = button(left, preload("res://scripts/localization.gd").t("กลับเมนูหลัก"))
	title_button.pressed.connect(func(): title_requested.emit())
	title_button.hide()
	var quit_button := button(left, preload("res://scripts/localization.gd").t("ออกจากเกม"))
	quit_button.pressed.connect(func(): get_tree().quit())
	text(left, preload("res://scripts/localization.gd").t("แนะนำให้เล่นพร้อมหูฟัง"), 14, MUTED)
	var right := VBoxContainer.new()
	columns.add_child(right)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 14)
	var number := text(right, "07", 110, Color(.48,.52,.45,.16))
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	number.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mode_picker = OptionButton.new()
	right.add_child(mode_picker)
	mode_picker.add_theme_font_size_override("font_size", 22)
	mode_picker.custom_minimum_size.y = 46
	mode_picker.add_item(preload("res://scripts/localization.gd").t("ง่าย — เสียงคิดในใจ"), 0)
	mode_picker.add_item(preload("res://scripts/localization.gd").t("ปกติ — ประสบการณ์เดิม"), 1)
	mode_picker.add_item(preload("res://scripts/localization.gd").t("ไร้สิ้นสุด — ต้องจบเกมก่อน"), 2)
	mode_picker.select(1)
	mode_description = text(right, "", 18, MUTED)
	mode_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	record_label = text(right, "", 17, PAPER)
	copy_stats = button(right, preload("res://scripts/localization.gd").t("คัดลอกสถิติไว้อวด"))
	copy_stats.pressed.connect(func(): DisplayServer.clipboard_set(share_text))
	copy_stats.hide()
	rules_heading = text(right, preload("res://scripts/localization.gd").t("ก่อนเข้าสู่ทางเดิน"), 17, ACCENT)
	rules_label = text(right, "", 19)
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.add_theme_constant_override("line_spacing", 7)
	text(vertical, preload("res://scripts/localization.gd").t("สังเกตให้ดี  •  จำทางกลับให้ได้"), 14, MUTED)
	text(vertical, "Environment: yuuuusukeeee  /  Characters: suzuart  ·  CC BY 4.0  ·  CREDITS.md", 12, MUTED)
	build_settings(margin)
	build_collection(margin)
	build_credits(margin)
	build_note()
	build_debug()
	fade = ColorRect.new()
	screen.add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0.01, 0.015, 0.02, 0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_brightness_filter()

func build_debug() -> void:
	debug_panel = PanelContainer.new()
	screen.add_child(debug_panel)
	debug_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	debug_panel.offset_left = -370
	debug_panel.offset_top = -125
	debug_panel.offset_right = 370
	debug_panel.offset_bottom = 125
	debug_panel.add_theme_stylebox_override("panel", style(INK, ACCENT))
	var column := VBoxContainer.new()
	debug_panel.add_child(column)
	text(column, preload("res://scripts/localization.gd").t("EVENT LAB  /  โหมดทดสอบ"), 24, ACCENT)
	text(column, preload("res://scripts/localization.gd").t("เลือกเหตุการณ์ → ทดสอบในห้อง 2 → กด F3 เพื่อปิด"), 17)
	debug_picker = OptionButton.new()
	column.add_child(debug_picker)
	debug_picker.add_item(preload("res://scripts/localization.gd").t("00  —  ทางเดินปกติ"), 0)
	var definitions: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/anomalies.json"))
	for entry in definitions:
		debug_picker.add_item("%02d  —  %s" % [int(entry.id), preload("res://scripts/localization.gd").anomaly(int(entry.id), entry.title)], int(entry.id))
	var test_button := button(column, preload("res://scripts/localization.gd").t("ทดสอบเหตุการณ์นี้"), true)
	test_button.pressed.connect(func(): debug_requested.emit(debug_picker.get_selected_id()))
	debug_panel.hide()

func show_menu(new_mode: String, body: String = "") -> void:
	stamina_panel.hide()
	credits_page.hide()
	credits_button.visible = new_mode in ["title", "pause", "win"]
	collection_page.hide()
	collection_button.visible = new_mode in ["title", "pause", "win"]
	mode_picker.visible = new_mode == "title"
	mode_description.visible = new_mode == "title"
	record_label.visible = new_mode in ["title", "win"]
	copy_stats.visible = new_mode == "win" and not share_text.is_empty()
	hint_label.hide()
	endless_status.hide()
	settings_page.hide()
	note_page.hide()
	ambience.show()
	menu_content.show()
	mode = new_mode
	title_button.visible = new_mode in ["pause", "win"]
	settings_button.visible = new_mode != "note"
	overlay.show()
	crosshair.hide()
	restart.visible = new_mode != "title"
	rules_heading.text = preload("res://scripts/localization.gd").t("การควบคุม")
	rules_label.text = preload("res://scripts/localization.gd").t("WASD  เดิน\nเมาส์  มอง\nSHIFT  วิ่ง\nE  โต้ตอบ\nF  ไฟฉาย\nESC  กลับ")
	match mode:
		"title":
			menu_title.text = "JUBUTSU"
			menu_subtitle.text = "ROOM %02d" % final_room
			menu_body.text = preload("res://scripts/localization.gd").t("เลิกเรียนแล้ว… แต่ทางเดินยังไม่สิ้นสุด")
			primary.text = preload("res://scripts/localization.gd").t("เข้าสู่ทางเดิน     →")
			rules_heading.text = preload("res://scripts/localization.gd").t("ก่อนเข้าสู่ทางเดิน")
			rules_label.text = preload("res://scripts/localization.gd").t("พบความผิดปกติ ให้ย้อนกลับ\nไม่พบความผิดปกติ ให้เดินต่อ\nทางออกอยู่ที่ห้อง %d") % final_room
		"pause":
			menu_title.text = "PAUSE"
			menu_subtitle.text = preload("res://scripts/localization.gd").t("ทางเดินจะรอคุณ")
			menu_body.text = preload("res://scripts/localization.gd").t("เสียงในทางเดินเงียบลงชั่วคราว")
			primary.text = preload("res://scripts/localization.gd").t("กลับสู่ทางเดิน     →")
		"note":
			menu_content.hide()
			ambience.hide()
			note_page.show()
			note_text.text = note_rules
			rules_heading.text = preload("res://scripts/localization.gd").t("ข้อความบนกระดาษ")
			rules_label.text = note_rules
			menu_title.text = "A NOTE"
			menu_subtitle.text = preload("res://scripts/localization.gd").t("กระดาษบนพื้น")
			menu_body.text = preload("res://scripts/localization.gd").t("ยินดีต้อนรับสู่โรงเรียนของเรา\nถ้าคุณติดอยู่ในวังวนเวลา ให้ทำตามกฎนี้\n\nจำไว้… คนที่เดินผ่านคุณ\nอาจไม่ได้กำลังหาทางออกเหมือนกัน")
			primary.text = preload("res://scripts/localization.gd").t("จำกฎแล้ว     →")
		"win":
			if not body.is_empty():
				result_body = body
			menu_title.text = "%02d / EXIT" % final_room
			menu_subtitle.text = result_body.get_slice("\n", 0)
			menu_body.text = result_body.substr(result_body.find("\n") + 1).strip_edges()
			primary.text = preload("res://scripts/localization.gd").t("กลับเข้าไปอีกครั้ง     →")
			restart.hide()
	primary.grab_focus()
	if mode == "note":
		note_close.grab_focus()
	reveal_menu()

func hide_menu() -> void:
	overlay.hide()
	stamina_panel.visible = stamina_active
	crosshair.show()
	hint_label.visible = not hint_label.text.is_empty()
	endless_status.visible = not endless_status.text.is_empty()

func update_stamina(active: bool, fraction: float, exhausted: bool) -> void:
	stamina_active = active
	stamina_bar.value = fraction * 100.0
	var fill: StyleBoxFlat = stamina_bar.get_theme_stylebox("fill")
	fill.bg_color = ACCENT if exhausted else PAPER
	stamina_panel.visible = active and mode == "playing"

func configure_modes(unlocked: bool, best: int, seconds: float) -> void:
	mode_picker.set_item_disabled(2, not unlocked)
	mode_picker.set_item_text(2, preload("res://scripts/localization.gd").t("ไร้สิ้นสุด") if unlocked else preload("res://scripts/localization.gd").t("ไร้สิ้นสุด — ต้องจบเกมก่อน"))
	record_label.text = preload("res://scripts/localization.gd").t("สถิติไร้สิ้นสุด: ผ่าน %d ชั้น  |  %02d:%02d") % [best, int(seconds) / 60, int(seconds) % 60] if unlocked else preload("res://scripts/localization.gd").t("จบโหมดง่ายหรือปกติหนึ่งครั้ง\nเพื่อปลดล็อกโหมดไร้สิ้นสุด")
	update_mode_description()

func update_mode_description() -> void:
	var descriptions := [preload("res://scripts/localization.gd").t("คำพูดในใจช่วยเตือนว่าควรสังเกตอะไร\nกฎและเหตุการณ์เหมือนโหมดปกติ"), preload("res://scripts/localization.gd").t("สังเกตด้วยตัวเองตามกฎเดิม\nหาทางออกที่ห้อง %d") % final_room, preload("res://scripts/localization.gd").t("เดินต่อไปได้ไม่จำกัดชั้น ผิดครั้งเดียวจบรอบ\nกระดิ่งวนตามห้อง 2, 3, 5 ของทุกชุด 7 ชั้น\nบันทึกสถิติส่วนตัวและคัดลอกเพื่อแชร์")]
	mode_description.text = descriptions[mode_picker.selected]

func configure_rules(last_room: int, bell_rooms: Array[int]) -> void:
	final_room = last_room
	var numbers := PackedStringArray()
	for number in bell_rooms:
		numbers.append(str(number))
	note_rules = preload("res://scripts/localization.gd").t("อย่าไว้ใจใคร\nอย่าสบตากับคนในทางเดิน\nห้อง %s ต้องสั่นกระดิ่ง 1 ครั้ง\nถ้าได้ยินฝีเท้าตามหลัง ให้วิ่งจนกว่าเสียงจะหายไป\nยกเว้นมีป้ายห้ามวิ่ง: เดินต่อไปข้างหน้า อย่าหยุด\nเครื่องรางที่วางไว้ เก็บติดตัวไปถึงทางออกได้\nอย่ารับของจากคนแปลกหน้า") % [", ".join(numbers)]
	rules_label.text = preload("res://scripts/localization.gd").t("พบความผิดปกติ ให้ย้อนกลับ\nไม่พบความผิดปกติ ให้เดินต่อ\nทางออกอยู่ที่ห้อง %d\n\nWASD  เดิน   /   เมาส์  มอง\nSHIFT  วิ่ง   /   E  โต้ตอบ\nF  ไฟฉาย   /   ESC  พัก") % final_room
	menu_subtitle.text = "ROOM %02d" % final_room

func update_status(_room: int, _final_room: int, _rings: int, _needs_bell: bool) -> void:
	# Progress is communicated through physical signs; rings must be remembered.
	room_label.text = "JUBUTSU"
	bell_label.text = "EAST WING  /  17:08"

func toast(message: String, duration: float = 3.5) -> void:
	notice.text = message
	notice_remaining = duration

func _process(delta: float) -> void:
	if notice_remaining > 0.0:
		notice_remaining -= delta
		if notice_remaining <= 0.0:
			notice.text = ""

func build_settings(parent: Node) -> void:
	preferences.load(settings_path)
	settings_page = VBoxContainer.new()
	parent.add_child(settings_page)
	settings_page.add_theme_constant_override("separation", 16)
	settings_page.custom_minimum_size.x = 700
	settings_page.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	text(settings_page, "SETTINGS", 48, PAPER)
	text(settings_page, preload("res://scripts/localization.gd").t("ตั้งค่า"), 23, ACCENT)
	var scroll := ScrollContainer.new()
	settings_page.add_child(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var options := VBoxContainer.new()
	scroll.add_child(options)
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("separation", 12)
	text(options, "ภาษา / Language", 21)
	language_picker = OptionButton.new()
	options.add_child(language_picker)
	language_picker.custom_minimum_size.y = 44
	language_picker.add_theme_font_size_override("font_size", 20)
	language_picker.add_item("ไทย")
	language_picker.add_item("English")
	language_picker.select(1 if preload("res://scripts/localization.gd").language == "en" else 0)
	language_picker.item_selected.connect(func(index: int):
		preload("res://scripts/localization.gd").language = "en" if index == 1 else "th"
		save_preferences()
		call_deferred("rebuild_language"))
	text(options, preload("res://scripts/localization.gd").t("ขนาดหน้าจอ (โหมดหน้าต่าง)"), 21)
	if editor_embedded:
		var embed_notice := text(options, preload("res://scripts/localization.gd").t("Godot Editor กำลังควบคุมขนาดหน้าต่าง\nปิด Game → Embed Game on Next Play แล้วเริ่มเกมใหม่\nหรือเปิดด้วย Launch JUBUTSU.cmd"), 17, ACCENT)
		embed_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resolution_picker = OptionButton.new()
	options.add_child(resolution_picker)
	resolution_picker.custom_minimum_size.y = 44
	resolution_picker.add_theme_font_size_override("font_size", 20)
	for resolution in RESOLUTIONS:
		resolution_picker.add_item("%d × %d" % [resolution.x, resolution.y])
	resolution_picker.select(clampi(int(preferences.get_value("display", "resolution", 2)), 0, RESOLUTIONS.size() - 1))
	resolution_picker.item_selected.connect(func(_index: int):
		apply_window_size()
		save_preferences())
	text(options, preload("res://scripts/localization.gd").t("ระดับเสียงรวม"), 21)
	volume_slider = HSlider.new()
	options.add_child(volume_slider)
	volume_slider.max_value = 100
	volume_slider.value = clampf(float(preferences.get_value("audio", "volume", 75)), 0, 100)
	volume_slider.custom_minimum_size.y = 32
	style_slider(volume_slider)
	var volume_value := text(options, "%d%%" % volume_slider.value, 18, MUTED)
	volume_slider.value_changed.connect(func(v: float):
		volume_value.text = "%d%%" % v
		volume_changed.emit(v / 100.0)
		save_preferences())
	text(options, preload("res://scripts/localization.gd").t("เสียงเพลงพื้นหลัง"), 21)
	music_volume_slider = HSlider.new()
	options.add_child(music_volume_slider)
	music_volume_slider.max_value = 100
	music_volume_slider.value = clampf(float(preferences.get_value("audio", "music", 75)), 0, 100)
	music_volume_slider.custom_minimum_size.y = 32
	style_slider(music_volume_slider)
	var music_value := text(options, "%d%%" % music_volume_slider.value, 18, MUTED)
	music_volume_slider.value_changed.connect(func(value: float):
		music_value.text = "%d%%" % value
		music_volume_changed.emit(value / 100.0)
		save_preferences())
	text(options, preload("res://scripts/localization.gd").t("ความสว่างหน้าจอ"), 21)
	brightness_slider = HSlider.new()
	options.add_child(brightness_slider)
	brightness_slider.min_value = 60
	brightness_slider.max_value = 140
	brightness_slider.value = clampf(float(preferences.get_value("display", "brightness", 100)), 60, 140)
	brightness_slider.custom_minimum_size.y = 32
	style_slider(brightness_slider)
	var brightness_value := text(options, "%d%%" % brightness_slider.value, 18, MUTED)
	brightness_slider.value_changed.connect(func(value: float):
		brightness_value.text = "%d%%" % value
		apply_brightness()
		save_preferences())
	text(options, preload("res://scripts/localization.gd").t("ความไวเมาส์"), 21)
	sensitivity_slider = HSlider.new()
	options.add_child(sensitivity_slider)
	sensitivity_slider.min_value = 0.5
	sensitivity_slider.max_value = 3.0
	sensitivity_slider.step = 0.1
	sensitivity_slider.value = clampf(float(preferences.get_value("controls", "sensitivity", 1.0)), 0.5, 3.0)
	sensitivity_slider.custom_minimum_size.y = 32
	style_slider(sensitivity_slider)
	var sensitivity_value := text(options, "%.1f ×" % sensitivity_slider.value, 18, MUTED)
	sensitivity_slider.value_changed.connect(func(v: float):
		sensitivity_value.text = "%.1f ×" % v
		sensitivity_changed.emit(v)
		save_preferences())
	fullscreen = CheckButton.new()
	fullscreen.text = preload("res://scripts/localization.gd").t("เต็มหน้าจอ")
	fullscreen.disabled = editor_embedded
	fullscreen.custom_minimum_size.y = 48
	fullscreen.add_theme_stylebox_override("focus", style(Color.TRANSPARENT, ACCENT))
	options.add_child(fullscreen)
	fullscreen.button_pressed = OS.get_cmdline_user_args().has("--start-fullscreen") or bool(preferences.get_value("display", "fullscreen", true))
	fullscreen.toggled.connect(func(on: bool):
		if DisplayServer.get_name() != "headless" and not editor_embedded:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
		resolution_picker.disabled = on or editor_embedded
		if not on:
			apply_window_size()
		save_preferences())
	resolution_picker.disabled = fullscreen.button_pressed or editor_embedded
	if fullscreen.button_pressed and DisplayServer.get_name() != "headless" and not editor_embedded:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		apply_window_size()
	var reset_button := button(settings_page, preload("res://scripts/localization.gd").t("คืนค่าเริ่มต้น"))
	reset_button.pressed.connect(func():
		volume_slider.value = 75
		music_volume_slider.value = 75
		sensitivity_slider.value = 1.0
		brightness_slider.value = 100
		resolution_picker.select(2)
		fullscreen.button_pressed = false
		apply_window_size()
		save_preferences())
	reset_button.name = "ResetDefaults"
	var back := button(settings_page, preload("res://scripts/localization.gd").t("กลับ"), true)
	back.pressed.connect(close_settings)
	text(settings_page, preload("res://scripts/localization.gd").t("บันทึกการตั้งค่าอัตโนมัติ  /  ESC กลับ"), 16, MUTED)
	settings_page.hide()

func save_preferences() -> void:
	preferences.set_value("display", "language", preload("res://scripts/localization.gd").language)
	preferences.set_value("audio", "volume", volume_slider.value)
	preferences.set_value("audio", "music", music_volume_slider.value)
	preferences.set_value("controls", "sensitivity", sensitivity_slider.value)
	preferences.set_value("display", "fullscreen", fullscreen.button_pressed)
	preferences.set_value("display", "resolution", resolution_picker.selected)
	preferences.set_value("display", "brightness", brightness_slider.value)
	preferences.save(settings_path)

func rebuild_language() -> void:
	var selected_mode := mode_picker.selected
	var origin := settings_origin
	if menu_tween:
		menu_tween.kill()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	build()
	mode_picker.select(selected_mode)
	settings_origin = origin
	language_changed.emit()
	mode = origin
	open_settings()

func apply_window_size() -> void:
	if editor_embedded or DisplayServer.get_name() == "headless" or (fullscreen and fullscreen.button_pressed):
		return
	# A maximized window ignores resize requests until restored.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var available := DisplayServer.screen_get_usable_rect()
	var requested: Vector2i = RESOLUTIONS[resolution_picker.selected]
	var actual := Vector2i(mini(requested.x, available.size.x), mini(requested.y, available.size.y))
	DisplayServer.window_set_size(actual)
	DisplayServer.window_set_position(available.position + (available.size - actual) / 2)

func build_brightness_filter() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	brightness_filter = ColorRect.new()
	layer.add_child(brightness_filter)
	brightness_filter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	brightness_filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear; uniform float brightness = 1.0; void fragment(){vec4 source = texture(screen_texture, SCREEN_UV); COLOR = vec4(pow(max(source.rgb, vec3(0.0)), vec3(1.0 / brightness)), 1.0);}"
	brightness_material = ShaderMaterial.new()
	brightness_material.shader = shader
	brightness_filter.material = brightness_material
	apply_brightness()

func apply_brightness() -> void:
	if not brightness_material:
		return
	brightness_material.set_shader_parameter("brightness", brightness_slider.value / 100.0)
	brightness_filter.visible = not is_equal_approx(brightness_slider.value, 100.0)

func open_settings() -> void:
	settings_origin = mode
	mode = "settings"
	menu_content.hide()
	settings_page.show()
	volume_slider.grab_focus()
	reveal_menu()

func close_settings() -> void:
	show_menu(settings_origin)
	settings_button.grab_focus()


func style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color("343a35")
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	slider.add_theme_stylebox_override("slider", track)
	var filled: StyleBoxFlat = track.duplicate()
	filled.bg_color = ACCENT
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)

func reveal_menu() -> void:
	if menu_tween:
		menu_tween.kill()
	var page: Control = settings_page if mode == "settings" else menu_content
	if mode == "note":
		page = note_page
	if mode == "collection":
		page = collection_page
	if mode == "credits":
		page = credits_page
	page.modulate.a = 0.0
	menu_tween = create_tween()
	menu_tween.tween_property(page, "modulate:a", 1.0, .22)

func build_credits(parent: Node) -> void:
	credits_page = VBoxContainer.new()
	parent.add_child(credits_page)
	credits_page.add_theme_constant_override("separation", 18)
	text(credits_page, preload("res://scripts/localization.gd").t("JUBUTSU  /  เครดิตทีมงาน"), 38, PAPER)
	var scroll := ScrollContainer.new()
	credits_page.add_child(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var contents := VBoxContainer.new()
	scroll.add_child(contents)
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.add_theme_constant_override("separation", 16)
	for member in TEAM_CREDITS:
		var name_label := text(contents, member[0], 27, PAPER)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text(contents, member[1], 19, MUTED)
		text(contents, member[2], 21, ACCENT)
		var gap := Control.new()
		gap.custom_minimum_size.y = 12
		contents.add_child(gap)
	text(contents, preload("res://scripts/localization.gd").t("โมเดลและเสียงประกอบ"), 23, PAPER)
	var attribution := RichTextLabel.new()
	contents.add_child(attribution)
	attribution.fit_content = true
	attribution.scroll_active = false
	attribution.add_theme_font_size_override("normal_font_size", 18)
	attribution.add_theme_color_override("default_color", MUTED)
	attribution.text = preload("res://scripts/credits_content.gd").FULL_TEXT
	credits_back = button(credits_page, preload("res://scripts/localization.gd").t("กลับ   [ ESC ]"), true)
	credits_back.pressed.connect(close_credits)
	credits_page.hide()

func open_credits() -> void:
	if mode not in ["title", "pause", "win"]:
		return
	credits_origin = mode
	mode = "credits"
	menu_content.hide()
	settings_page.hide()
	collection_page.hide()
	credits_page.show()
	credits_back.grab_focus()
	reveal_menu()

func close_credits() -> void:
	show_menu(credits_origin)
	credits_button.grab_focus()

func build_collection(parent: Node) -> void:
	collection_page = VBoxContainer.new()
	parent.add_child(collection_page)
	collection_page.add_theme_constant_override("separation", 16)
	text(collection_page, preload("res://scripts/localization.gd").t("สมุดสะสม"), 38, PAPER)
	collection_summary = text(collection_page, "", 20, ACCENT)
	text(collection_page, preload("res://scripts/localization.gd").t("บันทึกเมื่อออกจากชั้นหรือจบรอบ แม้หนีไม่สำเร็จก็เก็บไว้\nรายการที่ยังไม่พบจะปิดชื่อและรายละเอียด"), 17, MUTED)
	var scroll := ScrollContainer.new()
	collection_page.add_child(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	collection_list = VBoxContainer.new()
	scroll.add_child(collection_list)
	collection_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_list.add_theme_constant_override("separation", 12)
	collection_back = button(collection_page, preload("res://scripts/localization.gd").t("กลับ   [ ESC ]"), true)
	collection_back.pressed.connect(close_collection)
	collection_page.hide()

func open_collection(progress: RefCounted, definitions: Array) -> void:
	if mode not in ["title", "pause", "win"]:
		return
	collection_origin = mode
	mode = "collection"
	menu_content.hide()
	settings_page.hide()
	collection_page.show()
	for child in collection_list.get_children():
		collection_list.remove_child(child)
		child.queue_free()
	var total := 0
	var discovered := 0
	for entry in definitions:
		if entry.enabled:
			total += 1
			if progress.anomalies.has(int(entry.id)):
				discovered += 1
	collection_summary.text = preload("res://scripts/localization.gd").t("สิ่งผิดปกติ %d / %d   •   ฉากจบ %d / 2") % [discovered, total, progress.endings.size()]
	text(collection_list, preload("res://scripts/localization.gd").t("ฉากจบ"), 26, ACCENT)
	for id in ["normal", "true"]:
		var unlocked: bool = progress.endings.has(id)
		var title := preload("res://scripts/localization.gd").t("NORMAL END — ผู้เฝ้าทางเดิน") if id == "normal" else preload("res://scripts/localization.gd").t("TRUE END — ชีวิตที่ได้คืนมา")
		var story := preload("res://scripts/localization.gd").t("คุณแทนที่คนแปลกหน้า และเดินวนอยู่ในโรงเรียนต่อไป") if id == "normal" else preload("res://scripts/localization.gd").t("คุณออกจากโรงเรียน กลับบ้าน และใช้ชีวิตปกติได้อีกครั้ง")
		var item := text(collection_list, title + "\n" + story if unlocked else preload("res://scripts/localization.gd").t("??? — ฉากจบที่ยังไม่ค้นพบ"), 20, PAPER if unlocked else MUTED)
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var replay := button(collection_list, preload("res://scripts/localization.gd").t("▶ ดูฉากจบอีกครั้ง") if unlocked else preload("res://scripts/localization.gd").t("ยังไม่ปลดล็อก"))
		replay.name = "Replay_" + id
		replay.disabled = not unlocked
		replay.pressed.connect(func(): ending_replay_requested.emit(id))
	text(collection_list, preload("res://scripts/localization.gd").t("สิ่งผิดปกติ"), 26, ACCENT)
	for entry in definitions:
		if not entry.enabled:
			continue
		var unlocked: bool = progress.anomalies.has(int(entry.id))
		var row := HBoxContainer.new()
		row.name = "Anomaly_%02d" % int(entry.id)
		collection_list.add_child(row)
		row.add_theme_constant_override("separation", 22)
		var picture := TextureRect.new()
		picture.name = "Picture"
		picture.custom_minimum_size = Vector2(320, 200)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(picture)
		if unlocked:
			picture.texture = preload("res://scripts/collection_images.gd").PICTURES.get(int(entry.id))
		else:
			var hidden := text(picture, "?", 70, MUTED)
			hidden.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			hidden.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hidden.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var item := text(row, "%02d  •  %s" % [int(entry.id), preload("res://scripts/localization.gd").anomaly(int(entry.id), str(entry.title)) if unlocked else preload("res://scripts/localization.gd").t("??? — ยังไม่พบ")], 20, PAPER if unlocked else MUTED)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	collection_back.grab_focus()
	reveal_menu()

func close_collection() -> void:
	show_menu(collection_origin)
	collection_button.grab_focus()

func build_note() -> void:
	note_page = CenterContainer.new()
	overlay.add_child(note_page)
	note_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sheet := PanelContainer.new()
	sheet.custom_minimum_size = Vector2(620, 730)
	note_page.add_child(sheet)
	var paper_style := StyleBoxFlat.new()
	paper_style.bg_color = Color("c9bb99")
	paper_style.shadow_color = Color(0, 0, 0, .65)
	paper_style.shadow_size = 28
	paper_style.shadow_offset = Vector2(5, 12)
	sheet.add_theme_stylebox_override("panel", paper_style)
	var texture := ColorRect.new()
	sheet.add_child(texture)
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var paper_shader := Shader.new()
	paper_shader.code = "shader_type canvas_item; float hash(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);} void fragment(){float grain=hash(FRAGCOORD.xy);vec2 edge=min(UV,1.0-UV);float age=1.0-smoothstep(0.0,.14,min(edge.x,edge.y));float fold=exp(-abs(UV.x-.5)*160.0)*.10;float crease=exp(-abs(UV.y-.51)*190.0)*.06;float stain=sin(UV.x*17.0+sin(UV.y*14.0))*sin(UV.y*21.0)*.025;vec3 paper=vec3(.79,.74,.62)+(grain-.5)*.045-age*.17-fold-crease+stain;COLOR=vec4(paper,1.0);}"
	var material := ShaderMaterial.new()
	material.shader = paper_shader
	texture.material = material
	var margin := MarginContainer.new()
	sheet.add_child(margin)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 50)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	margin.add_child(column)
	text(column, preload("res://scripts/localization.gd").t("ถึงคนที่ยังอยู่ในโรงเรียน"), 29, Color("322a21"))
	var line := ColorRect.new()
	line.color = Color("79694e")
	line.custom_minimum_size.y = 1
	column.add_child(line)
	var introduction := text(column, preload("res://scripts/localization.gd").t("ยินดีต้อนรับสู่โรงเรียนของเรา\nถ้าคุณติดอยู่ในวังวนเวลา ให้ทำตามกฎนี้"), 21, Color("403629"))
	introduction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_text = text(column, "", 23, Color("30271f"))
	note_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_text.add_theme_constant_override("line_spacing", 16)
	note_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var warning := text(column, preload("res://scripts/localization.gd").t("จำไว้… คนที่เดินผ่านคุณ\nอาจไม่ได้กำลังหาทางออกเหมือนกัน"), 21, Color("68362b"))
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_close = Button.new()
	note_close.text = preload("res://scripts/localization.gd").t("วางกระดาษลง   [ E / ESC ]")
	note_close.custom_minimum_size.y = 44
	note_close.add_theme_color_override("font_color", Color("514330"))
	note_close.add_theme_color_override("font_focus_color", Color("514330"))
	note_close.add_theme_color_override("font_hover_color", Color("702d24"))
	note_close.add_theme_color_override("font_pressed_color", Color("702d24"))
	for state in ["normal", "hover", "pressed"]:
		note_close.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("8a7554")
	focus.border_width_bottom = 1
	note_close.add_theme_stylebox_override("focus", focus)
	note_close.pressed.connect(func(): primary_pressed.emit())
	column.add_child(note_close)
	note_page.hide()


