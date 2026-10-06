extends CanvasLayer
## Presentation only. Text, colors and margins can be changed without gameplay code.
signal primary_pressed
signal title_requested
signal restart_pressed
signal debug_requested(id: int)
signal volume_changed(value: float)
signal sensitivity_changed(value: float)
const INK := Color("0b0d0c")
const PAPER := Color("e0ddd3")
const MUTED := Color("9c9e97")
const ACCENT := Color("b74e48")
var menu_content: VBoxContainer
var settings_page: VBoxContainer
var settings_button: Button
var title_button: Button
var volume_slider: HSlider
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

func _ready() -> void:
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
	var controls := text(screen, "ESC  พัก", 16, MUTED)
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
	text(vertical, "J U B U T S U     /     เรื่องเล่าหลังเลิกเรียน", 15, ACCENT)
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
	menu_body = text(left, "เลิกเรียนแล้ว… แต่ทางเดินยังไม่สิ้นสุด", 22, MUTED)
	menu_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	primary = button(left, "เข้าสู่ทางเดิน     →", true)
	primary.pressed.connect(func(): primary_pressed.emit())
	restart = button(left, "เริ่มใหม่ที่ห้อง 1")
	restart.pressed.connect(func(): restart_pressed.emit())
	restart.hide()
	settings_button = button(left, "ตั้งค่า")
	settings_button.pressed.connect(open_settings)
	title_button = button(left, "กลับเมนูหลัก")
	title_button.pressed.connect(func(): title_requested.emit())
	title_button.hide()
	var quit_button := button(left, "ออกจากเกม")
	quit_button.pressed.connect(func(): get_tree().quit())
	text(left, "แนะนำให้เล่นพร้อมหูฟัง", 14, MUTED)
	var right := VBoxContainer.new()
	columns.add_child(right)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 14)
	var number := text(right, "07", 218, Color(.48,.52,.45,.16))
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	number.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_heading = text(right, "ก่อนเข้าสู่ทางเดิน", 17, ACCENT)
	rules_label = text(right, "", 19)
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.add_theme_constant_override("line_spacing", 7)
	text(vertical, "สังเกตให้ดี  •  จำทางกลับให้ได้", 14, MUTED)
	text(vertical, "Environment: yuuuusukeeee  /  Characters: suzuart  ·  CC BY 4.0  ·  CREDITS.md", 12, MUTED)
	build_settings(margin)
	build_note()
	build_debug()
	fade = ColorRect.new()
	screen.add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0.01, 0.015, 0.02, 0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
	text(column, "EVENT LAB  /  โหมดทดสอบ", 24, ACCENT)
	text(column, "เลือกเหตุการณ์ → ทดสอบในห้อง 2 → กด F3 เพื่อปิด", 17)
	debug_picker = OptionButton.new()
	column.add_child(debug_picker)
	debug_picker.add_item("00  —  ทางเดินปกติ", 0)
	var definitions: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/anomalies.json"))
	for entry in definitions:
		debug_picker.add_item("%02d  —  %s" % [int(entry.id), entry.title], int(entry.id))
	var test_button := button(column, "ทดสอบเหตุการณ์นี้", true)
	test_button.pressed.connect(func(): debug_requested.emit(debug_picker.get_selected_id()))
	debug_panel.hide()

func show_menu(new_mode: String, body: String = "") -> void:
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
	rules_heading.text = "การควบคุม"
	rules_label.text = "WASD  เดิน\nเมาส์  มอง\nSHIFT  วิ่ง\nE  โต้ตอบ\nF  ไฟฉาย\nESC  กลับ"
	match mode:
		"title":
			menu_title.text = "JUBUTSU"
			menu_subtitle.text = "ROOM %02d" % final_room
			menu_body.text = "เลิกเรียนแล้ว… แต่ทางเดินยังไม่สิ้นสุด"
			primary.text = "เข้าสู่ทางเดิน     →"
			rules_heading.text = "ก่อนเข้าสู่ทางเดิน"
			rules_label.text = "พบความผิดปกติ ให้ย้อนกลับ\nไม่พบความผิดปกติ ให้เดินต่อ\nทางออกอยู่ที่ห้อง %d" % final_room
		"pause":
			menu_title.text = "PAUSE"
			menu_subtitle.text = "ทางเดินจะรอคุณ"
			menu_body.text = "เสียงในทางเดินเงียบลงชั่วคราว"
			primary.text = "กลับสู่ทางเดิน     →"
		"note":
			menu_content.hide()
			ambience.hide()
			note_page.show()
			note_text.text = note_rules
			rules_heading.text = "ข้อความบนกระดาษ"
			rules_label.text = note_rules
			menu_title.text = "A NOTE"
			menu_subtitle.text = "กระดาษบนพื้น"
			menu_body.text = "ยินดีต้อนรับสู่โรงเรียนของเรา\nถ้าคุณติดอยู่ในวังวนเวลา ให้ทำตามกฎนี้\n\nจำไว้… คนที่เดินผ่านคุณ\nอาจไม่ได้กำลังหาทางออกเหมือนกัน"
			primary.text = "จำกฎแล้ว     →"
		"win":
			if not body.is_empty():
				result_body = body
			menu_title.text = "%02d / EXIT" % final_room
			menu_subtitle.text = result_body.get_slice("\n", 0)
			menu_body.text = result_body.substr(result_body.find("\n") + 1).strip_edges()
			primary.text = "กลับเข้าไปอีกครั้ง     →"
			restart.hide()
	primary.grab_focus()
	if mode == "note":
		note_close.grab_focus()
	reveal_menu()

func hide_menu() -> void:
	overlay.hide()
	crosshair.show()

func configure_rules(last_room: int, bell_rooms: Array[int]) -> void:
	final_room = last_room
	var numbers := PackedStringArray()
	for number in bell_rooms:
		numbers.append(str(number))
	note_rules = "อย่าไว้ใจใคร\nอย่าสบตากับคนในทางเดิน\nห้อง %s ต้องสั่นกระดิ่ง 1 ครั้ง\nถ้าได้ยินฝีเท้าตามหลัง ให้วิ่งจนกว่าเสียงจะหายไป\nยกเว้นมีป้ายห้ามวิ่ง: เดินต่อไปข้างหน้า อย่าหยุด\nเครื่องรางที่วางไว้ เก็บติดตัวไปถึงทางออกได้\nอย่ารับของจากคนแปลกหน้า" % [", ".join(numbers)]
	rules_label.text = "พบความผิดปกติ ให้ย้อนกลับ\nไม่พบความผิดปกติ ให้เดินต่อ\nทางออกอยู่ที่ห้อง %d\n\nWASD  เดิน   /   เมาส์  มอง\nSHIFT  วิ่ง   /   E  โต้ตอบ\nF  ไฟฉาย   /   ESC  พัก" % final_room
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
	preferences.load("user://settings.cfg")
	settings_page = VBoxContainer.new()
	parent.add_child(settings_page)
	settings_page.add_theme_constant_override("separation", 16)
	settings_page.custom_minimum_size.x = 650
	settings_page.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	text(settings_page, "SETTINGS", 48, PAPER)
	text(settings_page, "ตั้งค่า", 23, ACCENT)
	text(settings_page, "ปรับให้พร้อมก่อนกลับเข้าสู่ทางเดิน", 19, MUTED)
	text(settings_page, "ระดับเสียง", 21)
	volume_slider = HSlider.new()
	settings_page.add_child(volume_slider)
	volume_slider.max_value = 100
	volume_slider.value = clampf(float(preferences.get_value("audio", "volume", 75)), 0, 100)
	volume_slider.custom_minimum_size.y = 32
	style_slider(volume_slider)
	var volume_value := text(settings_page, "%d%%" % volume_slider.value, 18, MUTED)
	volume_slider.value_changed.connect(func(v: float):
		volume_value.text = "%d%%" % v
		volume_changed.emit(v / 100.0)
		save_preferences())
	text(settings_page, "ความไวเมาส์", 21)
	sensitivity_slider = HSlider.new()
	settings_page.add_child(sensitivity_slider)
	sensitivity_slider.min_value = 0.5
	sensitivity_slider.max_value = 3.0
	sensitivity_slider.step = 0.1
	sensitivity_slider.value = clampf(float(preferences.get_value("controls", "sensitivity", 1.0)), 0.5, 3.0)
	sensitivity_slider.custom_minimum_size.y = 32
	style_slider(sensitivity_slider)
	var sensitivity_value := text(settings_page, "%.1f ×" % sensitivity_slider.value, 18, MUTED)
	sensitivity_slider.value_changed.connect(func(v: float):
		sensitivity_value.text = "%.1f ×" % v
		sensitivity_changed.emit(v)
		save_preferences())
	fullscreen = CheckButton.new()
	fullscreen.text = "เต็มหน้าจอ"
	fullscreen.custom_minimum_size.y = 48
	fullscreen.add_theme_stylebox_override("focus", style(Color.TRANSPARENT, ACCENT))
	settings_page.add_child(fullscreen)
	fullscreen.button_pressed = bool(preferences.get_value("display", "fullscreen", false))
	fullscreen.toggled.connect(func(on: bool):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
		save_preferences())
	if fullscreen.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_page.add_child(space)
	var reset_button := button(settings_page, "คืนค่าเริ่มต้น")
	reset_button.pressed.connect(func():
		volume_slider.value = 75
		sensitivity_slider.value = 1.0
		fullscreen.button_pressed = false)
	var back := button(settings_page, "กลับ", true)
	back.pressed.connect(close_settings)
	text(settings_page, "บันทึกการตั้งค่าอัตโนมัติ  /  ESC กลับ", 16, MUTED)
	settings_page.hide()

func save_preferences() -> void:
	preferences.set_value("audio", "volume", volume_slider.value)
	preferences.set_value("controls", "sensitivity", sensitivity_slider.value)
	preferences.set_value("display", "fullscreen", fullscreen.button_pressed)
	preferences.save("user://settings.cfg")

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
	page.modulate.a = 0.0
	menu_tween = create_tween()
	menu_tween.tween_property(page, "modulate:a", 1.0, .22)

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
	text(column, "ถึงคนที่ยังอยู่ในโรงเรียน", 29, Color("322a21"))
	var line := ColorRect.new()
	line.color = Color("79694e")
	line.custom_minimum_size.y = 1
	column.add_child(line)
	var introduction := text(column, "ยินดีต้อนรับสู่โรงเรียนของเรา\nถ้าคุณติดอยู่ในวังวนเวลา ให้ทำตามกฎนี้", 21, Color("403629"))
	introduction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_text = text(column, "", 23, Color("30271f"))
	note_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_text.add_theme_constant_override("line_spacing", 16)
	note_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var warning := text(column, "จำไว้… คนที่เดินผ่านคุณ\nอาจไม่ได้กำลังหาทางออกเหมือนกัน", 21, Color("68362b"))
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_close = Button.new()
	note_close.text = "วางกระดาษลง   [ E / ESC ]"
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

