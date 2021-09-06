// IGT timer autosplitter
// Coding: Jujstme
// Version: 2.0
// contacts: just.tribe@gmail.com
// Discord: https://discord.com/invite/XRsRwRU
// Please do contact me if you have issues with the script

state("Sonic Colors - Ultimate") {}

init 
{
	// Basic check
	if (!game.Is64Bit()) throw new Exception("Not a 64bit application! Check if you're running the correct exe!");

	// Custom functions
	vars.bitCheck = new Func<string, int, bool>((string plotEvent, int b) => ((byte)(vars.watchers[plotEvent].Current) & (1 << b)) != 0);

	// Declare the watchers variable
	vars.watchers = new MemoryWatcherList();

	// Initialize variables needed for signature scanning
	var scanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);
	IntPtr ptr = IntPtr.Zero;

	// Run start (Any% and All Chaos Emeralds) - can be used also for signalling a reset in those two runs
	ptr = scanner.Scan(new SigScanTarget(5,
		"74 2B",                 // je "Sonic colors - Ultimate.exe"+16F3948
		"48 8B 0D ????????"));   // mov rcx,["Sonic colors - Ultimate.exe"+52462A8]
	if (ptr == IntPtr.Zero) throw new Exception("Could not find address - stage completion pointers");
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x120)) { Name = "runStart" });

	// Current level data pointer
	ptr = scanner.Scan(new SigScanTarget(5,
		"31 C0",                 // xor eax,eax
		"48 89 05 ????????"));   // mov ["Sonic colors - Ultimate.exe"+52465C0],rax
	if (ptr == IntPtr.Zero) throw new Exception("Could not find address - IGT!");
	// IGT
	vars.watchers.Add(new MemoryWatcher<float>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x0, 0x270)) { Name = "IGT", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });
	// Level completion flag
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x0, 0x110)) { Name = "goalRingReached", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });
	// Level ID
	vars.watchers.Add(new StringWatcher(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x0, 0xE0), 6) { Name = "levelID" });
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x0, 0xE0)) { Name = "levelID_numeric", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });  // Needed because StringWatcher doesn't allow to set a value to zero when the pointer becomes invalid

	// Egg Shuttle data pointer
	ptr = scanner.Scan(new SigScanTarget(5,
		"76 0C",                 // jna "Sonic Colors - Ultimate.exe"+16DF25C
		"48 8B 0D ????????"));   // mov rcx,["Sonic colors - Ultimate.exe"+5245658]
	if (ptr == IntPtr.Zero) throw new Exception("Could not find address - Egg Shuttle data!");

	// Egg Shuttle total levels (indicates the total number of stages included in Egg Shuttle mode)
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x8, 0x38, 0x68, 0x110, 0x0)) { Name = "eggShuttle_totalStages", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });
	// Egg Shuttle progressive level ID
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x8, 0x38, 0x68, 0x110, 0xB8)) { Name = "eggShuttle_progressiveID", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });
	
	// Define Dictionary defining each stage in the game
	vars.levels = new Dictionary<string, string> {
		// Tropical Resort
		{"stg110", "tropicalResortAct1"},
		{"stg130", "tropicalResortAct2"},
		{"stg120", "tropicalResortAct3"},
		{"stg140", "tropicalResortAct4"},
		{"stg150", "tropicalResortAct5"},
		{"stg160", "tropicalResortAct6"},
		{"stg190", "tropicalResortBoss"},
		// Sweet Mountain
		{"stg210", "sweetMountainAct1"},
		{"stg230", "sweetMountainAct2"},
		{"stg220", "sweetMountainAct3"},
		{"stg260", "sweetMountainAct4"},
		{"stg240", "sweetMountainAct5"},
		{"stg250", "sweetMountainAct6"},
		{"stg290", "sweetMountainBoss"},
		// Starlight Carnival
		{"stg310", "starlightCarnivalAct1"},
		{"stg330", "starlightCarnivalAct2"},
		{"stg340", "starlightCarnivalAct3"},
		{"stg350", "starlightCarnivalAct4"},
		{"stg320", "starlightCarnivalAct5"},
		{"stg360", "starlightCarnivalAct6"},
		{"stg390", "starlightCarnivalBoss"},
		// Planet Wisp
		{"stg410", "planetWispAct1"},
		{"stg440", "planetWispAct2"},
		{"stg450", "planetWispAct3"},
		{"stg430", "planetWispAct4"},
		{"stg460", "planetWispAct5"},
		{"stg420", "planetWispAct6"},
		{"stg490", "planetWispBoss"},
		// Aquarium Park
		{"stg510", "aquariumParkAct1"},
		{"stg540", "aquariumParkAct2"},
		{"stg550", "aquariumParkAct3"},
		{"stg530", "aquariumParkAct4"},
		{"stg560", "aquariumParkAct5"},
		{"stg520", "aquariumParkAct6"},
		{"stg590", "aquariumParkBoss"},
		// Asteroid Coaster
		{"stg610", "asteroidCoasterAct1"},
		{"stg630", "asteroidCoasterAct2"},
		{"stg640", "asteroidCoasterAct3"},
		{"stg650", "asteroidCoasterAct4"},
		{"stg660", "asteroidCoasterAct5"},
		{"stg620", "asteroidCoasterAct6"},
		{"stg690", "asteroidCoasterBoss"},
		// Terminal Velocity
		{"stg710", "terminalVelocityAct1"},
		{"stg720", "terminalVelocityBoss"},
		{"stg790", "terminalVelocityAct2"},
		// Sonic Simulator
		{"stgD10", "sonicSim1-1"},
		{"stgB20", "sonicSim1-2"},
		{"stgE50", "sonicSim1-3"},
		{"stgD20", "sonicSim2-1"},
		{"stgB30", "sonicSim2-2"},
		{"stgF30", "sonicSim2-3"},
		{"stgG10", "sonicSim3-1"},
		{"stgG30", "sonicSim3-2"},
		{"stgA10", "sonicSim3-3"},
		{"stgD30", "sonicSim4-1"},
		{"stgG20", "sonicSim4-2"},
		{"stgC50", "sonicSim4-3"},
		{"stgE30", "sonicSim5-1"},
		{"stgB10", "sonicSim5-2"},
		{"stgE40", "sonicSim5-3"},
		{"stgG40", "sonicSim6-1"},
		{"stgC40", "sonicSim6-2"},
		{"stgF40", "sonicSim6-3"},
		{"stgA30", "sonicSim7-1"},
		{"stgE20", "sonicSim7-2"},
		{"stgC10", "sonicSim7-3"}};

	// Define basic status variables we need in the run
	vars.totalIGT = (double)0;
	vars.isEggShuttle = false;
}

startup
{	
	settings.Add("levelSplitting", true, "Automatic splitting configuration");
	
	// Tropical Resort
	settings.Add("tropicalResort", true, "Tropical Resort", "levelSplitting");
	settings.Add("tropicalResortAct1", true, "Act 1", "tropicalResort");
	settings.Add("tropicalResortAct2", true, "Act 2", "tropicalResort");
	settings.Add("tropicalResortAct3", true, "Act 3", "tropicalResort");
	settings.Add("tropicalResortAct4", true, "Act 4", "tropicalResort");
	settings.Add("tropicalResortAct5", true, "Act 5", "tropicalResort");
	settings.Add("tropicalResortAct6", true, "Act 6", "tropicalResort");
	settings.Add("tropicalResortBoss", true, "BOSS",  "tropicalResort");

	// Sweet Mountain
	settings.Add("sweetMountain", true, "Sweet Mountain", "levelSplitting");
	settings.Add("sweetMountainAct1", true, "Act 1", "sweetMountain");
	settings.Add("sweetMountainAct2", true, "Act 2", "sweetMountain");
	settings.Add("sweetMountainAct3", true, "Act 3", "sweetMountain");
	settings.Add("sweetMountainAct4", true, "Act 4", "sweetMountain");
	settings.Add("sweetMountainAct5", true, "Act 5", "sweetMountain");
	settings.Add("sweetMountainAct6", true, "Act 6", "sweetMountain");
	settings.Add("sweetMountainBoss", true, "BOSS",  "sweetMountain");

	// Starlight Carnival
	settings.Add("starlightCarnival", true, "Starlight Carnival", "levelSplitting");
	settings.Add("starlightCarnivalAct1", true, "Act 1", "starlightCarnival");
	settings.Add("starlightCarnivalAct2", true, "Act 2", "starlightCarnival");
	settings.Add("starlightCarnivalAct3", true, "Act 3", "starlightCarnival");
	settings.Add("starlightCarnivalAct4", true, "Act 4", "starlightCarnival");
	settings.Add("starlightCarnivalAct5", true, "Act 5", "starlightCarnival");
	settings.Add("starlightCarnivalAct6", true, "Act 6", "starlightCarnival");
	settings.Add("starlightCarnivalBoss", true, "BOSS",  "starlightCarnival");

	// Planet Wisp
	settings.Add("planetWisp", true, "Planet Wisp", "levelSplitting");
	settings.Add("planetWispAct1", true, "Act 1", "planetWisp");
	settings.Add("planetWispAct2", true, "Act 2", "planetWisp");
	settings.Add("planetWispAct3", true, "Act 3", "planetWisp");
	settings.Add("planetWispAct4", true, "Act 4", "planetWisp");
	settings.Add("planetWispAct5", true, "Act 5", "planetWisp");
	settings.Add("planetWispAct6", true, "Act 6", "planetWisp");
	settings.Add("planetWispBoss", true, "BOSS",  "planetWisp");

	// Aquarium Park
	settings.Add("aquariumPark", true, "Aquarium Park", "levelSplitting");
	settings.Add("aquariumParkAct1", true, "Act 1", "aquariumPark");
	settings.Add("aquariumParkAct2", true, "Act 2", "aquariumPark");
	settings.Add("aquariumParkAct3", true, "Act 3", "aquariumPark");
	settings.Add("aquariumParkAct4", true, "Act 4", "aquariumPark");
	settings.Add("aquariumParkAct5", true, "Act 5", "aquariumPark");
	settings.Add("aquariumParkAct6", true, "Act 6", "aquariumPark");
	settings.Add("aquariumParkBoss", true, "BOSS",  "aquariumPark");

	// Asteroid Coaster
	settings.Add("asteroidCoaster", true, "Asteroid Coaster", "levelSplitting");
	settings.Add("asteroidCoasterAct1", true, "Act 1", "asteroidCoaster");
	settings.Add("asteroidCoasterAct2", true, "Act 2", "asteroidCoaster");
	settings.Add("asteroidCoasterAct3", true, "Act 3", "asteroidCoaster");
	settings.Add("asteroidCoasterAct4", true, "Act 4", "asteroidCoaster");
	settings.Add("asteroidCoasterAct5", true, "Act 5", "asteroidCoaster");
	settings.Add("asteroidCoasterAct6", true, "Act 6", "asteroidCoaster");
	settings.Add("asteroidCoasterBoss", true, "BOSS",  "asteroidCoaster");

	// Terminal Velocity
	settings.Add("terminalVelocity", true, "Asteroid Coaster", "levelSplitting");
	settings.Add("terminalVelocityAct1", true, "Act 1", "terminalVelocity");
	settings.Add("terminalVelocityBoss", true, "BOSS",  "terminalVelocity");
	settings.Add("terminalVelocityAct2", true, "Act 2", "terminalVelocity");

	// Sonic Simulator
	settings.Add("sonicSimulator", true, "Sonic Simulator", "levelSplitting");
	settings.Add("sonicSim1-1", true, "1-1", "sonicSimulator");
	settings.Add("sonicSim1-2", true, "1-2", "sonicSimulator");
	settings.Add("sonicSim1-3", true, "1-3", "sonicSimulator");
	settings.Add("sonicSim2-1", true, "2-1", "sonicSimulator");
	settings.Add("sonicSim2-2", true, "2-2", "sonicSimulator");
	settings.Add("sonicSim2-3", true, "2-3", "sonicSimulator");
	settings.Add("sonicSim3-1", true, "3-1", "sonicSimulator");
	settings.Add("sonicSim3-2", true, "3-2", "sonicSimulator");
	settings.Add("sonicSim3-3", true, "3-3", "sonicSimulator");
	settings.Add("sonicSim4-1", true, "4-1", "sonicSimulator");
	settings.Add("sonicSim4-2", true, "4-2", "sonicSimulator");
	settings.Add("sonicSim4-3", true, "4-3", "sonicSimulator");
	settings.Add("sonicSim5-1", true, "5-1", "sonicSimulator");
	settings.Add("sonicSim5-2", true, "5-2", "sonicSimulator");
	settings.Add("sonicSim5-3", true, "5-3", "sonicSimulator");
	settings.Add("sonicSim6-1", true, "6-1", "sonicSimulator");
	settings.Add("sonicSim6-2", true, "6-2", "sonicSimulator");
	settings.Add("sonicSim6-3", true, "6-3", "sonicSimulator");
	settings.Add("sonicSim7-1", true, "7-1", "sonicSimulator");
	settings.Add("sonicSim7-2", true, "7-2", "sonicSimulator");
	settings.Add("sonicSim7-3", true, "7-3", "sonicSimulator");
}

update
{
	// Update watchers
	vars.watchers.UpdateAll(game); 

	// The game calculates the IGT for each stage by simply truncating the float value to the second decimal
	current.gameIGT = Convert.ToDouble(Math.Truncate(vars.watchers["IGT"].Current * 100) / 100);
	
	// Level completion flag - becomes true when you complete a level, regardless of the level or game mode
	current.goalRingReached = vars.bitCheck("goalRingReached", 5);

	// Variables that need to be managed only when the run hasn't started yet
	if (timer.CurrentPhase == TimerPhase.NotRunning)
	{
		vars.totalIGT = (double)0; // If the timer is stopped (for example when you reset a run) make sure to reset the IGT variable
		vars.isEggShuttle = vars.watchers["eggShuttle_totalStages"].Current > 0; // Check which game mode you're in
	}

	// IGT logic: Use an internal totalIGT variable in which we will store the accumulated IGT every time the game IGT resets
	if (vars.watchers["IGT"].Old != 0 && vars.watchers["IGT"].Current == 0) vars.totalIGT += vars.watchers["IGT"].Old;
}

start
{
	if (vars.isEggShuttle) {
		return vars.watchers["levelID"].Current == "stg110" && vars.watchers["levelID_numeric"].Old == 0 && vars.watchers["levelID_numeric"].Changed;
	} else {
		return vars.watchers["runStart"].Old == 35 && vars.watchers["runStart"].Current == 110;
	}
}

reset
{
	return (vars.watchers["runStart"].Old == 110 && vars.watchers["runStart"].Current == 35);
}

split
{
	// If in Terminal Velocity Act 2, or if in the last stage of Egg Shuttle, you need to split as soon as the timer freezes
	if (vars.watchers["levelID"].Old == "stg790") {
		return current.goalRingReached && !old.goalRingReached && settings["terminalVelocityAct2"];
	} else if (vars.isEggShuttle && vars.watchers["eggShuttle_progressiveID"].Current == vars.watchers["eggShuttle_totalStages"].Current - 1) {
		return current.goalRingReached && !old.goalRingReached && settings[vars.levels[vars.watchers["levelID"].Current]];
	} else {
	// Otherwise, split when you leave the results screen
		return !current.goalRingReached && old.goalRingReached && settings[vars.levels[vars.watchers["levelID"].Old]];
	}
}

gameTime
{
	return TimeSpan.FromSeconds(vars.totalIGT + current.gameIGT);
}

isLoading
{
	return true;
}
