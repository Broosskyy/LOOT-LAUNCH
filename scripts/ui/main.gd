extends Control

const C_INK := Color("11152b")
const C_PANEL := Color("20284a")
const C_VIOLET := Color("7651e8")
const C_MINT := Color("45d8aa")
const C_GOLD := Color("ffc94f")
const C_RED := Color("e95468")
const C_SKY := Color("55c7f3")
const C_TEXT_SOFT := Color("d9e5f4")

var screen:Control
var nav:Control
var shell_background:ColorRect
var toast:Label
var orientation_guard:ColorRect
var world
var combo_label:Label
var launch_instruction:Label
var launch_action:Button
var launch_pad:Control
var launch_mode_label:Label
var launch_camera_hint:Label
var launch_reticle:Label
var launch_power_bar:ColorRect
var launch_power_fill:ColorRect
var launch_jump:Button
var launch_failure_panel:Panel
var launch_tally_label:Label
var launch_loadout_label:Label
var launch_objective_label:Label
var launch_route_label:Label
var result_title:Label
var onboarding_avatar_index := 0
var avatar_keys := ["bouncer","magneto","blasto","blink"]
var current_target := {}
var attack_shot := 0
var current_attack := {}
var current_launch_session := {}
var current_launch_is_pvp := false

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	_build_shell()
	show_auth()
	get_viewport().size_changed.connect(_update_orientation)
	_update_orientation()

func _build_shell():
	shell_background=ColorRect.new();shell_background.color=C_INK;shell_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shell_background)
	screen=Control.new();screen.position=Vector2(0,0);screen.size=Vector2(1080,1785);screen.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(screen)
	nav=Control.new();nav.position=Vector2(0,1785);nav.size=Vector2(1080,135);nav.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(nav)
	toast=_label("",24,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER);toast.position=Vector2(140,105);toast.size=Vector2(800,70);toast.z_index=50;toast.visible=false
	var toast_style:=StyleBoxFlat.new();toast_style.bg_color=Color(0.08,0.11,0.22,0.96);toast_style.border_color=C_MINT;toast_style.set_border_width_all(2);toast_style.set_corner_radius_all(26);toast.add_theme_stylebox_override("normal",toast_style);add_child(toast)
	orientation_guard=ColorRect.new();orientation_guard.color=C_INK;orientation_guard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);orientation_guard.z_index=100;add_child(orientation_guard)
	var guard_text:=_label("↻\nBITTE INS HOCHFORMAT DREHEN\nLOOTLINGS FLIEGEN AM LIEBSTEN AUFRECHT",40,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER);guard_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);orientation_guard.add_child(guard_text)

func _update_orientation(): orientation_guard.visible=get_viewport_rect().size.x>get_viewport_rect().size.y

func _clear(with_backdrop:=true):
	shell_background.visible=with_backdrop
	for child in screen.get_children(): child.queue_free()
	for child in nav.get_children(): child.queue_free()
	nav.visible=false
	if is_instance_valid(world): world.queue_free()
	world=null
	if with_backdrop:_add_backdrop()

func _add_backdrop():
	var art:=TextureRect.new();art.texture=load("res://art/concept/loot-launch-key-art.png");art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;art.position=Vector2.ZERO;art.size=Vector2(1080,1785);art.modulate=Color(0.72,0.79,0.95,1.0);art.mouse_filter=Control.MOUSE_FILTER_IGNORE;screen.add_child(art)
	var shade:=ColorRect.new();shade.color=Color(0.035,0.05,0.14,0.55);shade.position=Vector2.ZERO;shade.size=Vector2(1080,1785);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;screen.add_child(shade)
	var top_glow:=ColorRect.new();top_glow.color=Color(0.22,0.55,0.95,0.08);top_glow.position=Vector2.ZERO;top_glow.size=Vector2(1080,440);top_glow.mouse_filter=Control.MOUSE_FILTER_IGNORE;screen.add_child(top_glow)

func show_auth():
	_clear()
	var logo_card:=_panel(Vector2(60,90),Vector2(720,430),Color(0.10,0.09,0.25,0.62),48);screen.add_child(logo_card)
	_add_label(logo_card,"LOOT\nLAUNCH",Vector2(45,26),Vector2(620,260),92,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(logo_card,"ZIELEN  •  FLIEGEN  •  PLÜNDERN",Vector2(50,300),Vector2(620,60),25,C_GOLD,HORIZONTAL_ALIGNMENT_LEFT)
	var form:=_panel(Vector2(70,640),Vector2(940,940),Color(0.055,0.075,0.17,0.91),44);screen.add_child(form)
	_add_label(form,"WILLKOMMEN, HIMMELSKAPITÄN",Vector2(45,26),Vector2(850,74),31,Color.WHITE)
	_add_label(form,"Deine Insel wartet über den Wolken.",Vector2(45,91),Vector2(850,50),23,C_TEXT_SOFT)
	var email:=_make_input("E-Mail-Adresse",Vector2(40,175));email.size=Vector2(860,90);form.add_child(email)
	var password:=_make_input("Passwort – mindestens 8 Zeichen",Vector2(40,285),true);password.size=Vector2(860,90);form.add_child(password)
	var login:=_button("AB IN DIE WOLKEN",Vector2(40,410),Vector2(860,104),C_VIOLET);login.pressed.connect(func():_authenticate(email.text,password.text,false));form.add_child(login)
	var register:=_button("NEUES KONTO ERSTELLEN",Vector2(40,535),Vector2(860,88),Color("278f79"));register.pressed.connect(func():_authenticate(email.text,password.text,true));form.add_child(register)
	var local_text:="LOKALES SPIEL FORTSETZEN" if GameState.profile.get("username","")!="launch_rookie" else "LOKALES TRAINING STARTEN"
	var local:=_button(local_text,Vector2(40,643),Vector2(860,84),Color("30466b"));local.pressed.connect(_local_login);form.add_child(local)
	var reset_text:="PASSWORT ZURÜCKSETZEN" if GameState.live_mode else "PASSWORT-RESET • LIVE-BACKEND NÖTIG"
	var reset:=_button(reset_text,Vector2(40,747),Vector2(860,75),Color("222c4d"),19);reset.disabled=not GameState.live_mode;reset.pressed.connect(func():_reset_password(email.text));form.add_child(reset)
	_add_label(form,"LIVE MIT SUPABASE" if GameState.live_mode else "LOKALER ENTWICKLUNGSMODUS • KEIN ECHTES MULTIPLAYER",Vector2(40,838),Vector2(860,54),18,C_MINT if GameState.live_mode else C_GOLD)

func _authenticate(email:String,password:String,is_register:bool):
	var result:Dictionary
	if is_register:
		result=await GameState.register(email,password)
	else:
		result=await GameState.login(email,password)
	if result.get("ok",false):
		if GameState.profile.get("username","")!="launch_rookie":show_home()
		else:show_onboarding()
	else:_notify(result.get("error","Anmeldung fehlgeschlagen."))

func _reset_password(email:String):
	var result=await GameState.reset_password(email)
	if result.get("ok",false):_notify("Der Reset-Link wurde angefordert. Bitte E-Mail prüfen.")
	else:_notify(result.get("error","Passwort-Reset fehlgeschlagen."))

func _local_login():
	await GameState.login_guest()
	if GameState.profile.get("username","")!="launch_rookie":show_home()
	else:show_onboarding()

func show_onboarding():
	_clear();_header("DEIN HIMMELSKAPITÄN",false)
	_add_label(screen,"Wähle deinen öffentlichen Namen und deinen ersten Lootling.",Vector2(90,225),Vector2(900,100),27,C_TEXT_SOFT)
	var username:=_make_input("Eindeutiger Benutzername",Vector2(120,370));screen.add_child(username)
	var display:=_make_input("Anzeigename",Vector2(120,480));screen.add_child(display)
	var avatar_panel:=_panel(Vector2(190,635),Vector2(700,445),Color(0.11,0.10,0.28,0.90),52);screen.add_child(avatar_panel)
	var avatar:=_label("",44,Color.WHITE);avatar.name="AvatarLabel";avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);avatar_panel.add_child(avatar);_refresh_avatar_label(avatar)
	var left:=_button("◀",Vector2(150,1150),Vector2(170,90),C_VIOLET);left.pressed.connect(func():onboarding_avatar_index=(onboarding_avatar_index+3)%4;_refresh_avatar_label(avatar));screen.add_child(left)
	var right:=_button("▶",Vector2(760,1150),Vector2(170,90),C_VIOLET);right.pressed.connect(func():onboarding_avatar_index=(onboarding_avatar_index+1)%4;_refresh_avatar_label(avatar));screen.add_child(right)
	var confirm:=_button("MEINE INSEL ERSCHAFFEN",Vector2(120,1285),Vector2(840,106),C_MINT);confirm.pressed.connect(func():_reserve_profile(username.text,display.text));screen.add_child(confirm)

func _refresh_avatar_label(label:Label):label.text=_avatar_face(avatar_keys[onboarding_avatar_index])+"\n"+avatar_keys[onboarding_avatar_index].to_upper()
func _reserve_profile(username:String,display_name:String):
	var result=await GameState.reserve_profile(username,display_name,avatar_keys[onboarding_avatar_index]);
	if result.get("ok",false):show_tutorial()
	else:_notify(result.get("error","Dieser Benutzername ist nicht verfügbar."))

func show_tutorial():
	_clear();_header("DEIN ERSTER ABSCHUSS",false)
	var card:=_panel(Vector2(90,280),Vector2(900,820),Color(0.075,0.10,0.23,0.93),46);screen.add_child(card)
	_add_label(card,"DEINE ERSTE HIMMELSROUTE",Vector2(55,35),Vector2(790,70),33,C_GOLD)
	_add_label(card,"①  Bewege Bouncer frei mit dem Analogstick und springe über Hindernisse\n\n②  Wische rechts im Bild, um die Kamera zu drehen\n\n③  Steige in die Kanone, halte zum Aufladen und wische zum Zielen\n\n④  Loslassen feuert – im Flug kannst du steuern und einmal boosten\n\n⑤  Lande wirklich auf der Insel, öffne die Truhe und erreiche die nächste Kanone",Vector2(70,125),Vector2(760,640),25,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
	var play:=_button("ERSTE HIMMELSROUTE VORBEREITEN",Vector2(120,1220),Vector2(840,110),C_VIOLET);play.pressed.connect(show_launch_loadout);screen.add_child(play)

func show_home():
	_clear();GameState.refresh_energy();_header("WOLKENFESTE • STUFE %d"%GameState.island_level());_build_nav()
	var IslandView=preload("res://scripts/gameplay/island_view.gd");var island=IslandView.new();island.position=Vector2(0,180);island.size=Vector2(1080,825);island.set_levels(GameState.buildings);screen.add_child(island)
	var kinds:=["island_core","lootling_house","cannon_workshop","crystal_mine","airship_harbor"]
	for i in kinds.size():
		var kind:String=kinds[i];var x:=310.0 if i==4 else 65.0+(i%2)*490.0;var button:=_button(_building_name(kind)+"  •  ST. %d"%GameState.buildings[kind],Vector2(x,1000+(i/2)*100),Vector2(460,82),_building_color(kind),17);button.pressed.connect(show_building.bind(kind));screen.add_child(button)
	var launch:=_button("✦  "+_world_name(GameState.selected_world)+"  •  "+_lootling_name(GameState.selected_lootling)+" + "+_cannon_short_name(GameState.selected_cannon),Vector2(120,1325),Vector2(840,104),C_VIOLET,18);launch.pressed.connect(show_launch_loadout);screen.add_child(launch)
	var missions:=_button("TAGESMISSIONEN",Vector2(120,1450),Vector2(400,80),Color("31456d"),18);missions.pressed.connect(show_missions);screen.add_child(missions)
	var boss:=_button("WELTBOSS",Vector2(560,1450),Vector2(400,80),Color("8f376f"),18);boss.pressed.connect(show_world_boss);screen.add_child(boss)

func show_building(kind:String):
	_clear();_header(_building_name(kind),false)
	var level:int=GameState.buildings[kind];var panel:=_panel(Vector2(170,300),Vector2(740,600),_building_color(kind),54);screen.add_child(panel)
	_add_label(panel,"%s\n\nSTUFE %d / 5\n\n%s\n\nNÄCHSTE STUFE  ● %d"%[_building_name(kind),level,_building_benefit(kind,level),GameState.upgrade_cost(level)],Vector2(50,60),Vector2(640,480),33,Color.WHITE)
	if kind=="crystal_mine":
		var collect:=_button("◆  KRISTALLE EINSAMMELN",Vector2(210,920),Vector2(660,82),Color("287fa5"),19);collect.pressed.connect(_claim_mine);screen.add_child(collect)
	var upgrade:=_button("MAXIMALE STUFE" if level>=5 else "JETZT VERBESSERN",Vector2(120,1030),Vector2(840,105),Color("555a66") if level>=5 else C_MINT);upgrade.disabled=level>=5;upgrade.pressed.connect(func():_upgrade(kind));screen.add_child(upgrade)
	var back:=_button("ZURÜCK ZUR INSEL",Vector2(120,1160),Vector2(840,82),C_PANEL);back.pressed.connect(show_home);screen.add_child(back)

func _upgrade(kind:String):
	var result=await GameState.upgrade_building(kind,_id());
	if result.get("ok",false):_notify("Verbesserung abgeschlossen!");show_home()
	else:_notify(result.get("error","Verbesserung fehlgeschlagen."))

func _claim_mine():
	var result=await GameState.claim_mine()
	if result.get("ok",false):_notify("%d Kristalle eingesammelt!"%result.get("crystals",0));show_home()
	else:_notify(result.get("error","Die Mine produziert noch."))

func start_launch():
	var result=await GameState.start_launch()
	if not result.get("ok",false):_notify(result.get("error","Aktuell ist kein Abschuss möglich."));return
	_begin_launch(result,false,0)


func show_launch_loadout():
	_clear();_header("ABSCHUSS VORBEREITEN",false)
	var route_card:=_panel(Vector2(70,205),Vector2(940,240),Color(0.055,0.10,0.20,0.97),38);route_card.name="WorldChoiceCard";screen.add_child(route_card)
	_add_label(route_card,"1  EXPEDITION WÄHLEN",Vector2(28,10),Vector2(420,42),18,C_MINT,HORIZONTAL_ALIGNMENT_LEFT)
	for i in GameState.worlds.size():
		var world_key:String=GameState.worlds[i];var active:=world_key==GameState.selected_world
		var mastery:=int(GameState.launch_stats.get("crystal_forge_runs" if world_key=="crystal_forge" else "wolkengarten_runs",0))
		var world_button:=_button(("✓ " if active else "")+_world_name(world_key)+"\n"+_world_role(world_key)+"  •  MEISTERSCHAFT "+str(mastery),Vector2(24+i*452,62),Vector2(430,148),_world_color(world_key) if active else Color(0.09,0.13,0.25,0.96),15)
		world_button.name="WorldChoice_"+world_key;world_button.pressed.connect(_choose_world.bind(world_key));route_card.add_child(world_button)
	var loot_card:=_panel(Vector2(70,470),Vector2(940,350),Color(0.07,0.10,0.23,0.97),40);loot_card.name="LoadoutLootlingCard";screen.add_child(loot_card)
	_add_label(loot_card,"2  LOOTLING WÄHLEN",Vector2(28,12),Vector2(360,42),18,C_MINT,HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(loot_card,_avatar_face(GameState.selected_lootling)+"  "+_lootling_name(GameState.selected_lootling)+"  •  "+_lootling_role(GameState.selected_lootling),Vector2(28,55),Vector2(884,58),29,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(loot_card,_lootling_description(GameState.selected_lootling),Vector2(28,112),Vector2(884,76),18,C_TEXT_SOFT,HORIZONTAL_ALIGNMENT_LEFT)
	for i in GameState.lootlings.size():
		var item:String=GameState.lootlings[i];var active:=item==GameState.selected_lootling
		var button:=_button(("✓ " if active else "")+_avatar_face(item)+"\n"+_lootling_name(item),Vector2(24+i*225,215),Vector2(205,125),_loadout_color(item) if active else Color(0.10,0.13,0.25,0.96),15)
		button.name="LootlingChoice_"+item;button.pressed.connect(_choose_loadout_lootling.bind(item));loot_card.add_child(button)
	var cannon_card:=_panel(Vector2(70,845),Vector2(940,310),Color(0.10,0.075,0.18,0.97),40);cannon_card.name="LoadoutCannonCard";screen.add_child(cannon_card)
	_add_label(cannon_card,"3  KANONE WÄHLEN",Vector2(28,12),Vector2(360,42),18,C_GOLD,HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(cannon_card,_cannon_name(GameState.selected_cannon)+"  •  "+_cannon_stats(GameState.selected_cannon),Vector2(28,55),Vector2(884,48),24,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(cannon_card,_cannon_description(GameState.selected_cannon),Vector2(28,100),Vector2(884,64),17,C_TEXT_SOFT,HORIZONTAL_ALIGNMENT_LEFT)
	for i in GameState.cannons.size():
		var item:String=GameState.cannons[i];var active:=item==GameState.selected_cannon
		var button:=_button(("✓ " if active else "")+_cannon_short_name(item)+"\n"+_cannon_compact_role(item),Vector2(28+i*300,185),Vector2(280,105),Color("bd6b32") if active else Color(0.13,0.11,0.22,0.96),15)
		button.name="CannonChoice_"+item;button.pressed.connect(_choose_loadout_cannon.bind(item));cannon_card.add_child(button)
	var launch:=_button(_world_name(GameState.selected_world)+" STARTEN  ➤",Vector2(120,1185),Vector2(840,112),C_VIOLET);launch.name="ConfirmLoadoutButton";launch.pressed.connect(start_launch);screen.add_child(launch)
	var collection:=_button("SAMMLUNG & DETAILS",Vector2(120,1320),Vector2(410,82),Color("30466b"),17);collection.pressed.connect(show_collection);screen.add_child(collection)
	var back:=_button("ZURÜCK ZUR INSEL",Vector2(550,1320),Vector2(410,82),C_PANEL,17);back.pressed.connect(show_home);screen.add_child(back)


func _choose_loadout_lootling(item:String):
	GameState.select_loadout(item,GameState.selected_cannon)
	show_launch_loadout()


func _choose_world(world_key:String):
	GameState.select_world(world_key)
	show_launch_loadout()


func _choose_loadout_cannon(item:String):
	GameState.select_loadout(GameState.selected_lootling,item)
	show_launch_loadout()


func _cycle_lootling(direction:int):
	var index:=GameState.lootlings.find(GameState.selected_lootling)
	index=posmod(index+direction,GameState.lootlings.size())
	GameState.select_loadout(GameState.lootlings[index],GameState.selected_cannon)
	show_launch_loadout()


func _cycle_cannon(direction:int):
	var index:=GameState.cannons.find(GameState.selected_cannon)
	index=posmod(index+direction,GameState.cannons.size())
	GameState.select_loadout(GameState.selected_lootling,GameState.cannons[index])
	show_launch_loadout()

func _begin_launch(session:Dictionary,pvp:bool,number:int):
	_clear(false)
	current_launch_session=session.duplicate(true)
	current_launch_is_pvp=pvp
	var World=preload("res://scripts/gameplay/island_hopping_world.gd")
	world=World.new()
	screen.add_child(world)
	var hud:=_launch_hud_frame();hud.z_index=30;screen.add_child(hud)
	launch_mode_label=_label(_world_name(str(session.get("world_key",GameState.selected_world))),17,C_MINT,HORIZONTAL_ALIGNMENT_LEFT);launch_mode_label.position=Vector2(112,64);launch_mode_label.size=Vector2(300,40);hud.add_child(launch_mode_label)
	launch_loadout_label=_label(_lootling_name(GameState.selected_lootling)+" · "+_cannon_short_name(GameState.selected_cannon),16,C_SKY);launch_loadout_label.position=Vector2(350,64);launch_loadout_label.size=Vector2(275,40);hud.add_child(launch_loadout_label)
	launch_tally_label=_label("● 0  ◆ 0",17,Color.WHITE);launch_tally_label.position=Vector2(610,64);launch_tally_label.size=Vector2(145,40);hud.add_child(launch_tally_label)
	combo_label=_label("0× KOMBO",18,C_GOLD,HORIZONTAL_ALIGNMENT_RIGHT);combo_label.position=Vector2(730,64);combo_label.size=Vector2(165,40);hud.add_child(combo_label)
	launch_instruction=_label("LAUFE ZUR KANONE",22,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT);launch_instruction.position=Vector2(110,105);launch_instruction.size=Vector2(590,82);hud.add_child(launch_instruction)
	launch_route_label=_label("●  ○  ○  ○  ○  ○",19,C_GOLD,HORIZONTAL_ALIGNMENT_RIGHT);launch_route_label.position=Vector2(655,111);launch_route_label.size=Vector2(238,65);hud.add_child(launch_route_label)
	var objective_panel:=_panel(Vector2(165,260),Vector2(750,72),Color(0.045,0.07,0.15,0.94),25);objective_panel.z_index=30;objective_panel.visible=false;objective_panel.name="ObjectivePanel";screen.add_child(objective_panel)
	launch_objective_label=_label("INSELAUFTRAG",18,C_GOLD);launch_objective_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);objective_panel.add_child(launch_objective_label)
	_build_launch_controls()
	world.combo_changed.connect(_update_combo)
	world.aim_changed.connect(func(angle,value):launch_instruction.text="WINKEL %d°  •  KRAFT %d%%  •  LOSLASSEN"%[int(angle),int(value*100.0)];_set_launch_power(value))
	world.instruction_changed.connect(func(text):launch_instruction.text=text)
	world.action_prompt.connect(_update_launch_action)
	world.state_changed.connect(_update_launch_mode)
	world.finished.connect(_on_attack_launch_finished if pvp else _on_launch_finished)
	world.loot_collected.connect(_spawn_loot_fly)
	world.flight_tally_changed.connect(func(coins,crystals):if is_instance_valid(launch_tally_label):launch_tally_label.text="● %d   ◆ %d"%[coins,crystals])
	world.objective_changed.connect(_update_island_objective)
	world.begin(session,GameState.selected_lootling,GameState.selected_cannon,pvp,number)
	var cancel:=_button("×",Vector2(18,92),Vector2(66,66),Color(0.10,0.12,0.24,0.92),26);cancel.z_index=35;cancel.pressed.connect(_cancel_current_launch);screen.add_child(cancel)
	world.launched.connect(func():cancel.visible=false)

func _build_launch_controls():
	var Joystick=preload("res://scripts/ui/virtual_joystick.gd")
	launch_pad=Joystick.new();launch_pad.position=Vector2(18,1285);launch_pad.size=Vector2(560,475);launch_pad.z_index=31;launch_pad.vector_changed.connect(func(value):if is_instance_valid(world):world.set_move_vector(value));screen.add_child(launch_pad)
	launch_jump=_button("SPRUNG",Vector2(810,1455),Vector2(220,150),Color(0.18,0.62,0.78,0.90),22);launch_jump.z_index=31;launch_jump.pressed.connect(func():if is_instance_valid(world):world.request_jump());screen.add_child(launch_jump)
	launch_action=_button("ZUR KANONE",Vector2(620,1288),Vector2(410,126),C_VIOLET,20);launch_action.z_index=31;launch_action.disabled=true;launch_action.pressed.connect(_world_primary_action);screen.add_child(launch_action)
	launch_camera_hint=_label("RECHTS WISCHEN = KAMERA",17,Color(0.94,0.98,1.0,0.82));launch_camera_hint.position=Vector2(585,1195);launch_camera_hint.size=Vector2(450,78);launch_camera_hint.z_index=31;screen.add_child(launch_camera_hint)
	launch_reticle=_label("◎",54,Color(1.0,0.86,0.35,0.9));launch_reticle.position=Vector2(485,650);launch_reticle.size=Vector2(110,110);launch_reticle.z_index=29;launch_reticle.visible=false;screen.add_child(launch_reticle)
	launch_power_bar=ColorRect.new();launch_power_bar.color=Color(0.04,0.06,0.15,0.78);launch_power_bar.position=Vector2(1008,350);launch_power_bar.size=Vector2(28,570);launch_power_bar.z_index=29;launch_power_bar.visible=false;screen.add_child(launch_power_bar)
	launch_power_fill=ColorRect.new();launch_power_fill.color=C_GOLD;launch_power_fill.position=Vector2(4,562);launch_power_fill.size=Vector2(20,4);launch_power_bar.add_child(launch_power_fill)
	launch_failure_panel=_panel(Vector2(125,470),Vector2(830,560),Color(0.10,0.06,0.18,0.96),48);launch_failure_panel.z_index=45;launch_failure_panel.visible=false;screen.add_child(launch_failure_panel)
	_add_label(launch_failure_panel,"ROUTE GESCHEITERT",Vector2(45,35),Vector2(740,82),36,C_RED)
	_add_label(launch_failure_panel,"BOUNCER IST IN DEN WOLKEN VERSCHWUNDEN.\nDEIN LETZTER CHECKPOINT BLEIBT ERHALTEN.",Vector2(55,130),Vector2(720,150),24,Color.WHITE)
	var retry:=_button("LETZTE KANONE WIEDERHOLEN",Vector2(55,315),Vector2(720,90),C_VIOLET,19);retry.pressed.connect(func():if is_instance_valid(world):world.primary_action();launch_failure_panel.visible=false);launch_failure_panel.add_child(retry)
	var leave:=_button("ROUTE VERLASSEN",Vector2(55,425),Vector2(720,76),Color(0.22,0.25,0.38,0.95),18);leave.pressed.connect(_cancel_current_launch);launch_failure_panel.add_child(leave)

func _set_launch_power(value:float):
	if not is_instance_valid(launch_power_fill):return
	var height:=clampf(value,0.0,1.0)*562.0
	launch_power_fill.position.y=566.0-height
	launch_power_fill.size.y=height
	launch_power_fill.color=C_RED if value>0.88 else C_GOLD if value>0.55 else C_MINT

func _bind_move_button(button:Button,direction:Vector2):
	button.button_down.connect(func():if is_instance_valid(world):world.set_move_button(direction,true))
	button.button_up.connect(func():if is_instance_valid(world):world.set_move_button(direction,false))
	button.mouse_exited.connect(func():if button.button_pressed and is_instance_valid(world):world.set_move_button(direction,false))

func _world_primary_action():
	if not is_instance_valid(world):return
	if world.hop_state==world.HopState.FLYING:world.activate_special()
	else:world.primary_action()

func _update_launch_action(text:String,enabled:bool):
	if not is_instance_valid(launch_action):return
	launch_action.text=text
	launch_action.disabled=not enabled
	launch_action.visible=not text.is_empty()

func _update_launch_mode(label:String):
	if is_instance_valid(launch_mode_label):
		var mode_text:String={"ON_FOOT":"INSEL ERKUNDEN","ENTERING":"KANONE BESTEIGEN","AIMING":"KANONENANSICHT","FLYING":"LUFTFLUG","LANDED":"ZIELINSEL","FAILED":"ROUTE GESCHEITERT","RESULT":"ROUTE BEENDET"}.get(label,label)
		var progress_text:=""
		if is_instance_valid(world) and label not in ["FAILED","RESULT"]:
			progress_text="%d/%d  •  " % [world.current_island_index + 1, world.ROUTE_CENTERS.size()]
		launch_mode_label.text=progress_text+mode_text
	if is_instance_valid(launch_route_label) and is_instance_valid(world):
		var dots:=PackedStringArray()
		for i in range(world.ROUTE_CENTERS.size()):dots.append("●" if i<=world.current_island_index else "○")
		launch_route_label.text="  ".join(dots)
	if is_instance_valid(launch_pad):
		launch_pad.visible=label in ["ON_FOOT","FLYING","LANDED"]
		if not launch_pad.visible and launch_pad.has_method("reset"):launch_pad.reset()
	if is_instance_valid(launch_camera_hint):
		launch_camera_hint.visible=label in ["ON_FOOT","LANDED","FLYING"]
		launch_camera_hint.text="STICK = FLUGLENKUNG" if label=="FLYING" else "RECHTS WISCHEN = KAMERA"
	if is_instance_valid(launch_jump):launch_jump.visible=label in ["ON_FOOT","LANDED"]
	if is_instance_valid(launch_failure_panel):launch_failure_panel.visible=label=="FAILED"
	if is_instance_valid(launch_reticle):launch_reticle.visible=label=="AIMING"
	if is_instance_valid(launch_power_bar):launch_power_bar.visible=label=="AIMING"
	if is_instance_valid(launch_objective_label):
		var objective_panel:=launch_objective_label.get_parent()
		objective_panel.visible=label=="LANDED" and is_instance_valid(world) and world.current_island_index>0 and not world.opened_chests.has(world.current_island_index)
	if label=="AIMING" and is_instance_valid(world):_set_launch_power(world.aim_power)
	if label in ["ENTERING","AIMING","FAILED","RESULT"] and is_instance_valid(launch_action):launch_action.visible=false


func _update_island_objective(current:int,total:int,label:String):
	if not is_instance_valid(launch_objective_label):return
	launch_objective_label.text="AUFTRAG  •  %s  •  %d/%d"%[label,current,total]
	launch_objective_label.add_theme_color_override("font_color",C_MINT if current>=total else C_GOLD)
	launch_objective_label.get_parent().visible=true

func _update_combo(value:int):
	if not is_instance_valid(combo_label):return
	combo_label.text="✦ %dx KOMBO"%value
	combo_label.pivot_offset=combo_label.size*0.5
	combo_label.scale=Vector2(1.28,1.28)
	combo_label.modulate=C_GOLD if value<8 else Color("fff1a8")
	create_tween().tween_property(combo_label,"scale",Vector2.ONE,0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _spawn_loot_fly(kind:String,value:int,from_position:Vector2):
	var icon:="●" if kind=="coin" else "◆" if kind=="crystal" else "✦"
	var color:=C_GOLD if kind=="coin" else C_SKY if kind=="crystal" else Color("fff2a3")
	var fly:=_label(icon+" +"+str(value if value>0 else 100),28,color)
	fly.position=from_position-Vector2(70,35);fly.size=Vector2(150,70);fly.z_index=35;screen.add_child(fly)
	var target:=Vector2(185,85) if kind=="coin" else Vector2(430,85)
	var tween:=create_tween().set_parallel()
	tween.tween_property(fly,"position",target,0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(fly,"scale",Vector2(1.45,1.45),0.18).set_trans(Tween.TRANS_BACK)
	tween.tween_property(fly,"modulate:a",0.0,0.22).set_delay(0.42)
	tween.chain().tween_callback(fly.queue_free)

func _activate_special():
	if is_instance_valid(world):
		world.activate_special()

func _cancel_current_launch():
	if current_launch_is_pvp:
		GameState.current_attack={};current_attack={};show_matchmaking();return
	if is_instance_valid(world) and not world.fired:
		var result=await GameState.cancel_launch(str(current_launch_session.get("session_id","")))
		if not result.get("ok",false):_notify(result.get("error","Dieser Abschuss kann nicht abgebrochen werden."));return
	GameState.pending_world_boss=false
	show_home()

func _on_launch_finished(submission:Dictionary):
	var result=await GameState.submit_launch(submission)
	if result.get("ok",false):
		result["route_score"]=submission.get("route_score",0.0)
		result["attempts"]=submission.get("attempts",1)
		result["visible_coins"]=submission.get("visible_coins",0)
		result["visible_crystals"]=submission.get("visible_crystals",0)
		result["world_key"]=submission.get("world_key",GameState.selected_world)
		if GameState.pending_world_boss:
			GameState.pending_world_boss=false
			var damage:=maxi(100,int(result.get("combo",0))*120+int(result.get("coins",0))*2)
			var boss_result=await GameState.contribute_world_boss(damage)
			result["world_boss_damage"]=boss_result.get("damage",0)
		show_launch_result(result)
	else:_notify(result.get("error","Das Ergebnis wurde abgelehnt."));show_home()

func show_launch_result(result:Dictionary):
	_clear();_header(_world_name(str(result.get("world_key",GameState.selected_world)))+"  •  "+("SELTENER FUND" if result.get("rare",false) else "BEUTE GESICHERT"),false)
	var panel:=_panel(Vector2(140,330),Vector2(800,690),C_VIOLET if result.get("rare",false) else Color("247b70"),58);screen.add_child(panel)
	panel.scale=Vector2(0.72,0.72);panel.pivot_offset=panel.size*0.5
	var reveal:=create_tween();reveal.tween_property(panel,"scale",Vector2.ONE,0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var boss_line:="\n⚔  %d WELTBOSS-SCHADEN"%result.get("world_boss_damage",0) if result.get("world_boss_damage",0)>0 else ""
	var score:=float(result.get("route_score",0.0));var attempts:=int(result.get("attempts",1));var grade:=_route_grade(score,attempts)
	var visible_coins:=int(result.get("visible_coins",result.get("coins",0)));var confirmed_coins:=int(result.get("coins",0))
	var verify_line:="\n✓ SERVER BESTÄTIGT" if visible_coins==confirmed_coins else "\nSICHTBAR %d  •  SERVER-LIMIT %d"%[visible_coins,confirmed_coins]
	var mastery_key:="crystal_forge_runs" if str(result.get("world_key",""))=="crystal_forge" else "wolkengarten_runs"
	var mastery_line:="\nMEISTERSCHAFT  %d"%int(GameState.launch_stats.get(mastery_key,0))
	_add_label(panel,"RANG %s\nLANDUNG %d%%  •  %d VERSUCH%s\n\n%d× KOMBO\n●  %d MÜNZEN   ◆  %d KRISTALLE%s%s%s"%[grade,int(score),attempts,"" if attempts==1 else "E",result.get("combo",0),confirmed_coins,result.get("crystals",0),mastery_line,boss_line,verify_line],Vector2(40,32),Vector2(720,610),32,Color.WHITE)
	var again:=_button("NEUES LOADOUT & NOCH EINMAL",Vector2(120,1120),Vector2(840,105),C_VIOLET);again.pressed.connect(show_launch_loadout);screen.add_child(again)
	var home:=_button("ZURÜCK ZUR INSEL",Vector2(120,1250),Vector2(840,82),C_PANEL);home.pressed.connect(show_home);screen.add_child(home)

func show_collection():
	_clear();_header("SAMMLUNG");_build_nav();_add_label(screen,"LOOTLINGS  •  ANTIPPEN ZUM AUSRÜSTEN",Vector2(65,215),Vector2(800,55),26,C_MINT,HORIZONTAL_ALIGNMENT_LEFT)
	for i in GameState.lootlings.size():
		var item:String=GameState.lootlings[i];var equipped:=item==GameState.selected_lootling;var status:="✓ AUSGERÜSTET" if equipped else _lootling_role(item);var b:=_button(_avatar_face(item)+"  "+_lootling_name(item)+"\n"+status+"  •  "+_lootling_skill(item),Vector2(70+(i%2)*500,290+(i/2)*155),Vector2(460,126),C_VIOLET if equipped else Color(0.09,0.12,0.24,0.93),16);b.pressed.connect(_select_lootling.bind(item));screen.add_child(b)
	_add_label(screen,"KANONEN  •  ANTIPPEN ZUM AUSRÜSTEN",Vector2(65,640),Vector2(760,55),26,C_GOLD,HORIZONTAL_ALIGNMENT_LEFT)
	for i in GameState.cannons.size():
		var item:String=GameState.cannons[i];var equipped:=item==GameState.selected_cannon;var button_text:="✓ "+_cannon_short_name(item)+"\nAUSGERÜSTET" if equipped else _cannon_short_name(item)+"\n"+_cannon_stats(item);var b:=_button(button_text,Vector2(45+i*345,720),Vector2(300,115),Color("bd6b32") if equipped else Color(0.09,0.12,0.24,0.93),15);b.pressed.connect(_select_cannon.bind(item));screen.add_child(b)
	var summary:=_panel(Vector2(90,875),Vector2(900,180),Color(0.055,0.10,0.18,0.96),32);screen.add_child(summary)
	_add_label(summary,"AKTIVES TEAM\n"+_avatar_face(GameState.selected_lootling)+"  "+_lootling_name(GameState.selected_lootling)+"   +   "+_cannon_name(GameState.selected_cannon),Vector2(35,18),Vector2(830,140),24,Color.WHITE)
	var play:=_button("MIT DIESEM TEAM ABSCHIESSEN",Vector2(120,1090),Vector2(840,96),C_VIOLET);play.pressed.connect(show_launch_loadout);screen.add_child(play)
	var inventory:=_button("◆  RELIKTE & INVENTAR",Vector2(120,1210),Vector2(840,82),Color("34466f"),18);inventory.pressed.connect(show_inventory);screen.add_child(inventory)

func _select_lootling(item:String):
	GameState.select_loadout(item,GameState.selected_cannon);_notify(_lootling_name(item)+" ausgerüstet");show_collection()

func _select_cannon(item:String):
	GameState.select_loadout(GameState.selected_lootling,item);_notify(_cannon_name(item)+" ausgerüstet");show_collection()

func show_inventory():
	_clear();_header("RELIKTE & INVENTAR",false)
	var card:=_panel(Vector2(90,260),Vector2(900,760),Color(0.07,0.09,0.21,0.94),48);screen.add_child(card)
	var lines:=[]
	for relic in GameState.relics:
		lines.append("◆  %s\n    %s"%[_relic_name(relic),_relic_effect(relic)])
	if lines.is_empty():lines.append("Noch keine Relikte gefunden.")
	_add_label(card,"AUSGERÜSTETE RELIKTE\n\n"+"\n\n".join(lines)+"\n\nKANONEN: %d / 3\nLOOTLINGS: %d / 4"%[GameState.cannons.size(),GameState.lootlings.size()],Vector2(55,45),Vector2(790,650),29,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
	var back:=_button("ZURÜCK ZUR SAMMLUNG",Vector2(120,1120),Vector2(840,90),C_VIOLET);back.pressed.connect(show_collection);screen.add_child(back)

func show_matchmaking():
	_clear();_header("LUFTSCHIFF-RADAR");_build_nav();_add_label(screen,"PASSENDER GEGNER GEFUNDEN",Vector2(100,245),Vector2(880,90),29,C_SKY)
	var result=await GameState.find_target()
	if not result.get("ok",false):_notify(result.get("error","Kein passender Gegner gefunden."));return
	current_target=result.target;var training:bool=current_target.get("training_bot",false)
	_add_label(screen,"TRAININGSGEGNER • KEIN ECHTER SPIELER" if training else "REGISTRIERTER SPIELER",Vector2(90,365),Vector2(900,65),24,C_GOLD if training else C_MINT)
	var card:=_panel(Vector2(120,490),Vector2(840,440),C_PANEL,44);screen.add_child(card)
	_add_label(card,_avatar_face(current_target.avatar)+"\n"+current_target.display_name+"\n@"+current_target.username+"\nINSEL %d  •  ★ %d"%[current_target.island_level,current_target.trophies],Vector2(40,40),Vector2(760,340),34,Color.WHITE)
	var attack:=_button("TRAININGSANGRIFF STARTEN" if training else "DIESE INSEL ANGREIFEN",Vector2(120,1050),Vector2(840,105),C_RED);attack.pressed.connect(_start_attack);screen.add_child(attack)
	var next:=_button("ANDEREN GEGNER SUCHEN",Vector2(120,1180),Vector2(840,82),C_VIOLET);next.pressed.connect(show_matchmaking);screen.add_child(next)

func _start_attack():
	var result=await GameState.start_attack(current_target)
	if not result.get("ok",false):_notify(result.get("error","Der Angriff ist aktuell nicht möglich."));return
	current_attack=result.attack;attack_shot=1;_start_attack_shot()

func _start_attack_shot():
	var session:={"id":current_attack.id,"session_id":"%s-%d"%[current_attack.id,attack_shot],"seed":int(current_attack.seed)+attack_shot}
	_begin_launch(session,true,attack_shot);combo_label.text="PVP-ABSCHUSS %d / 3"%attack_shot

func _on_attack_launch_finished(submission:Dictionary):
	var best_speed:=0.0
	for event in submission.events:best_speed=maxf(best_speed,float(event.get("speed",0)))
	var shot:={"AttackId":current_attack.id,"ShotNumber":attack_shot,"Angle":submission.angle,"Power":submission.power,"BuildingHit":"snapshot_building_%d"%attack_shot if best_speed>=2 else null,"ImpactSpeed":best_speed,"IdempotencyKey":"%s:%d"%[current_attack.id,attack_shot],"number":attack_shot,"impact_speed":best_speed,"idempotency_key":"%s:%d"%[current_attack.id,attack_shot]}
	var result=await GameState.submit_attack_shot(shot)
	if not result.get("ok",false):_notify(result.get("error","Der Abschuss wurde abgelehnt."));show_matchmaking();return
	if not result.complete:attack_shot+=1;_start_attack_shot()
	else:show_attack_result(result)

func show_attack_result(result:Dictionary):
	_clear();_header("LUFTSCHIFF-BERICHT",false);var card:=_panel(Vector2(120,330),Vector2(840,720),Color(0.14,0.10,0.30,0.94),52);screen.add_child(card);_add_label(card,"⚔\n%d / 3 TREFFER\n\n●  %d MÜNZEN\n★  %+d TROPHÄEN\n\nDer Angriff wurde sicher gespeichert."%[result.hits,result.coins,result.trophy_delta],Vector2(50,45),Vector2(740,620),38,Color.WHITE)
	var done:=_button("ZURÜCK ZUR INSEL",Vector2(120,1180),Vector2(840,100),C_MINT);done.pressed.connect(show_home);screen.add_child(done)

func show_social():
	_clear();_header("HIMMELSCREW");_build_nav()
	_add_label(screen,"FREUNDE FINDEN",Vector2(60,220),Vector2(500,55),28,C_MINT,HORIZONTAL_ALIGNMENT_LEFT)
	var search:=_make_input("Exakten Benutzernamen eingeben",Vector2(80,300));search.size=Vector2(700,90);screen.add_child(search)
	var go:=_button("SUCHEN",Vector2(800,300),Vector2(210,90),C_VIOLET,18);go.pressed.connect(func():_search_friends(search.text));screen.add_child(go)
	var crew_lines:=[]
	for friend in GameState.friends:crew_lines.append("♟  %s  @%s%s"%[friend.get("display_name","Crewmitglied"),friend.get("username",""),"  [TRAINING]" if friend.get("training_bot",false) else ""])
	var crew_text:="NOCH KEINE CREWMITGLIEDER" if crew_lines.is_empty() else "\n".join(crew_lines)
	var activity_text:="NOCH KEINE AKTIVITÄTEN" if GameState.activity.is_empty() else "\n".join(GameState.activity.slice(0,4))
	var card:=_panel(Vector2(80,460),Vector2(920,650),C_PANEL,38);screen.add_child(card)
	_add_label(card,"DEINE CREW\n"+crew_text+"\n\nAKTIVITÄTEN\n"+activity_text,Vector2(45,35),Vector2(830,580),23,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
	if not GameState.friends.is_empty():
		var manage:=_button("CREW VERWALTEN",Vector2(340,1125),Vector2(400,78),Color("2f4c69"),17);manage.pressed.connect(show_manage_friends);screen.add_child(manage)
	var ranking:=_button("★  GLOBALE RANGLISTE",Vector2(120,1240),Vector2(840,90),Color("34466f"));ranking.pressed.connect(show_leaderboard);screen.add_child(ranking)
	var revenge:=_button("KEIN RACHEANGRIFF VERFÜGBAR",Vector2(120,1350),Vector2(840,82),Color("52576d"));revenge.disabled=true;screen.add_child(revenge)

func _search_friends(query:String):
	var result=await GameState.search_players(query)
	if not result.get("ok",false):_notify(result.get("error","Suche fehlgeschlagen."));return
	show_friend_results(result.get("items",[]))

func show_friend_results(items:Array):
	_clear();_header("SPIELERSUCHE",false)
	if items.is_empty():_add_label(screen,"KEIN SPIELER GEFUNDEN",Vector2(100,330),Vector2(880,130),32,C_TEXT_SOFT)
	for i in mini(items.size(),4):
		var player:Dictionary=items[i];var card:=_panel(Vector2(80,245+i*190),Vector2(920,155),Color(0.07,0.10,0.22,0.95),34);screen.add_child(card)
		_add_label(card,_avatar_face(player.get("avatar","bouncer"))+"  "+player.get("display_name","Spieler")+("  [TRAINING]" if player.get("training_bot",false) else "")+"\n@"+player.get("username","")+"  •  ★ %d"%player.get("trophies",0),Vector2(30,12),Vector2(610,128),23,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
		var add:=_button("HINZUFÜGEN",Vector2(655,35),Vector2(235,84),C_MINT,17);add.pressed.connect(_add_friend.bind(player));card.add_child(add)
	var back:=_button("ZURÜCK",Vector2(120,1130),Vector2(840,86),C_VIOLET);back.pressed.connect(show_social);screen.add_child(back)

func _add_friend(player:Dictionary):
	var result=await GameState.add_friend(player)
	if result.get("ok",false):_notify("Zur Himmelscrew hinzugefügt.");show_social()
	else:_notify(result.get("error","Freund konnte nicht hinzugefügt werden."))

func show_manage_friends():
	_clear();_header("HIMMELSCREW VERWALTEN",false)
	for i in GameState.friends.size():
		var friend:Dictionary=GameState.friends[i];var card:=_panel(Vector2(80,250+i*180),Vector2(920,145),Color(0.07,0.10,0.22,0.95),32);screen.add_child(card)
		_add_label(card,_avatar_face(friend.get("avatar","bouncer"))+"  "+friend.get("display_name","Crewmitglied")+"\n@"+friend.get("username",""),Vector2(30,10),Vector2(600,120),24,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
		var remove:=_button("ENTFERNEN",Vector2(660,30),Vector2(225,82),C_RED,17);remove.pressed.connect(_remove_friend.bind(str(friend.get("public_id",""))));card.add_child(remove)
	var back:=_button("ZURÜCK",Vector2(120,1150),Vector2(840,86),C_VIOLET);back.pressed.connect(show_social);screen.add_child(back)

func _remove_friend(public_id:String):
	var result=await GameState.remove_friend(public_id)
	if result.get("ok",false):_notify("Crewmitglied entfernt.");show_manage_friends()
	else:_notify(result.get("error","Entfernen fehlgeschlagen."))

func show_leaderboard():
	_clear();_header("GLOBALE RANGLISTE",false);var result=await GameState.get_leaderboard();var lines:=[];var items:Array=result.get("items",[]);items.sort_custom(func(a,b):return int(a.get("score",0))>int(b.get("score",0)))
	for i in items.size():lines.append("#%d   %s%s   ★ %d"%[i+1,items[i].name,"  [TRAINING]" if items[i].get("training_bot",false) else "",items[i].score])
	var rank_card:=_panel(Vector2(75,250),Vector2(930,1020),Color(0.06,0.08,0.18,0.94),42);screen.add_child(rank_card);_add_label(rank_card,"\n\n".join(lines),Vector2(50,30),Vector2(830,930),29,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
	var back:=_button("ZURÜCK",Vector2(120,1350),Vector2(840,82),C_VIOLET);back.pressed.connect(show_social);screen.add_child(back)

func show_missions():
	GameState._normalize_launch_stats();_clear();_header("AUFTRÄGE & MEISTERSCHAFT",false)
	var mission_card:=_panel(Vector2(75,220),Vector2(930,640),Color(0.06,0.09,0.20,0.94),44);screen.add_child(mission_card)
	_add_label(mission_card,"TÄGLICHE HIMMELSAUFTRÄGE\n\n◉  ROUTE STARTEN                         %d / 1\n\n◉  12 BEUTEOBJEKTE TREFFEN              %d / 12\n\n◉  3 INSELZIELE AKTIVIEREN              %d / 3\n\n◉  3 SCHATZTRUHEN ÖFFNEN                %d / 3\n\n◉  1 GEBÄUDE VERBESSERN                 %d / 1\n\nJE AUFTRAG: 140 MÜNZEN  •  KOMPLETT: 2 KRISTALLE"%[mini(1,int(GameState.launch_stats.launches)),mini(12,int(GameState.launch_stats.objects_hit)),mini(3,int(GameState.launch_stats.objectives)),mini(3,int(GameState.launch_stats.chests)),mini(1,int(GameState.launch_stats.upgrades))],Vector2(55,28),Vector2(820,580),21,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
	var garden_runs:=int(GameState.launch_stats.wolkengarten_runs);var forge_runs:=int(GameState.launch_stats.crystal_forge_runs)
	var mastery:=_panel(Vector2(75,885),Vector2(930,250),Color(0.12,0.075,0.22,0.96),38);screen.add_child(mastery)
	_add_label(mastery,"EXPEDITIONS-MEISTERSCHAFT  •  "+_mastery_rank(garden_runs+forge_runs)+"\n\nWOLKENGARTEN       %d RUNS  •  NÄCHSTES ZIEL %d\nKRISTALLSCHMIEDE   %d RUNS  •  NÄCHSTES ZIEL %d\n\nMEILENSTEINE: 1  •  3  •  10 ABSCHLÜSSE JE WELT"%[garden_runs,_next_mastery_goal(garden_runs),forge_runs,_next_mastery_goal(forge_runs)],Vector2(45,25),Vector2(840,205),20,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
	var claim:=_button("ABGESCHLOSSENE TAGESBELOHNUNGEN HOLEN",Vector2(120,1165),Vector2(840,90),Color("3b5c78"),18);claim.pressed.connect(_claim_missions);screen.add_child(claim)
	var back:=_button("ZURÜCK",Vector2(120,1275),Vector2(840,82),C_VIOLET);back.pressed.connect(show_home);screen.add_child(back)

func _claim_missions():
	var result=await GameState.claim_missions()
	if result.get("ok",false):_notify("+%d Münzen  +%d Kristalle"%[result.get("coins",0),result.get("crystals",0)]);show_missions()
	else:_notify(result.get("error","Keine Belohnung verfügbar."))

func show_world_boss():
	_clear();_header("WELTBOSS",false);var result=await GameState.get_world_boss();var progress:=1.0-float(result.get("current",0))/maxf(1.0,float(result.get("maximum",1)))
	var card:=_panel(Vector2(110,300),Vector2(860,720),Color("6f337d"),50);screen.add_child(card);_add_label(card,"✦  DER TRESORWAL  ✦\n\nGLOBALER SCHADEN\n%.1f %%\n\nDEIN BEITRAG  %d%s"%[progress*100.0,result.get("personal",0),"\n\nTRAININGSDATEN" if result.get("training",false) else ""],Vector2(45,70),Vector2(770,560),39,Color.WHITE)
	var launch:=_button("MIT NÄCHSTEM ABSCHUSS BEITRAGEN",Vector2(120,1140),Vector2(840,100),Color("a33a76"),19);launch.pressed.connect(_start_world_boss_launch);screen.add_child(launch)
	var back:=_button("ZURÜCK",Vector2(120,1270),Vector2(840,82),C_VIOLET);back.pressed.connect(show_home);screen.add_child(back)

func _start_world_boss_launch():
	GameState.pending_world_boss=true
	show_launch_loadout()

func show_settings():
	_clear();_header("PROFIL & EINSTELLUNGEN",false);var profile_card:=_panel(Vector2(90,220),Vector2(900,250),Color(0.07,0.10,0.22,0.94),42);screen.add_child(profile_card);_add_label(profile_card,_avatar_face(GameState.profile.avatar)+"   "+GameState.profile.display_name+"\n@"+GameState.profile.username+"\nINSEL %d  •  ★ %d"%[GameState.island_level(),GameState.wallet.trophies],Vector2(45,25),Vector2(810,200),31,Color.WHITE)
	_add_setting("MUSIK","music",520);_add_setting("SOUND","sound",640);_add_setting("GRAFIKQUALITÄT","quality",760)
	var vibration:=_button("VIBRATION: "+("AN" if GameState.settings.vibration else "AUS"),Vector2(140,880),Vector2(800,82),C_PANEL);vibration.pressed.connect(func():GameState.save_setting("vibration",not GameState.settings.vibration);show_settings());screen.add_child(vibration)
	var logout:=_button("ABMELDEN",Vector2(140,1100),Vector2(800,86),C_RED);logout.pressed.connect(func():GameState.logout();show_auth());screen.add_child(logout)
	var back:=_button("ZURÜCK",Vector2(140,1210),Vector2(800,82),C_VIOLET);back.pressed.connect(show_home);screen.add_child(back)

func _add_setting(title:String,key:String,y:float):
	var value=GameState.settings[key];var text:String=str(["AKKU","BALANCE","HOCH","ULTRA"][clampi(int(value),0,3)]) if key=="quality" else "%d%%"%int(float(value)*100.0)
	var button:=_button(title+":  "+text,Vector2(140,y),Vector2(800,82),C_PANEL);button.pressed.connect(func():var next=(int(value)+1)%4 if key=="quality" else fmod(float(value)+0.25,1.25);GameState.save_setting(key,next);show_settings());screen.add_child(button)

func _route_grade(score:float,attempts:int)->String:
	if score>=78.0 and attempts==1:return "S"
	if score>=62.0 and attempts<=2:return "A"
	if score>=40.0:return "B"
	return "C"

func _build_nav():
	nav.visible=true
	var base:=_panel(Vector2.ZERO,Vector2(1080,135),Color(0.045,0.06,0.14,0.98),0);base.mouse_filter=Control.MOUSE_FILTER_IGNORE;nav.add_child(base)
	var entries:=[ ["⌂\nINSEL",show_home],["➤\nABSCHUSS",show_launch_loadout],["⚔\nANGRIFF",show_matchmaking],["♟\nFREUNDE",show_social],["◆\nSAMMLUNG",show_collection] ]
	for i in entries.size():
		var color:=C_VIOLET if i==1 else Color(0.11,0.14,0.27,0.88)
		var button:=_button(entries[i][0],Vector2(i*216+6,7),Vector2(204,120),color,16);button.pressed.connect(entries[i][1]);nav.add_child(button)

func _launch_hud_frame()->Control:
	var root:=Control.new();root.name="CrystalRouteHUD";root.position=Vector2(45,10);root.size=Vector2(990,220);root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var frame:=NinePatchRect.new();frame.texture=load("res://art/generated/ui/hud_crystal_frame_v14.png");frame.patch_margin_left=285;frame.patch_margin_right=285;frame.patch_margin_top=105;frame.patch_margin_bottom=105;frame.axis_stretch_horizontal=NinePatchRect.AXIS_STRETCH_MODE_STRETCH;frame.axis_stretch_vertical=NinePatchRect.AXIS_STRETCH_MODE_STRETCH;frame.position=Vector2.ZERO;frame.size=root.size;frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(frame)
	return root

func _header(title:String,with_stats:=true):
	var panel:=_panel(Vector2(18,18),Vector2(1044,170),Color(0.045,0.065,0.16,0.92),32);screen.add_child(panel)
	_add_label(panel,title,Vector2(30,10),Vector2(875,70),36,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)
	if with_stats:
		_add_resource_chip(panel,"●",str(GameState.wallet.coins),Vector2(28,92),C_GOLD)
		_add_resource_chip(panel,"◆",str(GameState.wallet.crystals),Vector2(245,92),Color("76e8ff"))
		_add_resource_chip(panel,"⚡","%d/%d"%[GameState.energy.current,GameState.energy.maximum],Vector2(462,92),Color("8cf5b5"))
		_add_resource_chip(panel,"★",str(GameState.wallet.trophies),Vector2(715,92),Color("ffd86b"))
	var settings:=_button("⚙",Vector2(930,23),Vector2(86,72),Color("28335b"),28);settings.pressed.connect(show_settings);panel.add_child(settings)

func _add_resource_chip(parent:Control,icon:String,value:String,pos:Vector2,color:Color):
	var chip:=_panel(pos,Vector2(195,52),Color(0.10,0.14,0.27,0.94),22);parent.add_child(chip)
	_add_label(chip,icon,Vector2(10,0),Vector2(44,52),22,color)
	_add_label(chip,value,Vector2(52,0),Vector2(130,52),20,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT)

func _notify(text:String):
	toast.text=text;toast.visible=true
	get_tree().create_timer(2.6).timeout.connect(func(): toast.visible=false)

func _panel(pos:Vector2,panel_size:Vector2,color:Color,radius:float)->Panel:
	var panel:=Panel.new();panel.position=pos;panel.size=panel_size;var style:=StyleBoxFlat.new();style.bg_color=color;style.corner_radius_top_left=int(radius);style.corner_radius_top_right=int(radius);style.corner_radius_bottom_left=int(radius);style.corner_radius_bottom_right=int(radius);style.border_color=Color(0.65,0.78,1.0,0.18);style.border_width_left=2;style.border_width_top=2;style.border_width_right=2;style.border_width_bottom=2;style.shadow_color=Color(0.01,0.02,0.08,0.45);style.shadow_size=16;style.shadow_offset=Vector2(0,8);panel.add_theme_stylebox_override("panel",style);return panel

func _button(text:String,pos:Vector2,button_size:Vector2,color:Color,font_size:=22)->Button:
	var button:=Button.new();button.text=text;button.position=pos;button.size=button_size;button.add_theme_font_size_override("font_size",font_size);button.add_theme_color_override("font_color",Color.WHITE);button.add_theme_color_override("font_hover_color",Color.WHITE)
	button.pressed.connect(AudioManager.play_ui)
	var normal:=StyleBoxFlat.new();normal.bg_color=color;normal.corner_radius_top_left=24;normal.corner_radius_top_right=24;normal.corner_radius_bottom_left=24;normal.corner_radius_bottom_right=24;normal.border_color=color.lightened(0.28);normal.border_width_left=2;normal.border_width_top=2;normal.border_width_right=2;normal.border_width_bottom=3;normal.shadow_color=Color(0.01,0.02,0.08,0.48);normal.shadow_size=9;normal.shadow_offset=Vector2(0,6);button.add_theme_stylebox_override("normal",normal)
	var hover:=normal.duplicate();hover.bg_color=color.lightened(0.12);hover.border_color=Color.WHITE;button.add_theme_stylebox_override("hover",hover)
	var pressed:=normal.duplicate();pressed.bg_color=color.darkened(0.14);pressed.shadow_size=2;pressed.shadow_offset=Vector2(0,2);button.add_theme_stylebox_override("pressed",pressed)
	var disabled:=normal.duplicate();disabled.bg_color=Color("444b63");disabled.border_color=Color("5c647e");button.add_theme_stylebox_override("disabled",disabled);return button

func _label(text:String,font_size:int,color:Color,alignment:=HORIZONTAL_ALIGNMENT_CENTER)->Label:
	var label:=Label.new();label.text=text;label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",color);label.horizontal_alignment=alignment;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return label

func _add_label(parent:Control,text:String,pos:Vector2,label_size:Vector2,font_size:int,color:Color,alignment:=HORIZONTAL_ALIGNMENT_CENTER)->Label:
	var label:=_label(text,font_size,color,alignment);label.position=pos;label.size=label_size;parent.add_child(label);return label

func _make_input(placeholder:String,pos:Vector2,secret:=false)->LineEdit:
	var input:=LineEdit.new();input.placeholder_text=placeholder;input.position=pos;input.size=Vector2(860,90);input.secret=secret;input.add_theme_font_size_override("font_size",24);var style:=StyleBoxFlat.new();style.bg_color=Color(0.96,0.98,1.0,0.96);style.corner_radius_top_left=22;style.corner_radius_top_right=22;style.corner_radius_bottom_left=22;style.corner_radius_bottom_right=22;style.border_color=Color(0.63,0.75,1.0,0.55);style.border_width_left=2;style.border_width_top=2;style.border_width_right=2;style.border_width_bottom=2;style.content_margin_left=25;style.content_margin_right=25;input.add_theme_stylebox_override("normal",style);var focus:=style.duplicate();focus.border_color=C_SKY;focus.border_width_left=4;focus.border_width_top=4;focus.border_width_right=4;focus.border_width_bottom=4;input.add_theme_stylebox_override("focus",focus);input.add_theme_color_override("font_color",C_INK);input.add_theme_color_override("font_placeholder_color",Color("777f96"));return input

func _avatar_face(key:String)->String:return {"bouncer":"◉ᴗ◉","magneto":"⊂●ᴗ●⊃","blasto":"✦•ᴗ•✦","blink":"◌●‿●◌"}.get(key,"●ᴗ●")
func _lootling_name(key:String)->String:return {"bouncer":"BOUNCER","magneto":"MAGNETO","blasto":"BLASTO","blink":"BLINK"}.get(key,key.to_upper())
func _lootling_skill(key:String)->String:return {"bouncer":"KRAFTABPRALLER","magneto":"BEUTEMAGNET","blasto":"ERSTTREFFER-EXPLOSION","blink":"PHASENSPRUNG"}.get(key,"")
func _lootling_role(key:String)->String:return {"bouncer":"KOMBO","magneto":"SAMMLER","blasto":"ZERSTÖRER","blink":"TAKTIK"}.get(key,"ALLROUND")
func _lootling_description(key:String)->String:return {"bouncer":"Prallt besonders stark ab und hält lange Combo-Ketten am Leben.","magneto":"Zieht Münzen und Kristalle aus größerer Entfernung sicher an.","blasto":"Sprengt beim ersten harten Treffer Hindernisse und öffnet riskante Wege.","blink":"Teleportiert sich mit der Spezialfähigkeit nach vorn durch Gefahr."}.get(key,"")
func _cannon_name(key:String)->String:return {"standard":"STANDARDKANONE","thunder":"DONNERKANONE","portal":"PORTALWERFER"}.get(key,key.to_upper())
func _cannon_short_name(key:String)->String:return {"standard":"STANDARD","thunder":"DONNER","portal":"PORTAL"}.get(key,key.to_upper())
func _cannon_description(key:String)->String:return {"standard":"Ausgeglichen, präzise und ideal zum Lernen neuer Routen.","thunder":"Mehr Kraft und schnelleres Laden – reagiert dafür empfindlicher.","portal":"Weniger Grundkraft, aber zwei taktische Spezialimpulse im Flug."}.get(key,"")
func _cannon_stats(key:String)->String:return {"standard":"KRAFT 3/5  •  KONTROLLE 5/5","thunder":"KRAFT 5/5  •  KONTROLLE 2/5","portal":"KRAFT 2/5  •  TAKTIK 5/5"}.get(key,"")
func _cannon_compact_role(key:String)->String:return {"standard":"PRÄZISE","thunder":"MAX. KRAFT","portal":"2 IMPULSE"}.get(key,"")
func _world_name(key:String)->String:return {"wolkengarten":"WOLKENGARTEN","crystal_forge":"KRISTALLSCHMIEDE","kristallschmiede_expedition_v1":"KRISTALLSCHMIEDE"}.get(key,key.to_upper())
func _world_role(key:String)->String:return {"wolkengarten":"AUSGEGLICHEN • LUFT & PORTALE","crystal_forge":"FORTGESCHRITTEN • HÖHEN & PRISMEN"}.get(key,"")
func _world_color(key:String)->Color:return Color("236d7d") if key=="wolkengarten" else Color("754bc4")
func _next_mastery_goal(runs:int)->int:return 1 if runs<1 else 3 if runs<3 else 10 if runs<10 else runs
func _mastery_rank(total_runs:int)->String:return "HIMMELSVETERAN" if total_runs>=20 else "ROUTENMEISTER" if total_runs>=6 else "EXPEDITIONSANWÄRTER" if total_runs>=2 else "NEULING"
func _loadout_color(key:String)->Color:return {"bouncer":Color("2d9f78"),"magneto":Color("268ba8"),"blasto":Color("c95545"),"blink":Color("6d4bd2")}.get(key,C_VIOLET)
func _building_name(kind:String)->String:return {"island_core":"INSELKERN","lootling_house":"LOOTLING-HAUS","cannon_workshop":"KANONENWERKSTATT","crystal_mine":"KRISTALLMINE","airship_harbor":"LUFTSCHIFFHAFEN"}.get(kind,kind.to_upper())
func _building_color(kind:String)->Color:return {"island_core":Color("8651dc"),"lootling_house":Color("34a77a"),"cannon_workshop":Color("d85c3d"),"crystal_mine":Color("28a5d0"),"airship_harbor":Color("bf8e29")}.get(kind,C_PANEL)
func _building_benefit(kind:String,level:int)->String:return {"island_core":"Öffnet Weltstufe %d"%level,"lootling_house":"Lootling-Bonus +%d %%"%(level*2),"cannon_workshop":"Abschussleistung +%d %%"%(level*3),"crystal_mine":"Produziert %d Kristall je 10 Minuten"%level,"airship_harbor":"Angriffsschutz +%d %%"%(level*2)}.get(kind,"")
func _relic_name(key:String)->String:return {"wind_splinter":"WINDSPLITTER"}.get(key,key.to_upper())
func _relic_effect(key:String)->String:return {"wind_splinter":"+5 % kontrollierte Abschusskraft"}.get(key,"Unbekannter Relikteffekt")
func _id()->String:return "%x-%x"%[Time.get_ticks_usec(),randi()]
