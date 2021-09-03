// IGT timer autosplitter
// Coding: Jujstme
// Version: 1.0
// contacts: just.tribe@gmail.com
// Discord: https://discord.com/invite/XRsRwRU
// Please do contact me if you have issues with the script

state("Sonic Colors - Ultimate") {}

init 
{
	// Basic check
	if (!game.Is64Bit()) throw new Exception("Not a 64bit application! Check if you're running the correct exe!");

	// Declare the watchers variable
	vars.watchers = new MemoryWatcherList();

	// Initialize variables needed for signature scanning
	var scanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);
	IntPtr ptr = IntPtr.Zero;

	// IGT
	ptr = scanner.Scan(new SigScanTarget(5,
		"31 C0",               // xor eax,eax
		"48 89 05 ????????")); // mov ["Sonic colors - Ultimate.exe"+52465C0],rax
	if (ptr == IntPtr.Zero) throw new Exception("Could not find address - IGT!");
	vars.watchers.Add(new MemoryWatcher<float>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x0, 0x270)) { Name = "IGT" });
	vars.watchers["IGT"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

	// Stage completion pointers
	ptr = scanner.Scan(new SigScanTarget(5,
		"74 2B",               // je "Sonic colors - Ultimate.exe"+16F3948
		"48 8B 0D ????????")); // mov rcx,["Sonic colors - Ultimate.exe"+52462A8]
	if (ptr == IntPtr.Zero) throw new Exception("Could not find address - IGT!");

	// Run start (standard mode) - can be used also for signalling a reset in the Any% run
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x120)) { Name = "runStart" });   // old 35 , new 110

	// Level completion flags
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x15E)) { Name = "levelflags1" });
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x15F)) { Name = "levelflags2" });
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x160)) { Name = "levelflags3" });
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x161)) { Name = "levelflags4" });
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x162)) { Name = "levelflags5" });
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x163)) { Name = "levelflags6" });
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x164)) { Name = "levelflags7" });
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x16B)) { Name = "levelflags8" });
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x16C)) { Name = "levelflags9" });
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x16D)) { Name = "levelflags10" });
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x16E)) { Name = "levelflags11" });

	// Custom functions
	vars.bitCheck = new Func<string, int, bool>((string plotEvent, int b) => ((byte)(vars.watchers[plotEvent].Current) & (1 << b)) != 0);

	vars.plotBools = new Dictionary<string, Tuple<string, int>>();

	vars.plotBools.Add("tropicalResortAct1", new Tuple<string, int>("levelflags1", 6));
	vars.plotBools.Add("tropicalResortAct2", new Tuple<string, int>("levelflags1", 7));
	vars.plotBools.Add("tropicalResortAct3", new Tuple<string, int>("levelflags2", 0));
	vars.plotBools.Add("tropicalResortAct4", new Tuple<string, int>("levelflags2", 1));
	vars.plotBools.Add("tropicalResortAct5", new Tuple<string, int>("levelflags2", 2));
	vars.plotBools.Add("tropicalResortAct6", new Tuple<string, int>("levelflags2", 3));
	vars.plotBools.Add("tropicalResortBoss", new Tuple<string, int>("levelflags2", 4));

	vars.plotBools.Add("sweetMountainAct1", new Tuple<string, int>("levelflags2", 5));
	vars.plotBools.Add("sweetMountainAct2", new Tuple<string, int>("levelflags2", 6));
	vars.plotBools.Add("sweetMountainAct3", new Tuple<string, int>("levelflags2", 7));
	vars.plotBools.Add("sweetMountainAct4", new Tuple<string, int>("levelflags3", 0));
	vars.plotBools.Add("sweetMountainAct5", new Tuple<string, int>("levelflags3", 1));
	vars.plotBools.Add("sweetMountainAct6", new Tuple<string, int>("levelflags3", 2));
	vars.plotBools.Add("sweetMountainBoss", new Tuple<string, int>("levelflags3", 3));

	vars.plotBools.Add("starlightCarnivalAct1", new Tuple<string, int>("levelflags3", 4));
	vars.plotBools.Add("starlightCarnivalAct2", new Tuple<string, int>("levelflags3", 5));
	vars.plotBools.Add("starlightCarnivalAct3", new Tuple<string, int>("levelflags3", 6));
	vars.plotBools.Add("starlightCarnivalAct4", new Tuple<string, int>("levelflags3", 7));
	vars.plotBools.Add("starlightCarnivalAct5", new Tuple<string, int>("levelflags4", 0));
	vars.plotBools.Add("starlightCarnivalAct6", new Tuple<string, int>("levelflags4", 1));
	vars.plotBools.Add("starlightCarnivalBoss", new Tuple<string, int>("levelflags4", 2));

	vars.plotBools.Add("planetWispAct1", new Tuple<string, int>("levelflags4", 3));
	vars.plotBools.Add("planetWispAct2", new Tuple<string, int>("levelflags4", 4));
	vars.plotBools.Add("planetWispAct3", new Tuple<string, int>("levelflags4", 5));
	vars.plotBools.Add("planetWispAct4", new Tuple<string, int>("levelflags4", 6));
	vars.plotBools.Add("planetWispAct5", new Tuple<string, int>("levelflags4", 7));
	vars.plotBools.Add("planetWispAct6", new Tuple<string, int>("levelflags5", 0));
	vars.plotBools.Add("planetWispBoss", new Tuple<string, int>("levelflags5", 1));

	vars.plotBools.Add("aquariumParkAct1", new Tuple<string, int>("levelflags5", 2));
	vars.plotBools.Add("aquariumParkAct2", new Tuple<string, int>("levelflags5", 3));
	vars.plotBools.Add("aquariumParkAct3", new Tuple<string, int>("levelflags5", 4));
	vars.plotBools.Add("aquariumParkAct4", new Tuple<string, int>("levelflags5", 5));
	vars.plotBools.Add("aquariumParkAct5", new Tuple<string, int>("levelflags5", 6));
	vars.plotBools.Add("aquariumParkAct6", new Tuple<string, int>("levelflags5", 7));
	vars.plotBools.Add("aquariumParkBoss", new Tuple<string, int>("levelflags6", 0));

	vars.plotBools.Add("asteroidCoasterAct1", new Tuple<string, int>("levelflags6", 1));
	vars.plotBools.Add("asteroidCoasterAct2", new Tuple<string, int>("levelflags6", 2));
	vars.plotBools.Add("asteroidCoasterAct3", new Tuple<string, int>("levelflags6", 3));
	vars.plotBools.Add("asteroidCoasterAct4", new Tuple<string, int>("levelflags6", 4));
	vars.plotBools.Add("asteroidCoasterAct5", new Tuple<string, int>("levelflags6", 5));
	vars.plotBools.Add("asteroidCoasterAct6", new Tuple<string, int>("levelflags6", 6));
	vars.plotBools.Add("asteroidCoasterBoss", new Tuple<string, int>("levelflags6", 7));

	vars.plotBools.Add("terminalVelocityAct1", new Tuple<string, int>("levelflags7", 0));
	vars.plotBools.Add("terminalVelocityBoss", new Tuple<string, int>("levelflags7", 2));
	vars.plotBools.Add("terminalVelocityAct2", new Tuple<string, int>("levelflags7", 1));

	vars.plotBools.Add("1-1", new Tuple<string, int>("levelflags8", 4));
	vars.plotBools.Add("1-2", new Tuple<string, int>("levelflags8", 5));
	vars.plotBools.Add("1-3", new Tuple<string, int>("levelflags8", 6));
	vars.plotBools.Add("2-1", new Tuple<string, int>("levelflags8", 7));
	vars.plotBools.Add("2-2", new Tuple<string, int>("levelflags9", 0));
	vars.plotBools.Add("2-3", new Tuple<string, int>("levelflags9", 1));
	vars.plotBools.Add("3-1", new Tuple<string, int>("levelflags9", 2));
	vars.plotBools.Add("3-2", new Tuple<string, int>("levelflags9", 3));
	vars.plotBools.Add("3-3", new Tuple<string, int>("levelflags9", 4));
	vars.plotBools.Add("4-1", new Tuple<string, int>("levelflags9", 5));
	vars.plotBools.Add("4-2", new Tuple<string, int>("levelflags9", 6));
	vars.plotBools.Add("4-3", new Tuple<string, int>("levelflags9", 7));
	vars.plotBools.Add("5-1", new Tuple<string, int>("levelflags10", 0));
	vars.plotBools.Add("5-2", new Tuple<string, int>("levelflags10", 1));
	vars.plotBools.Add("5-3", new Tuple<string, int>("levelflags10", 2));
	vars.plotBools.Add("6-1", new Tuple<string, int>("levelflags10", 3));
	vars.plotBools.Add("6-2", new Tuple<string, int>("levelflags10", 4));
	vars.plotBools.Add("6-3", new Tuple<string, int>("levelflags10", 5));
	vars.plotBools.Add("7-1", new Tuple<string, int>("levelflags10", 6));
	vars.plotBools.Add("7-2", new Tuple<string, int>("levelflags10", 7));
	vars.plotBools.Add("7-3", new Tuple<string, int>("levelflags11", 0));


	// Define basic status variables we need in the run
	vars.totalIGT = 0f;
}

startup
{	
	// Defining Worlds	
	string[][] worldName = new string[2][] {
		new string[8] {"tropicalResort", "sweetMountain", "starlightCarnival", "planetWisp", "aquariumPark", "asteroidCoaster", "terminalVelocity", "specialStages"},
		new string[8] {"Tropical Resort", "Sweet Mountain", "Starlight Carnival", "Planet Wisp", "Aquarium Park", "Asteroid Coaster", "Terminal Velocity", "Sonic Simulator"}
	};

	// Defining a codename for each stage included in the game. These names will be used as references for everything that relates to a single stage.
	vars.levelNames = new string[8][]
	{
		new string[7]  {"tropicalResortAct1", "tropicalResortAct2", "tropicalResortAct3", "tropicalResortAct4", "tropicalResortAct5", "tropicalResortAct6", "tropicalResortBoss"},                      // Tropical Resort
		new string[7]  {"sweetMountainAct1", "sweetMountainAct2", "sweetMountainAct3", "sweetMountainAct4", "sweetMountainAct5", "sweetMountainAct6", "sweetMountainBoss"},                             // Sweet Mountain
		new string[7]  {"starlightCarnivalAct1", "starlightCarnivalAct2", "starlightCarnivalAct3", "starlightCarnivalAct4", "starlightCarnivalAct5", "starlightCarnivalAct6", "starlightCarnivalBoss"}, // Starlight Carnival
		new string[7]  {"planetWispAct1", "planetWispAct2", "planetWispAct3", "planetWispAct4", "planetWispAct5", "planetWispAct6", "planetWispBoss"},                                                  // Planet Wisp
		new string[7]  {"aquariumParkAct1", "aquariumParkAct2", "aquariumParkAct3", "aquariumParkAct4", "aquariumParkAct5", "aquariumParkAct6", "aquariumParkBoss"},                                    // Aquarium Park
		new string[7]  {"asteroidCoasterAct1", "asteroidCoasterAct2", "asteroidCoasterAct3", "asteroidCoasterAct4", "asteroidCoasterAct5", "asteroidCoasterAct6", "asteroidCoasterBoss"},               // Asteroid Coaster
		new string[3]  {"terminalVelocityAct1", "terminalVelocityBoss", "terminalVelocityAct2"},                                                                                                        // Terminal Velocity
		new string[21] {"1-1", "1-2", "1-3", "2-1", "2-2", "2-3", "3-1", "3-2", "3-3", "4-1", "4-2", "4-3", "5-1", "5-2", "5-3", "6-1", "6-2", "6-3", "7-1", "7-2", "7-3"}                              // Special Stages
	};

	// Add settings for each level, using the codenames from above
	settings.Add("levelSplitting", true, "Automatic splitting configuration");
	for (int i = 0; i < worldName[0].Length; i++) settings.Add(worldName[0][i], true, worldName[1][i], "levelSplitting");
	for (int i = 0; i < 8; i++){
		for (int j = 0; j < vars.levelNames[i].Length; j++) settings.Add(vars.levelNames[i][j], true, (i < 6 && j == 6) || (i == 6 && j == 1) ? "BOSS" : i > 6 ? vars.levelNames[i][j] : "Act " + (i == 6 && j == 2 ? j.ToString() : (j+1).ToString()) , worldName[0][i > 6 ? 7 : i]);
	}
}


update
{
	// Update watchers
	vars.watchers.UpdateAll(game);
	
	// Fixing the IGT
	vars.watchers["IGT"].Current = (float)(Math.Truncate(100 * vars.watchers["IGT"].Current)) / 100;

	// Defining levelCompleted
	current.levelCompleted = new Dictionary<string, bool>();
	foreach (var entry in vars.plotBools) {
		current.levelCompleted.Add(entry.Key, vars.bitCheck(entry.Value.Item1, entry.Value.Item2));
	}

	// IGT logic: Use an internal totalIGT variable in which we will store the accumulated IGT every time the game IGT resets
	if (vars.watchers["IGT"].Old != 0 && vars.watchers["IGT"].Current == 0) vars.totalIGT += vars.watchers["IGT"].Old;
}

start
{
	vars.totalIGT = 0;
	return (vars.watchers["runStart"].Old == 35 && vars.watchers["runStart"].Current == 110);
}

reset
{
	return (vars.watchers["runStart"].Old == 110 && vars.watchers["runStart"].Current == 35);
}

split
{
	foreach (var entry in vars.plotBools)
	{
		if (old.levelCompleted[entry.Key] == current.levelCompleted[entry.Key]) continue;
		return settings[entry.Key] && current.levelCompleted[entry.Key];
	}
}

gameTime
{
	return TimeSpan.FromSeconds(Convert.ToDouble(vars.totalIGT + vars.watchers["IGT"].Current));
}

isLoading
{
	return true;
}