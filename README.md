# questHelper
[TES3MP] Script that protects quest items from being sold or dropped and allows each player to pick up one instance of that item regardless of whether another player picked it up before

**UPDATE 19.2.2020 - Redownload questHelper.lua and questItems.lua (optimizations and fixes), delete questHelper.json (optimization)**

## Disclaimer

I'm aware that there is ```config.disallowedDeleteRefIds``` that perfectly does the part where one object is available to multiple players and when Player1 picks it up it becomes invisible for him not affecting visibility for another Player that didn't interact with the object before but I wanted to have an emergency command (admin/moderator/owner rank required) that could re-enable certain item for specific player if needed (server crashes, inventory is not properly saved or any other reason) 

## Files description
- questHelper.lua -- main script file
- merchants.json -- list of Morrowind merchants (source: https://en.uesp.net/wiki/Morrowind:Merchants)
- questItems.lua -- INCOMPLETE list of quest items, for now it only has ```Dwemer puzzle box``` as an example and for testing

## What does not work:
- if you try to sell quest item along with non quest item, you will lose your non quest items and receive no gold for them but you will get your quest items back
- quest items in containers don't work (ToDo)

## Installation:

1. Download ```questHelper.lua``` and place it in ```server/scripts/custom```
2. Download ```merchants.json``` and place it in ```server/data/custom```
3. Download ```questItems.lua``` and place it in ```server/scripts```
4. Open ```customScripts.lua``` and add there ```require("custom.questHelper")```

## Available commands:

1. ```/qhhelp``` -- brings up list of all available commands
2. ```/qhlist``` -- *command to re-enable specific item for specific player*; brings up list of all registered quest items (those in ```questItems.lua```), after clicking an item and pressing 'OK', you'll be redirected to another list where you can choose which player will be affected (if he had already picked the item up)

## Brief showcase of the item protection:

1. Protection from placing it in world
2. Protection from placing item in container
3. Protection from selling item to merchant (only those listed in ```merchants.json```)
(Player doesn't lose his item, nor gold nor does merchant's inventory contain that item preventing item duplication, hopefully)

https://www.youtube.com/watch?v=UKt4LvBBh1g

## Credits:
- urm - I copied and modified some functions from his VisualHarvesting script; advices on preventing item from being placed
- Rickoff - sale protection advices
- Wujek - testing
