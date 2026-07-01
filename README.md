# Samurai Revenge

Samurai Revenge je moj prvy herny projekt vytvoreny v Godote. Ide o jednoduchu 2D platformovu hru, kde hrac ovlada samuraja, prechadza levelmi, bojuje s nepriatelmi, zbiera mince a plni ulohy.

## O hre

- Hra je postavena ako 2D platformer s viacerymi levelmi.
- Hrac ma zakladny pohyb, skok, sprint a utok mecom.
- Levely obsahuju nepriatelov, portaly, dialogy, hinty a ulohy.
- Quest system sleduje zbieranie minci, porazenie nepriatelov a dosiahnutie portalu.
- NPC Jawy sluzi ako vedlajsia postava, ktora zadava ulohu a po jej splneni da odmenu.

## Struktura projektu

- `scenes/levels/` - hlavne herne levely, uvodna scena a koncova scena.
- `scenes/player/` - scena hraca a jeho UI prvky.
- `scenes/enemies/` - nepriatelia ako zaba a vcela.
- `scenes/items/` - zbieratelne predmety, napr. mince a potion.
- `scenes/ui/` - HUD, quest UI, dialogy, hinty, chest a portal.
- `scenes/side-character/` - NPC postavy.
- `scripts/` - GDScript logika pre hraca, nepriatelov, questy, levely, hudbu a UI.

## Herny postup

Hra zacina uvodnou scenou a pokracuje cez jednotlive levely. Kazdy level ma vlastne ulohy a ciel. Po splneni hlavnych uloh sa otvori portal, ktory posunie hraca dalej. Posledny level konci jednoduchou koncovou scenou.

## Ovládanie

- `A` / `D` - pohyb dolava a doprava
- `Space` - skok
- `Shift` - sprint
- `J` - utok
- `E` - interakcia s NPC

## Assety

Projekt pouziva 2D sprity, hudbu a zvukove efekty pocas vyvoja hry. Cast vizualnych assetov pochadza z itch.io asset packov. Projekt sluzi hlavne ako ucenie Godotu, GDScriptu a zakladov tvorby hier.

## Stav projektu

Projekt je vo vyvoji. Kod, levely aj grafika sa este mozu menit.
