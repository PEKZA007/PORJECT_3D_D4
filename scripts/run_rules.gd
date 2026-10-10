extends RefCounted
## Pure rules shared by the game and regression tests.
static func evaluate(room: int, final_room: int, anomaly: bool, turned_back: bool, rings: int, bell_rooms: Array[int], anomaly_id: int = 0) -> Dictionary:
	if room >= final_room:
		return {"ok": not turned_back, "won": not turned_back, "reason": preload("res://scripts/localization.gd").t("ทางออกอยู่ข้างหน้า"), "next": room}
	if bell_rooms.has(room) and rings != 1:
		return {"ok": false, "won": false, "reason": preload("res://scripts/localization.gd").t("ห้อง %d ต้องสั่นกระดิ่ง 1 ครั้ง — คุณสั่น %d ครั้ง") % [room, rings], "next": 1}
	if anomaly_id == 27:
		return {"ok": not turned_back, "won": false, "reason": preload("res://scripts/localization.gd").t("ป้ายห้ามวิ่ง: เดินไปข้างหน้าต่อไป"), "next": room + 1 if not turned_back else 1}
	if anomaly != turned_back:
		return {"ok": false, "won": false, "reason": preload("res://scripts/localization.gd").t("มีความผิดปกติ แต่คุณเดินต่อ") if anomaly else preload("res://scripts/localization.gd").t("ทางเดินปกติ แต่คุณย้อนกลับ"), "next": 1}
	return {"ok": true, "won": false, "reason": "", "next": room + 1}

