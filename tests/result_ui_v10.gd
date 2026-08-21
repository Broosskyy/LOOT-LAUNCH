extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_scene:PackedScene=load("res://scenes/main.tscn")
	var main=main_scene.instantiate()
	root.add_child(main)
	await process_frame
	main.show_launch_result({"rare":true,"combo":17,"coins":480,"crystals":2,"route_score":84.0,"attempts":1})
	await process_frame
	var all_text:=""
	for child in main.screen.find_children("*","Label",true,false):
		all_text+=str(child.text)+"\n"
	assert(all_text.contains("RANG S"),"High precision first-attempt route shows an S grade")
	assert(all_text.contains("480 MÜNZEN"),"Authoritative reward remains visible")
	assert(all_text.contains("LANDUNG 84%"),"Landing precision is explained on the result screen")
	print("LOOT LAUNCH v10 result UI passed")
	quit(0)
