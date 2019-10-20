# Team Sonic Racer Autosplitter v1.4.2
This is an autosplitter for the PC Steam release of Team Sonic Racing. It will work with all publicly-released versions of Team Sonic Racing. In case of a new game update, support for it can easily be added.
Credits to Nimputs for  testing the preliminary versions of the splitter, and thanks to Tyapp for giving me useful info I needed to understand how this game manages a couple of weird stuff in memory.
## Behavior
* This sutosplitter works for all speedrun.com categories
* For All Team Races / All Standards Races / All Grand Prix modes, the timer will automatically start when you confirm your character selection at the first track and splits will be automatically triggered at the end of each track. This includes the final split at the last track of the speedrun
* For Team Adventure Any%, the start will be triggered automatically the moment you enter Team Adventure mode. As speedrun.com requires you to speedrun this category from a new savefile, the script will NOT start if you already completed any event in the story mode. The script will automatically split at the end of each story mode event, if you gain at least 1 star at the end of the event (which is required to progress in story mode). In the last event of the speedrun (Showdown race in Thunder Deck) the split will be triggered the moment you reach the credits (or, in case the game skips the credits, as soon as you exit the track after completing it)
* The in-game timer is grabbed from the game directly, which means it's truncated to a tenth of a second. Unfortunately, this is the way the game behaves
* Team Adventure 100% is untested and will probably never be supported (it's a category nobody will ever be interested to run anyway)
