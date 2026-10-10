extends SceneTree
var game: Node3D
const OUT = "res://docs/anomalies_27/"
var captions = ["กระดาษผิดห้อง", "เลือดหน้าห้องเรียน", "ประตูเปิดเอง", "โปสเตอร์เพิ่ม", "คนยื่นของ", "หน้ากากบนโปสเตอร์", "สัญลักษณ์หลอน", "คนสวมหน้ากาก", "ผีในกระจก", "คนแง้มประตูห้องน้ำ", "ฝีเท้าตามหลัง / ผู้ไล่ตาม", "ไฟกระพริบ (ช่วงไฟหรี่)", "ข้อความบนกระดาน", "ลำโพงหาย", "เลขห้องผิด — ปิด / ไม่มีเอฟเฟกต์", "กรอบกระจกหาย", "ประตูหาย", "คนนอกหน้าต่าง — ปิดการสุ่ม", "คนตัวเล็ก", "ไฟดับ", "ผู้ไล่ตามจากผนัง", "เคาะประตู — เหตุการณ์เสียง", "โปสเตอร์เต็มกำแพง", "ถังดับเพลิงหาย", "มือโผล่จากถัง", "เลือดไหลจากก๊อก", "ห้ามวิ่ง / ชายเดินตาม"]

func _initialize() -> void:
	call_deferred("run")

func view_at(pos: Vector3, target: Vector3) -> void:
	game.player.position = pos
	game.player.look_at(Vector3(target.x, pos.y, target.z))
	game.player.camera.rotation = Vector3.ZERO
	game.player.camera.look_at(target)

func save_image(path: String) -> void:
	await process_frame
	await process_frame
	await create_timer(.15).timeout
	assert(root.get_texture().get_image().save_png(path) == OK)

func run() -> void:
	if "--sheets-only" in OS.get_cmdline_user_args():
		await make_sheets()
		quit()
		return
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1280,800)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	game.running = false
	game.player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for id in range(1,28):
		game.load_room(2,id)
		game.level.prop("CharmPickup").hide()
		game.player.get_node("Camera3D/Flashlight").show()
		view_at(Vector3(0,.02,32),Vector3(0,1.4,20))
		match id:
			1: view_at(Vector3(-.3,.02,38.8),game.level.prop("Note").global_position)
			2: view_at(Vector3(-.6,.02,10.5),Vector3(.5,.1,9.2))
			3:
				game.player.position = Vector3(0,.02,2.8)
				game.director.tick(1.0)
				view_at(Vector3(-.5,.02,7.8),Vector3(1.2,1.1,9.3))
			4,6,7,23: view_at(Vector3(-.65,.02,32),Vector3(1,1.5,30))
			5,8,19:
				var walker = game.level.prop("Walker")
				walker.rotation.y = PI
				walker.animate(.2,"Walk")
				var target: Vector3 = walker.global_position + Vector3(0,1.15 if id != 19 else .5,0)
				view_at(walker.global_position + Vector3(0,.02,2.0),target)
			9,16: view_at(Vector3(-.7,.02,24.5),game.level.prop("Mirror").global_position)
			10: view_at(Vector3(-.7,.02,4.7),Vector3(.93,1.45,3.36))
			11,21:
				var z: float = game.level.footsteps_trigger_z if id == 11 else game.level.attacker_trigger_z
				game.player.position = Vector3(0,.02,z-.1)
				game.director.tick(.1)
				view_at(game.player.position,game.level.prop("Pursuer").global_position+Vector3(0,1.2,0))
			12:
				game.director.tick(.1)
				game.player.get_node("Camera3D/Flashlight").hide()
			13:
				game.level.toggle_classroom_door()
				view_at(Vector3(2,.02,9.26),Vector3(4.16,1.65,9.26))
			14: view_at(Vector3(-.5,.02,15),game.level.prop("Speaker").global_position)
			15: view_at(Vector3(0,.02,39),game.level.prop("RoomNumber").global_position)
			17,22:
				if id == 22: game.director.tick(2.3)
				view_at(Vector3(-.6,.02,8.1),Vector3(1.11,1.1,9.26))
			18: view_at(Vector3(.4,.02,10.2),Vector3(-1.85,1.6,11.5))
			20: view_at(Vector3(0,.02,29),Vector3(0,1.4,17))
			24: view_at(Vector3(-.5,.02,-4.5),game.level.prop("Extinguisher").global_position)
			25: view_at(Vector3(.2,.02,18.8),game.level.prop("Bin").global_position + Vector3(0,.6,0))
			26: view_at(Vector3(-.55,.02,-7.8),game.level.prop("Sink").global_position+Vector3(0,.7,0))
			27:
				game.player.position = Vector3(0,.02,32.8)
				game.director.tick(.016)
				view_at(game.player.position,Vector3(.82,1.65,34))
		await save_image(OUT+"%02d.png" % id)
		print("CAPTURED ",id)
	game.queue_free()
	await process_frame
	await make_sheets()
	quit()

func make_sheets() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1800,1260)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var page := Control.new()
	viewport.add_child(page)
	var bg := ColorRect.new()
	bg.color = Color("111714")
	bg.size = Vector2(1800,1260)
	page.add_child(bg)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Leelawadee UI","Tahoma"])
	for sheet in 3:
		var contents := Control.new()
		page.add_child(contents)
		for i in 9:
			var id := sheet*9+i+1
			var origin := Vector2(18+(i%3)*594,18+(i/3)*414)
			var picture := TextureRect.new()
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.texture = ImageTexture.create_from_image(Image.load_from_file(OUT+"%02d.png" % id))
			picture.position = origin
			picture.size = Vector2(576,360)
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			contents.add_child(picture)
			var caption := Label.new()
			caption.position = origin+Vector2(0,365)
			caption.size = Vector2(576,44)
			caption.text = "%02d  %s" % [id,captions[id-1]]
			caption.add_theme_font_override("font",font)
			caption.add_theme_font_size_override("font_size",22)
			contents.add_child(caption)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		assert(viewport.get_texture().get_image().save_png(OUT+"overview_%d.png" % (sheet+1)) == OK)
		contents.free()
	page.free()
	viewport.free()
