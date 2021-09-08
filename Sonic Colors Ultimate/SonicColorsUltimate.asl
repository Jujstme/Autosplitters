// IGT timer autosplitter
// Coding: Jujstme
// Version: 2.2
// contacts: just.tribe@gmail.com
// Discord: https://discord.gg/XRsRwRU
// Please do contact me if you have issues with the script

state("Sonic Colors - Ultimate") {}

init 
{
	// Basic check
	if (!game.Is64Bit()) throw new Exception("Not a 64bit application! Check if you're running the correct exe!");

	// The game abuses bitmasks so we need a way to easily check single bits inside a byte
	vars.bitCheck = new Func<string, int, bool>((string input, int b) => (vars.watchers[input].Current & (1 << b)) != 0);

	// Main watchers variable
	vars.watchers = new MemoryWatcherList();

	// Initialize variables needed for signature scanning
	var scanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);
	IntPtr ptr = IntPtr.Zero;

	// Run start (Any% and All Chaos Emeralds)
	// Corresponds to the "name" assigned to the internal savefile
	// New game = "########"
	// Otherwise = "no-name"
	// Can be used for signalling a reset
	ptr = scanner.Scan(new SigScanTarget(5,
		"74 2B",                 // je "Sonic Colors - Ultimate.exe"+16F3948
		"48 8B 0D ????????"));   // mov rcx,["Sonic Colors - Ultimate.exe"+52462A8]
	if (ptr == IntPtr.Zero) throw new Exception("Could not find address - stage completion pointers");
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x120)) { Name = "runStart" });

	// Current level data pointer
	// This region of memory contains basic data about the current level you're in, such as IGT, rings, score, etc. 
	// Also has a lot of flags (inside bitmasks) I didn't bother to investigate
	ptr = scanner.Scan(new SigScanTarget(5,
		"31 C0",                 // xor eax,eax
		"48 89 05 ????????"));   // mov ["Sonic Colors - Ultimate.exe"+52465C0],rax
	if (ptr == IntPtr.Zero) throw new Exception("Could not find address - level data pointer!");
	// IGT
	vars.watchers.Add(new MemoryWatcher<float>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x0, 0x270)) { Name = "IGT", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull }); // Self-explanatory
	// Level completion flag
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x0, 0x110)) { Name = "goalRingReached", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull }); // Bit 5 gets flipped th emoment the stage is reported by the game as complete and all in-level events stop (eg. IGT stops)
	// Level ID
	vars.watchers.Add(new StringWatcher(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x0, 0xE0), 6) { Name = "levelID" }); // It's a 6-character ID that uniquely reports the level you're in. The IDs are the same as in the Wii version of the game. Check Wii's actstgmission.lua for details
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x0, 0xE0)) { Name = "levelID_numeric", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });  // Same address, but with value reported as a byte. Hacky solution to StringWatcher not allowing ReadFailAction.SetZeroOrNull

	// Egg Shuttle data pointer
	// This memory region becomes accessible only when you're inside Egg Shuttle
	ptr = scanner.Scan(new SigScanTarget(5,
		"76 0C",                 // jna "Sonic Colors - Ultimate.exe"+16DF25C
		"48 8B 0D ????????"));   // mov rcx,["Sonic colors - Ultimate.exe"+5245658]
	if (ptr == IntPtr.Zero) throw new Exception("Could not find address - Egg Shuttle data!");
	// Egg Shuttle total levels (indicates the total number of stages included in Egg Shuttle mode)
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x8, 0x38, 0x68, 0x110, 0x0)) { Name = "eggShuttle_totalStages", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull }); // This value is always above 0 so it can be used to report whether you're in egg shuttle or not
	// Egg Shuttle progressive level ID
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x8, 0x38, 0x68, 0x110, 0xB8)) { Name = "eggShuttle_progressiveID", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull }); // Indicates level progression inside Egg Shuttle. Goes from 0 to 44 (44 = Terminal Velocity Act 2). It techically also goes to 45 at the final results screen after Terminal Velocity Act 2
}

startup
{
	// Define an array with the internal codename for easy reference/access
	// The order is the same in which the stages are run in Egg Shuttle
	vars.orderedLevels = new string[]
	{
		"tropicalResortAct1",    "tropicalResortAct2",    "tropicalResortAct3",    "tropicalResortAct4",    "tropicalResortAct5",    "tropicalResortAct6",    "tropicalResortBoss",
		"sweetMountainAct1",     "sweetMountainAct2",     "sweetMountainAct3",     "sweetMountainAct4",     "sweetMountainAct5",     "sweetMountainAct6",     "sweetMountainBoss",
		"starlightCarnivalAct1", "starlightCarnivalAct2", "starlightCarnivalAct3", "starlightCarnivalAct4", "starlightCarnivalAct5", "starlightCarnivalAct6", "starlightCarnivalBoss",
		"planetWispAct1",        "planetWispAct2",        "planetWispAct3",        "planetWispAct4",        "planetWispAct5",        "planetWispAct6",        "planetWispBoss",
		"aquariumParkAct1",      "aquariumParkAct2",      "aquariumParkAct3",      "aquariumParkAct4",      "aquariumParkAct5",      "aquariumParkAct6",      "aquariumParkBoss",
		"asteroidCoasterAct1",   "asteroidCoasterAct2",   "asteroidCoasterAct3",   "asteroidCoasterAct4",   "asteroidCoasterAct5",   "asteroidCoasterAct6",   "asteroidCoasterBoss",
		"terminalVelocityAct1",  "terminalVelocityBoss",  "terminalVelocityAct2",
		"sonicSim1-1",           "sonicSim1-2",           "sonicSim1-3",
		"sonicSim2-1",           "sonicSim2-2",           "sonicSim2-3",
		"sonicSim3-1",           "sonicSim3-2",           "sonicSim3-3",
		"sonicSim4-1",           "sonicSim4-2",           "sonicSim4-3",
		"sonicSim5-1",           "sonicSim5-2",           "sonicSim5-3",
		"sonicSim6-1",           "sonicSim6-2",           "sonicSim6-3",
		"sonicSim7-1",           "sonicSim7-2",           "sonicSim7-3"
	};

	// Define another array with the internal IDs used by the game to define stage you're currently in
	// The order has to match the same order used for vars.orderedLevels
	vars.orderedLevelIDs = new string[]
	{
		"stg110", "stg130", "stg120", "stg140", "stg150", "stg160", "stg190", // Tropical Resort
		"stg210", "stg230", "stg220", "stg260", "stg240", "stg250", "stg290", // Sweet Mountain
		"stg310", "stg330", "stg340", "stg350", "stg320", "stg360", "stg390", // Starlight Carnival
		"stg410", "stg440", "stg450", "stg430", "stg460", "stg420", "stg490", // Planet Wisp
		"stg510", "stg540", "stg550", "stg530", "stg560", "stg520", "stg590", // Aquarium Park
		"stg610", "stg630", "stg640", "stg650", "stg660", "stg620", "stg690", // Asteroid Coaster
		"stg710", "stg790", "stg720",                                         // Terminal Velocity
		"stgD10", "stgB20", "stgE50",                                         // Sonic simulator 1
		"stgD20", "stgB30", "stgF30",                                         // Sonic simulator 2
		"stgG10", "stgG30", "stgA10",                                         // Sonic simulator 3
		"stgD30", "stgG20", "stgC50",                                         // Sonic simulator 4
		"stgE30", "stgB10", "stgE40",                                         // Sonic simulator 5
		"stgG40", "stgC40", "stgF40",                                         // Sonic simulator 6
		"stgA30", "stgE20", "stgC10"                                          // Sonic simulator 7
	};

	// Define basic status variables we use throughout the script
	vars.totalIGT = 0d;        // Note to self: the suffix "d" reports the value as a double (default behaviour for C#)
	vars.isEggShuttle = false; // Very important variable as the main splitting logic checks for this
	
	// Define a Dictionary matching each stage ID with its easy-to-access codename
	vars.levels = new Dictionary<string, string>();
	for (int i = 0; i < vars.orderedLevels.Length; i++) vars.levels.Add(vars.orderedLevelIDs[i], vars.orderedLevels[i]);

	// Add settings allowing the user to customize splitting options
	// The code is ugly AF but it works
	settings.Add("levelSplitting", true, "Automatic splitting configuration");
	// Tropical Resort
	settings.Add("tropicalResort", true, "Tropical Resort", "levelSplitting"); for (int i = 0; i < 7; i++) settings.Add(vars.orderedLevels[i], true, i == 6 ? "BOSS" : "Act " + (i+1).ToString(), "tropicalResort");
	// Sweet Mountain
	settings.Add("sweetMountain", true, "Sweet Mountain", "levelSplitting"); for (int i = 7; i < 14; i++) settings.Add(vars.orderedLevels[i], true, i == 13 ? "BOSS" : "Act " + (i-6).ToString(), "sweetMountain");
	// Starlight Carnival
	settings.Add("starlightCarnival", true, "Starlight Carnival", "levelSplitting"); for (int i = 14; i < 21; i++) settings.Add(vars.orderedLevels[i], true, i == 20 ? "BOSS" : "Act " + (i-13).ToString(), "starlightCarnival");
	// Planet Wisp
	settings.Add("planetWisp", true, "Planet Wisp", "levelSplitting"); for (int i = 21; i < 28; i++) settings.Add(vars.orderedLevels[i], true, i == 27 ? "BOSS" : "Act " + (i-20).ToString(), "planetWisp");
	// Aquarium Park
	settings.Add("aquariumPark", true, "Aquarium Park", "levelSplitting"); for (int i = 28; i < 35; i++) settings.Add(vars.orderedLevels[i], true, i == 34 ? "BOSS" : "Act " + (i-27).ToString(), "aquariumPark");
	// Asteroid Coaster
	settings.Add("asteroidCoaster", true, "Asteroid Coaster", "levelSplitting"); for (int i = 35; i < 42; i++) settings.Add(vars.orderedLevels[i], true, i == 41 ? "BOSS" : "Act " + (i-34).ToString(), "asteroidCoaster");
	// Terminal Velocity
	settings.Add("terminalVelocity", true, "Asteroid Coaster", "levelSplitting"); for (int i = 42; i < 45; i++) settings.Add(vars.orderedLevels[i], true, i == 43 ? "BOSS" : i == 44 ? "Act 2" : "Act 1", "terminalVelocity");
	// Sonic Simulator
	settings.Add("sonicSimulator", true, "Sonic Simulator", "levelSplitting"); for (int i = 45; i < 66; i++) settings.Add(vars.orderedLevels[i], true, vars.orderedLevels[i].Substring(vars.orderedLevels[i].IndexOf("m") + 1).Replace('-', '—'), "sonicSimulator");
}

update
{
	// Update watchers
	vars.watchers.UpdateAll(game); 

	// Level completion flag - becomes true when you complete a level, regardless of the level or game mode
	current.goalRingReached = vars.bitCheck("goalRingReached", 5);

	// Assume the IGT is always zero if you are in the credits stage or outside a stage
	// This prevents a possible overflowException that sometimes occurs if you load the credits while the timer is running
	// This behaviour is caused by the IGT often reporting insanely huge IGT values inside the credits
	if (vars.watchers["levelID_numeric"].Current == 8 || vars.watchers["levelID_numeric"].Current == 0) vars.watchers["IGT"].Current = 0;
	
	// The game calculates the IGT for each stage by simply truncating the float value to the second decimal.
	// In order to make the timer match the displayed IGT inside the game, we need to do the same.
	// This also implicitly converts the IGT from float to double (C# really doesn't like to work with floats).
	current.gameIGT = Math.Truncate(vars.watchers["IGT"].Current * 100) / 100;

	// Another IGT logic: Use an internal totalIGT variable in which we will store the accumulated IGT every time the game IGT resets (eg. when exiting a level)
	if (vars.watchers["IGT"].Old != 0 && vars.watchers["IGT"].Current == 0) vars.totalIGT += old.gameIGT;

	// These variables need to be managed this way when the run hasn't started yet
	// You can put these inside the start section of the autosplitter but you risk the code not being run if the user disables automatic start
	if (timer.CurrentPhase == TimerPhase.NotRunning)
	{
		vars.totalIGT = 0d; // If the timer is stopped (for example when you reset a run) make sure to reset the IGT variable to its default value
		vars.isEggShuttle = vars.watchers["eggShuttle_totalStages"].Current > 0; // Check whether you're in Egg Shuttle or not. This value must not change once the timer started to run.
	}
}

start
{
	if (vars.isEggShuttle)
	{
		// In Egg Shuttle, the run must start the moment Tropical Resort 1 starts loading
		vars.startTrigger = vars.watchers["levelID"].Current == vars.orderedLevelIDs[0] && vars.watchers["levelID_numeric"].Old == 0 && vars.watchers["levelID_numeric"].Changed;
	} else {
		// Outside Egg Shuttle, the run must start the moment a new savefile is created
		// This code has the side effect of starting the timer whenever the game is started with LiveSplit already open
		// so this part might be optimized with time
		vars.startTrigger = vars.watchers["runStart"].Old == 35 && vars.watchers["runStart"].Current == 110;
	}

	return vars.startTrigger;
}

reset
{
	if (vars.isEggShuttle)
	{
		// In Egg Shuttle, a reset is triggered when you exit an uncompleted stage
		// which means you're giving up the run or restarting another one
		vars.resetTrigger = vars.watchers["IGT"].Old != 0 && vars.watchers["IGT"].Current == 0 && !old.goalRingReached;
	} else {
		// A reset must always be triggered whenever you delete your save file
		vars.resetTrigger = vars.watchers["runStart"].Old == 110 && vars.watchers["runStart"].Current == 35;
	}

	return vars.resetTrigger;
}

split
{
	// The script must be prevented from continuously throwing Exceptions whenever you are inside the credits, or whenever the levelID is null
	if (vars.watchers["levelID"].Current == null || vars.watchers["levelID_numeric"].Current == 8) return false;
	
	if (vars.isEggShuttle)
	{
		// If you're in Egg Shuttle, split when the EggShuttle-specific stage counter increases
		// If you're in the last stage of Egg Shuttle, split whenever the timer stops
		vars.StageCounterIncreased = vars.watchers["eggShuttle_progressiveID"].Current == vars.watchers["eggShuttle_progressiveID"].Old + 1 &&
									vars.watchers["eggShuttle_progressiveID"].Old < vars.watchers["eggShuttle_totalStages"].Current - 1 &&
									settings[vars.orderedLevels[vars.watchers["eggShuttle_progressiveID"].Old]];
		vars.LastStageEggShuttleCompleted = current.goalRingReached && !old.goalRingReached &&
									vars.watchers["eggShuttle_progressiveID"].Current == vars.watchers["eggShuttle_totalStages"].Current - 1 &&
									settings[vars.orderedLevels[vars.watchers["eggShuttle_progressiveID"].Old]];
		vars.ShouldSplit = vars.StageCounterIncreased || vars.LastStageEggShuttleCompleted;
	} else {
		// If you're not in Egg Shuttle, the script has to trigger a split when you exit the results screen after completing a stage
		// This code must never be applied to Terminal Velocity Act 2 (see below)
		vars.StageCompleted = !current.goalRingReached && old.goalRingReached && settings[vars.levels[vars.watchers["levelID"].Old]] && vars.watchers["levelID"].Old != vars.orderedLevelIDs[44];
		// If you are in Terminal Velocity Act 2, you need to split as soon as the timer freezes, as it always represents the end of the speedrun
		vars.StageCompletedTVAct2 = current.goalRingReached && !old.goalRingReached && settings[vars.orderedLevels[44]] && vars.watchers["levelID"].Old == vars.orderedLevelIDs[44];
		vars.ShouldSplit = vars.StageCompleted || vars.StageCompletedTVAct2;
	}
	
	return vars.ShouldSplit;
}

gameTime
{
	return TimeSpan.FromSeconds(vars.totalIGT + current.gameIGT);
}

isLoading
{
	return true;
}
