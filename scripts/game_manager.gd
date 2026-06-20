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
	""" Pridá nový quest do zoznamu úloh. """
	var quest = {
		"type": type,
		"target": target,
		"current": 0,
		"description": description,
		"completed": false
	}
	active_quests.append(quest)
	quest_updated.emit(active_quests.size() - 1)

func notify_enemy_killed():
	""" Pomocná funkcia pre questy na zabíjanie nepriateľov. """
	_update_quest_progress("enemy_kill", 1, true)

func _update_quest_progress(type: String, value: int, is_increment: bool = false):
	""" Interná funkcia na kontrolu a aktualizáciu progresu v questoch. """
	for i in range(active_quests.size()):
		var q = active_quests[i]
		if q.type == type and not q.completed:
			if is_increment:
				q.current += value
			else:
				q.current = value
			
			if q.current >= q.target:
				q.current = q.target
				q.completed = true
				# Splnenie hlavného cieľa levelu (nie cieľa "dôjdi do portálu").
				if q.type != "reach_portal":
					objective_completed.emit()

			quest_updated.emit(i)
