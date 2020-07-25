// Autosplitter by Sora, R3FR4G, Jellyfisher and Jujstme
// Made only thanks to the contributions from above.
// Thanks to all guys who helped in writing this
// Coding: Jujstme
// contacts: just.tribe@gmail.com

state("Sonic & SEGA All-Stars Racing")
{
    byte runStart: 0x82A044;				// Self-explanatory
	byte raceType: 0x8E7068, 0xAD0;			// 0 = Grand Prix, 3 = Mission; It's the main menu option used to choose the game mode
	byte missionEvent: 0x912355; 			// A hacky solution to determine if you're running a normal race or a GP in mission mode. It's 10 (0xA) in races
	byte missionEventGP: 0x9124F0, 0x14;	// Becomes 3 in cups in mission mode; Becomes 4 for all-cups runs. Used by the game to determine how many events are in cups. It's an invalid pointer in any other mode
	byte cuphandler: 0x9124F4;				// Internal counter used by the game to determine which race of the cup you're playing into
	byte ranking: 0x8F7A68, 0x4;			// Ranking system used in mission mode. Needs to be 2 or less (A ranking) to complete missions
	byte runSplit: 0x8F7A6C;				// Self-explanatory
	uint globalFrameCountAtGo: 0x8F7A80;	// Internal 50hz IGT. Needed in mission mode
	byte currentLap: 0x8F7A68, 0x74;		// Reports which lap you're currently into
	uint lap0: 0x8F7A68, 0x6C, 0x0;			// Internal timer for lap 0 (before you cross the start line)
	uint lap1: 0x8F7A68, 0x6C, 0x4;			// Internal timer for lap 1
	uint lap2: 0x8F7A68, 0x6C, 0x8;			// Internal timer for lap 2
	uint lap3: 0x8F7A68, 0x6C, 0xC;			// Internal timer for lap 3
	uint totalLap: 0x8F7A68, 0x68;			// Reports the "fixed" timer for the race up to the previous lap. Used to determine the time at the end of the race with 100% accuracy
}

startup
{
   vars.totaligt = 0;
   vars.progressIGT = 0;
   vars.racetime = 0;
   // refreshRate = 60;
   settings.Add("AAArankSplit", false, "All missions: split only at AAA rank");
   settings.SetToolTip("AAArankSplit", "If enabled, LiveSplit will trigger a split for All Mission categories only when you get a AAA rank.\nIf disabled, LiveSplit will trigger a split when you complete a mission successfully, regardless of the rank.\nYou need to enable this options if you wish to run the \"AAA\" subcategory of All Missions run.\n\nDefault: disabled");
   settings.Add("GPsplit", false, "All Cups: split only at the final race of each cup");
   settings.SetToolTip("GPsplit", "If enabled, LiveSplit will trigger a split for All Cups runs when you complete a cup.\nIf disabled, LiveSplit will trigger a split at the completion of each race.\n\nDefault: disabled");

}

start
{
   // Reset the IGT variables if you reset a run
   vars.totaligt = 0;
   vars.progressIGT = 0;
   vars.racetime = 0;
   
   // The run starts when conferming selection of the first event in mission mode or in GP mode
   return (current.runStart == 1 && old.runStart == 0);
}


update
{
	// When resetting a race this script will keep track of the IGT until now
	if (old.globalFrameCountAtGo != 0 && current.globalFrameCountAtGo < old.globalFrameCountAtGo) {
	vars.progressIGT = vars.progressIGT + vars.racetime;
	vars.racetime = 0;
	}
	
	// General behaviour for all-cups speedrun
	// The game grabs the time directly from memory and updates it at each lap
	// Might not be 100% accurate during the race
	// However, it WILL get the correct time at the end of the race regardless
	if (current.raceType == 0) {
		// Time is the sum of the previous laps + current lap
		// The game uses 4 laps internally (lap 0 is the very start, before you cross the start line)
		if (current.currentLap < 4) {
			if (current.currentLap == 0) {
				vars.racetime = current.lap0;
			} else if (current.currentLap == 1) {
				vars.racetime = current.totalLap + current.lap1;
			} else if (current.currentLap == 2) {
				vars.racetime = current.totalLap + current.lap2;
			} else if (current.currentLap == 3) {
				vars.racetime = current.totalLap + current.lap3;
			}
		} else if (current.currentLap == 4) {
			vars.racetime = current.totalLap;
		}
		
		// Time is calculated and added to the total
		vars.racetime = (Math.Truncate((1000 * ((double)vars.racetime/204800))) / 1000);
		
		
	} else if (current.raceType == 3) {
	
		// General behaviour for Mission mode
		// The script will use the internal frame counter to determine the time
		// However, in races that are inside mission mode, the same timing system employed in all-cups runs will be used
		
		// In in a normal race within mission mode, the standard timing system will be used
		// The only difference is mission mode races have 2 laps instead of 3
		if (current.missionEvent == 10) {
			if (current.currentLap < 3) {
				if (current.currentLap == 0) {
					vars.racetime = current.lap0;
				} else if (current.currentLap == 1) {
					vars.racetime = current.totalLap + current.lap1;
				} else if (current.currentLap == 2) {
					vars.racetime = current.totalLap + current.lap2;
				}
			} else if (current.currentLap == 3) {
				vars.racetime = current.totalLap;
			}
			vars.racetime = (Math.Truncate((1000 * ((double)vars.racetime/204800))) / 1000);
	
		} else {	
		
			// Frame-based timing system
			vars.racetime = ((double)current.globalFrameCountAtGo) / 50;
			
			// This snippet fixes the 1 frame time shift in mission mode
			if (current.runSplit == 1 || current.runSplit == 2) {
				vars.racetime = vars.racetime - 0.02;
			}
		}
	}
	
	// Final time calculation
	vars.totaligt = vars.progressIGT + vars.racetime;
}



split
{
	if (current.raceType == 0) {
		// In GP mode, split whenever you cross the finish line, regardless of anything
		if (settings["GPsplit"]) {
			return ((current.runSplit == 1 || current.runSplit == 2) && old.runSplit == 0 && old.cuphandler == 3);
		}
		else
		{
			return ((current.runSplit == 1 || current.runSplit == 2) && old.runSplit == 0);
		}
	} else if (current.raceType == 3) {
		// In mission mode, split when you complete an event successfully
		if ((current.runSplit == 1 || current.runSplit == 2) && old.runSplit == 0) {
			if (current.missionEvent == 10 && current.missionEventGP == 3) {
				if (settings["AAArankSplit"]) {
					return (old.cuphandler == 2 && current.ranking == 0);
				}
				else
				{
					return (old.cuphandler == 2 && current.ranking <= 2);
				}
			} else {
				if (settings["AAArankSplit"]) {
					return (current.ranking == 0);
				}
				else
				{
					return (current.ranking <= 2);
				}
			}
		}
	}
}

gameTime
{
	return TimeSpan.FromSeconds(vars.totaligt);	
}

isLoading
{
	return true;
}