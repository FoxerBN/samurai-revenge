# Samurai Revenge — poznámky, review a návrhy

Tento súbor zhŕňa stav projektu po upratovaní a obsahuje návrhy, ktoré sa
**zatiaľ neimplementovali** (kolízne vrstvy, systém postupu do ďalšieho levela).

---

## 1. Štruktúra priečinkov — hodnotenie

Aktuálne (po vyčistení):

```
assets/
  fonts/      PressStart2P
  music/      Silent Forest.mp3
  sounds/     coin.wav, chest.mp3
  sprites/
	Character/   animačné sheety hráča + slime-npc.png
	environment/ stromy (Dark/Golden/Green/Red/Yellow)
	coin.png, chest.png, Tiles.png, Summer8.png, Background.png   ← voľne ležia
scenes/   enemies/ items/ levels/ player/ ui/
scripts/  enemies/ items/ levels/ ui/ + game_manager.gd
```

**Čo je dobré:** rozdelenie `scenes/` a `scripts/` podľa rovnakých kategórií je
prehľadné a konzistentné. `assets/` má rozumné podpriečinky.

**Čo som vyčistil:**
- `recording.avi` (10 MB Movie Maker nahrávka) — zmazané + pridané do `.gitignore`
- `chest88.png`, `Interface-...Crown.ico` — nepoužité, zmazané
- všetky `*.gif` (Aseprite náhľady, Godot ich nepoužíva) — zmazané
- `controls.tscn/.gd` — nahradené novým `story_dialog`

**Odporúčania (sprav v Godot editore — kvôli `.import` referenciám neťahaj
súbory mimo editora!):**
- Voľné sprity v `assets/sprites/` presunúť do podpriečinkov:
  `items/` (coin, chest), `tiles/` (Tiles), `backgrounds/` (Summer8, Background).
- `Jumlp-All/` → preklep, premenuj na `Jump-All/`. Skontroluj aj nepoužité
  sheety `Jump-Start/`, `Jump/` (hráč ich teraz nepoužíva) — buď zapoj do
  animácií skoku, alebo zmaž.
- `.aseprite` zdrojové súbory som **nechal** (sú to editovateľné originály).
  Pokojne ich presuň do samostatného `art_source/` mimo `assets/`, aby sa
  nepliedli s tým, čo hra reálne načítava.
- `Background.png` už nie je nikde použitý (skrytý sprite som odstránil z levelu).
  Ak ho neplánuješ použiť, môžeš zmazať `Background.png` + `.import`.

---

## 2. Scény a logika — review

**Tok hry:** `level_1.tscn` je hlavná scéna → `StoryDialog` pauzne hru a ukáže
intro → po dohraní vyšle signál `finished` → `Player.start_game()` spustí hru.

**Globálny stav:** `GameManager` (autoload) drží mince a questy a komunikuje cez
signály (`coins_changed`, `quest_updated`). HUD aj QuestUI len počúvajú signály —
**toto je správny vzor** (loose coupling, žiadne tvrdé referencie medzi UI a logikou).

**Komunikácia medzi objektmi je riešená dobre:**
- mince/nepriatelia identifikujú hráča cez skupinu `player` (`is_in_group`),
  nie cez tvrdú cestu — čisté a znovupoužiteľné;
- truhla aj minca volajú `GameManager` priamo cez autoload — OK.

**Čo by som zlepšil (nie kritické):**
- `frog.gd` zatiaľ **nemá smrť** — útok hráča žabu nezabije. Pre „kill" levely to
  bude treba (viď bod 4).
- `player.gd _handle_interaction()` používa `find_child("InteractionArea", ...)`
  každý stlačok E — lepšie uložiť referenciu cez `@onready`.
- Mená nodov v leveli som upratal: `Environment`, `Environment2`, `base`,
  `Enemies`, `Coins`, `Coin1..4` (predtým `Node`, `enemy`, `Area2D`…).
- TileSet dáta sú vložené priamo v `level_1.tscn` (preto má ~390 KB). Pre
  čistotu a zdieľanie medzi levelmi zváž **uloženie TileSetu ako `.tres`**
  (v editore: TileSet → Save As) do `resources/` a referencovať ho.

---

## 3. Kolízne vrstvy (layers / masks) — review

**Aktuálny stav:**

| Objekt            | layer | mask  | poznámka |
|-------------------|-------|-------|----------|
| Tilemapy (svet)   | 1     | 1     | kolízia definovaná v TileSet physics layer |
| Hráč              | 1     | 1+2   | je na **rovnakej vrstve ako svet** |
| Žaba (frog)       | 2     | 1     | deteguje hráča, lebo hráč je na vrstve 1 |
| Minca (Area2D)    | 1     | 1     | deteguje telo hráča |
| Truhla + areas    | 1     | 1     | |

**Funguje to**, ale má to jeden „smell": **hráč a svet zdieľajú vrstvu 1**.
Žaba „náhodou" deteguje hráča len preto, že hráč sedí na vrstve sveta.
Je to krehké — keby si hráča presunul na vlastnú vrstvu, žaba ho prestane vidieť.

**Odporúčaná čistá schéma** (nastav v *Project Settings → Layer Names → 2D Physics*
a potom v jednotlivých scénach zaškrtni vrstvy/masky — rob v editore a hneď testuj):

```
Vrstva 1: World         (tilemapy, neviditeľné steny)
Vrstva 2: Player
Vrstva 3: Enemy
Vrstva 4: Collectible   (mince — len Area2D)
Vrstva 5: Interactable  (truhla)
```

| Objekt              | layer        | mask                  |
|---------------------|--------------|-----------------------|
| Tilemapy / steny    | World        | —                     |
| Hráč (body)         | Player       | World + Enemy         |
| Hráč InteractionArea| —            | Interactable          |
| Žaba                | Enemy        | World + Player        |
| Minca (Area2D)      | Collectible  | Player                |
| Truhla (body)       | World        | —                     |
| Truhla InteractionArea | Interactable | Player             |

Pozn.: kolíziu **svetových dlaždíc** nemeníš na node, ale v **TileSet → Physics
Layer** (tam je nastavená vrstva sveta).

---

## 4. Návrh: systém postupu do ďalšieho levela (zatiaľ neimplementované)

Cieľ: dva typy levelov — **zbieranie mincí** a **zabíjanie NPC**. Po splnení
questu sa sprístupní **výstupná zóna** (`Area2D`), ktorá hráča prenesie do ďalšej
scény. Žiadne ukladanie.

### 4.1. Doplniť do `GameManager`
```gdscript
signal all_quests_completed          # vyšle sa, keď sú hotové VŠETKY questy

func _update_quest_progress(...):
    ...
    if q.current >= q.target:
        q.completed = true
        quest_updated.emit(i)
        if _all_done():
            all_quests_completed.emit()

func _all_done() -> bool:
    for q in active_quests:
        if not q.completed: return false
    return not active_quests.is_empty()
```

### 4.2. Pre „kill" levely zabezpečiť smrť nepriateľa
V `frog.gd` pridať `die()` (vyvolá ho útok hráča), ktoré na konci zavolá
`GameManager.notify_enemy_killed()` — tá funkcia už v `GameManager` existuje.
Quest sa pridá ako `add_quest("enemy_kill", 3, "Zabij žáby")`.

### 4.3. Nová scéna `LevelExit` (znovupoužiteľná pre oba typy)
`scenes/levels/level_exit.tscn` = `Area2D` + `CollisionShape2D` (+ voliteľne
sprite dverí/portálu). Skript:
```gdscript
extends Area2D
@export_file("*.tscn") var next_level: String
var _unlocked := false

func _ready():
	GameManager.all_quests_completed.connect(_unlock)
	body_entered.connect(_on_body_entered)

func _unlock():
	_unlocked = true
	# tu zapni vizuál/označenie, že sa dá prejsť ďalej

func _on_body_entered(body):
	if _unlocked and body.is_in_group("player"):
		GameManager.reset_game()          # vyčisti mince/questy pre ďalší level
		get_tree().change_scene_to_file(next_level)
```
V každom leveli umiestniš `LevelExit` na koniec mapy a v inšpektore nastavíš
`next_level` na cestu k ďalšej scéne. Quest typ (coins/kill) určuje len to, čím
sa zóna „odomkne" — logika prechodu je rovnaká.

### 4.4. Tok
```
level → quest (coins | kill) → all_quests_completed → odomkne LevelExit
      → hráč vojde do zóny → change_scene_to_file(next_level)
```

---

## 5. Intro / príbeh (hotové)
- Nahradený čierny low-visibility kontajner **sivým pixel-art panelom** s
  hranatými okrajmi (`story_dialog.tscn`), prispôsobuje sa dĺžke textu.
- Hra **čaká** (pauza), **MEDZERNÍK** posúva stránky: ovládanie → príbeh (2 strany)
  → ZAČÍT. Texty sú per-level konfigurovateľné v inšpektore (`pages`).
- Príbeh preložený do češtiny.
