# Sonic Colors: Ultimate

## Autosplitter
LiveSplit autosplitter designed to handle automatic split and in-game timer calculation for Sonic Colors: Ultimate.

## Supported versions
The script is to be used with the PC version of the game only.

## Autosplitting behavior
* For Any% runs, the timer will automatically start upon confirming navigator settings upon starting a new game, in accordance to speedrun.com rules for Any% category
* For Egg Shuttle runs, the timer will automatically start upon loading the first level in Egg Shuttle mode (Tropical Resort Act 1)
* The script assumes you are running Egg Shuttle if it detects a savefile. Otherwise, it assumes an Any% run
* If the timer is already running, selecting "New Game" in the main menu will cause it to automatically reset, regardless of the category you're running
* Autosplitting in Any% is performed upon first-time completion of each level, whereas in Egg Shuttle it's performed automatically at the end of every level (this option can be configured in the settings, if you wish to reduce the number of total splits)
* Automatic in-game timer calculation is provided by the script
