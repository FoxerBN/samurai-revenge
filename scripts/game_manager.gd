extends Node

# --- SIGNÁLY ---
signal coins_changed(new_amount: int)
signal quest_updated(quest_index: int)
signal objective_completed   # hlavný cieľ levelu (mince/zabíjanie) je splnený

# --- PREMENNÉ ---
var active_quests = []
var coins: int = 0:
	set(value):
		coins = value
		coins_changed.emit(coins)
		_update_quest_progress("coins", coins)

# --- FUNKCIE ---

func reset_game():
	""" Resetuje stav hry pri novom štarte alebo reštarte levelu. """
	coins = 0
	active_quests = []

func add_quest(type: String, target: int, description: String):
	""" Pridá nový quest do zoznamu úloh.
	Hlavné questy sa spúšťajú postupne – naraz je aktívny vždy len jeden,
	ďalší sa aktivuje až po dokončení predchádzajúceho. Quest "dôjdi do
	portálu" je aktívny hneď (pridáva sa, až keď sú hlavné questy hotové). """
	var quest = {
		"type": type,
		"target": target,
		"current": 0,
		"description": description,
		"completed": false,
		"active": type == "reach_portal"
	}
	active_quests.append(quest)
	if quest.active:
		quest_updated.emit(active_quests.size() - 1)
	else:
		_activate_next_quest()

func notify_enemy_killed():
	""" Pomocná funkcia pre questy na zabíjanie nepriateľov. """
	_update_quest_progress("enemy_kill", 1, true)

func _update_quest_progress(type: String, value: int, is_increment: bool = false):
	""" Interná funkcia na kontrolu a aktualizáciu progresu v questoch. """
	for i in range(active_quests.size()):
		var q = active_quests[i]
		# Aktualizujeme len aktívny quest – čakajúce questy sa nepočítajú,
		# kým na ne nepríde rad.
		if q.type == type and not q.completed:
			if is_increment:
				q.current += value
			else:
				q.current = value

			if q.current >= q.target:
				q.current = q.target
				q.completed = true
				if q.type != "reach_portal":
					# Cieľ levelu (otvorenie portálu) je splnený, až keď sú
					# hotové VŠETKY hlavné questy. Inak spustíme ďalší v poradí.
					if _all_objectives_completed():
						objective_completed.emit()
					else:
						_activate_next_quest()

			quest_updated.emit(i)

func _all_objectives_completed() -> bool:
	""" True, ak sú splnené všetky hlavné questy (okrem 'dôjdi do portálu'). """
	for q in active_quests:
		if q.type != "reach_portal" and not q.completed:
			return false
	return true

func notify_sword_swing():
	_update_quest_progress("sword_swing", 1, true)

func _activate_next_quest() -> void:
	""" Aktivuje ďalší čakajúci hlavný quest, ak práve žiadny nebeží. """
	for q in active_quests:
		if q.type != "reach_portal" and q.active and not q.completed:
			return  # nejaký hlavný quest ešte beží, čakáme
	for i in range(active_quests.size()):
		var q = active_quests[i]
		if q.type != "reach_portal" and not q.active and not q.completed:
			q.active = true
			quest_updated.emit(i)
			return
