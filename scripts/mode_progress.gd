extends RefCounted
## Local unlock and personal record, separate from audio/display preferences.
var path := "user://progress.cfg"
var unlocked := false
var best_rooms := 0
var best_seconds := 0.0
var best_anomalies := 0
var anomalies: Array[int] = []
var endings: Array[String] = []

func load_progress() -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	unlocked = bool(file.get_value("progress", "endless_unlocked", false))
	best_rooms = maxi(0, int(file.get_value("endless", "rooms", 0)))
	best_seconds = maxf(0, float(file.get_value("endless", "seconds", 0)))
	best_anomalies = maxi(0, int(file.get_value("endless", "anomalies", 0)))
	anomalies.clear()
	for id in file.get_value("collection", "anomalies", []):
		if int(id) in range(1, 28) and not anomalies.has(int(id)):
			anomalies.append(int(id))
	endings.clear()
	for id in file.get_value("collection", "endings", []):
		if str(id) in ["normal", "true"] and not endings.has(str(id)):
			endings.append(str(id))

func save_progress() -> void:
	var file := ConfigFile.new()
	file.set_value("progress", "endless_unlocked", unlocked)
	file.set_value("endless", "rooms", best_rooms)
	file.set_value("endless", "seconds", best_seconds)
	file.set_value("endless", "anomalies", best_anomalies)
	file.set_value("collection", "anomalies", anomalies)
	file.set_value("collection", "endings", endings)
	if file.save(path) != OK:
		push_warning(preload("res://scripts/localization.gd").t("บันทึกความคืบหน้าไม่สำเร็จ"))

func discover(id: int) -> void:
	if id > 0 and id <= 27 and not anomalies.has(id):
		anomalies.append(id)
		save_progress()

func collect_ending(id: String) -> void:
	if id in ["normal", "true"] and not endings.has(id):
		endings.append(id)
		save_progress()

func record(rooms: int, seconds: float, anomalies: int) -> void:
	if rooms > best_rooms or (rooms == best_rooms and rooms > 0 and seconds < best_seconds):
		best_rooms = rooms
		best_seconds = seconds
		best_anomalies = anomalies
		save_progress()

static func hint(room: int) -> String:
	var lines := [
		preload("res://scripts/localization.gd").t("“ค่อย ๆ จำภาพทางเดินนี้ไว้… ทั้งสิ่งที่เห็นและเสียงที่ได้ยิน”"),
		preload("res://scripts/localization.gd").t("“ของที่เคยอยู่ตรงนั้น คนที่เดินผ่าน… ลองมองให้ทั่วอีกครั้ง”"),
		preload("res://scripts/localization.gd").t("“บางอย่างเปลี่ยนไปเงียบ ๆ ทั้งตามผนังและหลังบานประตู”"),
		preload("res://scripts/localization.gd").t("“อย่ามัวแต่มองข้างหน้า… เงาสะท้อนกับมุมทางเดินก็มีเรื่องเล่า”"),
		preload("res://scripts/localization.gd").t("“ฟังให้ดีด้วยนะ… เสียงรอบตัวอาจทำให้เรานึกอะไรออก”"),
		preload("res://scripts/localization.gd").t("“แสงกับเงาทำให้ของคุ้นเคยดูต่างไป ลองดูรอบ ๆ ช้า ๆ”"),
		preload("res://scripts/localization.gd").t("“มาไกลแล้ว… จำสิ่งที่พบไว้ แล้วเลือกทางด้วยตัวเอง”")
	]
	return lines[(room - 1) % lines.size()]

