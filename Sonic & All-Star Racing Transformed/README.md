# Sonic & All-Stars Racing Transformed

## Autosplitter
This autosplitter works on the PC Steam release of S&ASRT.
The script fully supports all speedrun categories, although it's still untested on World Tour 100%. If somebody wants to help improve the script, he's totally free to do so.

## Behavior
* The timer will automatically start when you confirm your character selection at the first track for both All-Cups and World Tour categories
* In GP mode, splits are triggered as soon as you cross the finish line at the end of each track
* In World Tour, splits are triggered whenever you succesfully complete an event and gains stars for doing so. Failing an event will not trigger a split
* The in-game timer is grabbed from the game directly. Due to how the game behaves when showing the total time for a race, there might be a 1 or 2 ms difference between the time shown by LiveSplit and the time displayed by the game. The time displayed by LiveSplit is more accurate anyway :)

## Note
* This autosplitter calculates the IGT, but remember that speedruns for this game are timed RTA
