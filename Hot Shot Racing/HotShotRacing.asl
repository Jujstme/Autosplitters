// IGT timer autosplitter for Hot Shot Racing
// Coding: Jujstme
// Version: 1.0
// In case of bugs, please contact me at just.tribe@gmail.com

state("HotshotRacing", "v1.0")
{
	float runstart: 0x12F5F40, 0x2A8;								// For other modes. Becomes 1 when you confirm the character selection
	byte racestatus: 0x12F5EEC;										// 0 idle; 1 stage intro: 3 countdown; 4 racing; 5 results screen
	byte racecompleted: 0x12F631C;									// becomes 1 when completing a race, becomes 3 in case of TimeOut
	float igt: 0x12F5F10, 0x4;										// starts at the start of every race and stops at the results screen
	float totalracetime: 0x12F5EB8, 0x0, 0xAF8, 0x0, 0xE8, 0x34;	// updates itself each time you complete a lap (final lap included)
	byte trackorder: 0x12F7138;										// Becomes 4 at the end of a GP

}

init
{
	if (modules.First().ModuleMemorySize == 0x144C000) {
		version = "v1.0";
	} else {
		version = "unsupported";
	    MessageBox.Show("This game version is currently not supported. Autosplitting and in-game timer calculation will be disabled.", "LiveSplit Auto Splitter - Unsupported Game Version");
	}
}

startup
{
	vars.totaligt = 0;
	vars.progressIGT = 0;

	settings.Add("GPsplit", false, "Split only at the final race of each Grand Prix");
	settings.SetToolTip("GPsplit", "If enabled, LiveSplit will trigger a split only upon completion of a Grand Prix.\nIf disabled, LiveSplit will trigger a split at the completion of each race.\n\nDefault: disabled");
}

start
{
	// Reset the variables if you reset a run
	vars.totaligt = 0;
	vars.progressIGT = 0;
    
	// Autostart will be triggered in accordance to speedrun.com rulings
	// Whenever the "3" appears at the countdown before the start of the first race of the Grand Prix
	return(current.runstart >= 2 && current.igt == 0 && current.racestatus == 3 && current.trackorder == 0);
}


update
{
  // If the game version is unsupported, disable the autosplitter completely
  if (version == "unsupported") {
    return false;
  } else {
		// During a race, the IGT is calculated by the game and is added to the total
		if (current.racecompleted == 0)	{
			
			// If you restart an event or a race, the IGT of the failed race is still considered and added
			if (old.igt != 0 && current.igt == 0 && old.racestatus == 4) {
				vars.totaligt = old.igt + vars.totaligt;
				vars.progressIGT = vars.totaligt;
			}
			else
			{
				vars.progressIGT = current.igt + vars.totaligt;
			}
		}

		// How to behave the moment you complete a race:
		if (current.racecompleted == 1 && old.racecompleted == 0)
		{
			vars.totaligt = (Math.Truncate(1000 * (current.totalracetime + vars.totaligt)) / 1000);
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
	// Split automatically once you reach the finish line at the end of each track
	if (settings["GPsplit"]) {
		return (current.trackorder == 4 && current.racecompleted == 1 && old.racecompleted == 0);
	}
	else
	{
		return (current.racecompleted == 1 && old.racecompleted == 0);
	}
}

isLoading
{
	return true;
}