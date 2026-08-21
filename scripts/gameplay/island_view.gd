extends Control

var levels := {}
var pulse := 0.0

func set_levels(value:Dictionary):
	levels = value
	queue_redraw()

func _process(delta):
	pulse += delta
	queue_redraw()

func _draw():
	var center := size * Vector2(0.5, 0.48)
	# Soft cloud sea and a layered floating-island silhouette.
	for i in range(9):
		var x := center.x - 460.0 + i * 120.0
		var cloud_y:=center.y+205.0+sin(pulse*0.55+i*0.8)*12.0
		draw_circle(Vector2(x,cloud_y),92.0,Color(0.90,0.96,1.0,0.24))
		draw_circle(Vector2(x+35,cloud_y-26),62.0,Color(0.96,0.98,1.0,0.18))
	var shadow:=PackedVector2Array([center+Vector2(-390,5),center+Vector2(385,5),center+Vector2(240,250),center+Vector2(28,385),center+Vector2(-210,270)])
	draw_colored_polygon(shadow,Color(0.03,0.04,0.12,0.42))
	var rock:=PackedVector2Array([center+Vector2(-365,-5),center+Vector2(360,-5),center+Vector2(255,205),center+Vector2(55,360),center+Vector2(-70,330),center+Vector2(-245,215)])
	draw_colored_polygon(rock,Color("443c65"))
	draw_colored_polygon(PackedVector2Array([center+Vector2(-270,30),center+Vector2(-70,55),center+Vector2(-110,305),center+Vector2(-245,215)]),Color("342f53"))
	draw_colored_polygon(PackedVector2Array([center+Vector2(30,35),center+Vector2(315,10),center+Vector2(205,205),center+Vector2(55,340)]),Color("5f527b"))
	var top:=PackedVector2Array([center+Vector2(-405,-35),center+Vector2(-300,-145),center+Vector2(-85,-195),center+Vector2(170,-170),center+Vector2(390,-48),center+Vector2(300,80),center+Vector2(-310,95)])
	draw_colored_polygon(top,Color("3faa72"))
	draw_polyline(top,Color("91f0a8"),10.0,true)
	# Warm stone paths connect the buildings.
	draw_polyline(PackedVector2Array([center+Vector2(-230,10),center+Vector2(0,-75),center+Vector2(230,5)]),Color("d4bd83"),18.0,true)
	draw_polyline(PackedVector2Array([center+Vector2(-140,125),center+Vector2(0,-75),center+Vector2(165,130)]),Color("c9b27a"),15.0,true)
	var positions := {
		"island_core":center+Vector2(0,-75), "lootling_house":center+Vector2(-240,0), "cannon_workshop":center+Vector2(225,5),
		"crystal_mine":center+Vector2(-145,125), "airship_harbor":center+Vector2(160,130)
	}
	var colors := {"island_core":Color("8b56e8"),"lootling_house":Color("45c894"),"cannon_workshop":Color("e86743"),"crystal_mine":Color("36bde4"),"airship_harbor":Color("e7ad37")}
	for kind in positions:
		var p:Vector2 = positions[kind]; var level:int = int(levels.get(kind,1)); var scale := 1.0 + (level-1)*0.09
		_draw_building(kind,p,scale,colors[kind])
		draw_string(ThemeDB.fallback_font,p+Vector2(-45,68)*scale,"ST. %d"%level,HORIZONTAL_ALIGNMENT_CENTER,90*scale,20*scale,Color.WHITE)

func _draw_building(kind:String,p:Vector2,building_scale:float,color:Color):
	draw_circle(p+Vector2(0,16)*building_scale,64.0*building_scale,Color(0.03,0.04,0.10,0.38))
	match kind:
		"island_core":
			draw_rect(Rect2(p+Vector2(-45,-22)*building_scale,Vector2(90,85)*building_scale),Color("e8ddd0"),true)
			draw_colored_polygon(PackedVector2Array([p+Vector2(-58,-18)*building_scale,p+Vector2(0,-95)*building_scale,p+Vector2(58,-18)*building_scale]),color)
			_draw_crystal(p+Vector2(0,-108)*building_scale,26.0*building_scale,Color("cf78ff"))
		"lootling_house":
			draw_rect(Rect2(p+Vector2(-54,-22)*building_scale,Vector2(108,84)*building_scale),Color("f5e1b7"),true)
			draw_circle(p+Vector2(0,-24)*building_scale,56.0*building_scale,color)
			draw_circle(p+Vector2(0,18)*building_scale,22.0*building_scale,Color("3c315a"))
		"cannon_workshop":
			draw_rect(Rect2(p+Vector2(-58,-10)*building_scale,Vector2(116,72)*building_scale),Color("67506b"),true)
			draw_set_transform(p+Vector2(-5,-30)*building_scale,-0.42,Vector2.ONE)
			draw_rect(Rect2(0,-14*building_scale,92*building_scale,28*building_scale),color,true)
			draw_circle(Vector2.ZERO,23*building_scale,Color("e9b45a"))
			draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
		"crystal_mine":
			draw_rect(Rect2(p+Vector2(-62,10)*building_scale,Vector2(124,52)*building_scale),Color("594e6c"),true)
			_draw_crystal(p+Vector2(-30,-24)*building_scale,34*building_scale,color)
			_draw_crystal(p+Vector2(8,-42)*building_scale,48*building_scale,Color("8e67ff"))
			_draw_crystal(p+Vector2(42,-16)*building_scale,28*building_scale,Color("65eaff"))
		"airship_harbor":
			draw_rect(Rect2(p+Vector2(-58,12)*building_scale,Vector2(116,50)*building_scale),Color("765538"),true)
			draw_line(p+Vector2(0,15)*building_scale,p+Vector2(0,-66)*building_scale,Color("e8c582"),8*building_scale)
			draw_circle(p+Vector2(0,-78)*building_scale,42*building_scale,color)
			draw_rect(Rect2(p+Vector2(-30,-48)*building_scale,Vector2(60,18)*building_scale),Color("b27840"),true)

func _draw_crystal(p:Vector2,radius:float,color:Color):
	var points:=PackedVector2Array([p+Vector2(0,-radius),p+Vector2(radius*0.55,-radius*0.25),p+Vector2(radius*0.35,radius*0.72),p+Vector2(0,radius),p+Vector2(-radius*0.42,radius*0.55),p+Vector2(-radius*0.58,-radius*0.22)])
	draw_colored_polygon(points,color)
	draw_polyline(points,Color(0.9,0.98,1.0,0.75),3.0,true)
