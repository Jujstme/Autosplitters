// IGT timer autosplitter for Team Sonic Racing
// Coding: Jujstme
// Tester:  Nimputs
// Version: 1.4.2 hotfix
// In case of bugs, please contact me at just.tribe@gmail.com

state("GameApp_PcDx11_x64Final", "v1.1")
{
	// Story mode variables
	byte teamadventurestart: 0x11325A0, 0x0;			// Stays 0 in the menu, becomes 1 as soon as you click on the team adventure mode
	byte gamemode: 0x1135E6C;							// Stays at 0 during Team Adventure mode. Becomes 1 in All Tracks categories
	byte requiredlaps: 0x10B18E8, 0x0, 0x110, 0x10;		// number of laps required to finish a race. Usually 3, but it's set as 255 (FF) in special events where laps are irrelevant
	byte stars1: 0x11325A0, 0x48, 0x008, 0x22C;			// Nr. of stars in Team Adventure Chapter 1
	byte stars2: 0x11325A0, 0x48, 0x040, 0x22C;			// Nr. of stars in Team Adventure Chapter 2
	byte stars3: 0x11325A0, 0x48, 0x088, 0x22C;			// Nr. of stars in Team Adventure Chapter 3
	byte stars4: 0x11325A0, 0x48, 0x0C8, 0x22C;			// Nr. of stars in Team Adventure Chapter 4
	byte stars5: 0x11325A0, 0x48, 0x108, 0x22C;			// Nr. of stars in Team Adventure Chapter 5
	byte stars6: 0x11325A0, 0x48, 0x148, 0x22C;			// Nr. of stars in Team Adventure Chapter 6
	byte stars7: 0x11325A0, 0x48, 0x190, 0x22C;			// Nr. of stars in Team Adventure Chapter 7
	float totalracetimeadventure: 0x1132A98;			// Used in place of the IGT in special cases
	
	// Other important variables
	byte runstart: 0x11456A8, 0x50, 0xD44;				// For other modes. Becomes 1 when you confirm the character selection
	byte racerulings: 0x102DE40, 0x340;					// Race rulings. Used to avoid starting the timer when outside the allowed categories
	byte racestatus: 0x10B1920;							// 0 idle; 1 stage intro: 2 team intro; 5 ready; 6 racing; 7 results screen
	byte racecompleted: 0x10B1968;						// becomes 1 when a race or an event ends, regardless of anything
	float igt: 0x10B2FA4;								// starts at the start of every race and stops at the results screen
	float totalracetime: 0x10B18E8, 0x0, 0x110, 0x30;	// updates itself each time you complete a lap (final lap included)
	byte abortrace: 0x102DEA8, 0x25C;					// Used when you reset of abort a race

	// These are used in specific scenarios for the last split in Team Adventure mode
	byte credits: 0x112DF14; 							// Becomes 4 when the credits are rolling
	byte skippedcredits: 0x11351F8, 0x0;				// ID of the message to display on screen. Becomes 8 at the final screen; Used to determine when to split at the end of the run if you skipped the credits
	byte teamadventuretrack: 0x11325A0, 0x11; 			// Internal ID of the selected track for Team Adventure mode
}

state("GameApp_PcDx11_x64Final", "v1.0")
{
	// Story mode variables
	byte teamadventurestart: 0x112B210, 0x0;			// Stays 0 in the menu, becomes 1 as soon as you click on the team adventure mode
	byte gamemode: 0x112EBBC;							// Stays at 0 during Team Adventure mode. Becomes 1 in All Tracks categories
	byte requiredlaps: 0x10AA550, 0x0, 0x110, 0x10;		// number of laps required to finish a race. Usually 3, but it's set as 255 (FF) in special events where laps are irrelevant
	byte stars1: 0x112B210, 0x48, 0x008, 0x22C;			// Nr. of stars in Team Adventure Chapter 1
	byte stars2: 0x112B210, 0x48, 0x040, 0x22C;			// Nr. of stars in Team Adventure Chapter 2
	byte stars3: 0x112B210, 0x48, 0x088, 0x22C;			// Nr. of stars in Team Adventure Chapter 3
	byte stars4: 0x112B210, 0x48, 0x0C8, 0x22C;			// Nr. of stars in Team Adventure Chapter 4
	byte stars5: 0x112B210, 0x48, 0x108, 0x22C;			// Nr. of stars in Team Adventure Chapter 5
	byte stars6: 0x112B210, 0x48, 0x148, 0x22C;			// Nr. of stars in Team Adventure Chapter 6
	byte stars7: 0x112B210, 0x48, 0x190, 0x22C;			// Nr. of stars in Team Adventure Chapter 7
	float totalracetimeadventure: 0x112B708;			// Used in place of the IGT in special cases
	
	// Other important variables
	byte runstart: 0x113E368, 0x50, 0xD44;				// For other modes. Becomes 1 when you confirm the character selection
	byte racerulings: 0x1026BF0, 0x330;					// Race rulings. Used to avoid starting the timer when outside the allowed categories
	byte racestatus: 0x10AA588;							// 0 idle; 1 stage intro: 2 team intro; 5 ready; 6 racing; 7 results screen
	byte racecompleted: 0x10AA690;						// becomes 1 when a race or an event ends, regardless of anything
	float igt: 0x10ABC14;								// starts at the start of every race and stops at the results screen
	float totalracetime: 0x10AA550, 0x0, 0x110, 0x30;	// updates itself each time you complete a lap (final lap included)

	// These are used in specific scenarios for the last split in Team Adventure mode
	byte credits: 0x1126B94; 							// Becomes 4 when the credits are rolling
	byte skippedcredits: 0x112DF80, 0x0; 				// ID of the message to display on screen. Becomes 8 at the final screen; Used to determine when to split at the end of the run if you skipped the credits
	byte teamadventuretrack: 0x112B210, 0x11; 			// Internal ID of the selected track for Team Adventure mode
}

init
{
	if (modules.First().ModuleMemorySize == 0x15E9D000) version = "v1.1";
    if (modules.First().ModuleMemorySize == 0x172CA000) version = "v1.0";
}

startup
{
   vars.totaligt = 0;
   vars.progressIGT = 0;
   vars.finalsplit = 0;
   vars.currentstars = 0;
   vars.oldstars = 0;
   vars.frozenigt = 0;
   refreshRate = 60;
}

start
{
	// Reset the variables if you reset a run
	vars.totaligt = 0;
	vars.progressIGT = 0;
	vars.finalsplit = 0;
	vars.frozenigt = 0;
	vars.currentstars = current.stars1 + current.stars2 + current.stars3 + current.stars4 + current.stars5 + current.stars6 + current.stars7;
    
	// Autostart will be triggered in accordance to speedrun.com rulings
	// ADVENTURE MODE: as soon as you enter the Team Adventure mode
	// ALL RACES CATEGORIES: when you confirm your character selection at the first race
	// As speedrun.com requires Tead Adventure speedruns to run from a clean save file, the timer won't
	// start if you already have some stars in adventure mode (which means your save file is not new)
	return((current.gamemode == 1 && current.runstart == 1 && current.racerulings != 19) || (current.teamadventurestart == 1 && vars.currentstars == 0));
}


update
{

	// During a race, the IGT is calculated by the game (not by LiveSplit) and is added to the total
	if (current.racecompleted == 0)	{
		vars.progressIGT = (Math.Truncate(100 * current.igt) / 100) + vars.totaligt;
		
		// If you restart an event or a race, the IGT of the failed race is still considered and added
		if (current.abortrace == 1 && old.abortrace == 0) vars.frozenigt = vars.progressIGT;
		if (old.igt != 0 && current.igt == 0 && old.racestatus == 6) {
			vars.totaligt = vars.frozenigt;
			vars.progressIGT = vars.totaligt;
			vars.frozenigt = 0;
		}
	}
	
	// The moment you complete a race, the game picks your total racing time and saves it into a different address
	// Also, the game truncates the time to the second decimal. We're going to do the same for consistency purposes
	if(current.racecompleted == 1 && old.racecompleted == 0)
	{
		vars.totaligt = (Math.Truncate(100 * current.totalracetime) / 100) + vars.totaligt;
		vars.progressIGT = vars.totaligt;
		
		// IF YOU ARE IN TEAM ADVENTURE AND YOU ARE DOING A SPECIAL CHALLENGE (eg. daredevil, eggpawn assault, etc.) THE ABOVE WON'T WORK
		// BECAUSE THE GAME LIKES TO USE DIFFERENT ADDRESSES
		// In order to cope with that, we need this snipped of code
		if (current.gamemode == 0 && current.requiredlaps == 255) {
			vars.totaligt = (Math.Truncate(100 * current.totalracetimeadventure) / 100) + vars.totaligt;
			vars.progressIGT = vars.totaligt;
		}
	}
}

gameTime
{
	return TimeSpan.FromSeconds((double)vars.progressIGT);
}

split
{
	// If you are in adventure mode, split whenever the game gives you the stars at the end of the event
	// or, in the case of the final challenge in Thunder Deck, don't split until you reach the end screen (as per speedrun.com rules)
	if (current.gamemode == 0) {
		//  This is requirement is specific to the final event. It's untested outside the any% category
		if (current.teamadventuretrack == 104) {
			if (vars.finalsplit == 0 && (current.credits == 4 || current.skippedcredits == 8)) {
					vars.finalsplit = 1;
			}
			if (vars.finalsplit == 1) {
				vars.finalsplit = 2;
				return (true);
			}
		}
		else
		{
			vars.currentstars = current.stars1 + current.stars2 + current.stars3 + current.stars4 + current.stars5 + current.stars6 + current.stars7;
			vars.oldstars = old.stars1 + old.stars2 + old.stars3 + old.stars4 + old.stars5 + old.stars6 + old.stars7;
 			return (vars.currentstars != vars.oldstars);
		}
	}
	else
	// In standard races during All Tracks categories, split automatically
	// once you reach the finish line at the end of each track
	{
	  return (current.racecompleted == 1 && old.racecompleted == 0);
	}
}

isLoading
{
	return true;
}