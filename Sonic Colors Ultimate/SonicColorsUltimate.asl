// IGT timer autosplitter
// Coding: Jujstme
// Version: 1.1
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
	vars.Truncate = new Func<float, float>((float input) => (float)(Math.Truncate(100 * input)) / 100);

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
	vars.watchers.Add(new MemoryWatcher<float>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x0, 0x270)) { Name = "IGT", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });

	// Stage completion pointers
	ptr = scanner.Scan(new SigScanTarget(5,
		"74 2B",               // je "Sonic colors - Ultimate.exe"+16F3948
		"48 8B 0D ????????")); // mov rcx,["Sonic colors - Ultimate.exe"+52462A8]
	if (ptr == IntPtr.Zero) throw new Exception("Could not find address - stage completion pointers");

	// Run start (standard mode) - can be used also for signalling a reset in the Any% run
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, 0x120)) { Name = "runStart" });

	// Level completion flags
	int[] levelFlags = new int[11] { 0x15E, 0x15F, 0x160, 0x161, 0x162, 0x163, 0x164, 0x16B, 0x16C, 0x16D, 0x16E };
	for (int i = 0; i < levelFlags.Length; i++) vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + memory.ReadValue<int>(ptr), 0x60, levelFlags[i])) { Name = "levelflags" + (i+1).ToString() });

	// Define a dictionary with the pointers to the game booleans.
	// This is used to easily get to the completion status of each stage, which is data stored in single bits.
	vars.plotBools = new Dictionary<string, Tuple<string, int>> {
	// Tropical Resort
	{vars.levelNames[0][0],  new Tuple<string, int>("levelflags1",  6)},
	{vars.levelNames[0][1],  new Tuple<string, int>("levelflags1",  7)},
	{vars.levelNames[0][2],  new Tuple<string, int>("levelflags2",  0)},
	{vars.levelNames[0][3],  new Tuple<string, int>("levelflags2",  1)},
	{vars.levelNames[0][4],  new Tuple<string, int>("levelflags2",  2)},
	{vars.levelNames[0][5],  new Tuple<string, int>("levelflags2",  3)},
	{vars.levelNames[0][6],  new Tuple<string, int>("levelflags2",  4)},
	// Sweet Mountain
	{vars.levelNames[1][0],  new Tuple<string, int>("levelflags2",  5)},
	{vars.levelNames[1][1],  new Tuple<string, int>("levelflags2",  6)},
	{vars.levelNames[1][2],  new Tuple<string, int>("levelflags2",  7)},
	{vars.levelNames[1][3],  new Tuple<string, int>("levelflags3",  0)},
	{vars.levelNames[1][4],  new Tuple<string, int>("levelflags3",  1)},
	{vars.levelNames[1][5],  new Tuple<string, int>("levelflags3",  2)},
	{vars.levelNames[1][6],  new Tuple<string, int>("levelflags3",  3)},
	// Starlight Carnival
	{vars.levelNames[2][0],  new Tuple<string, int>("levelflags3",  4)},
	{vars.levelNames[2][1],  new Tuple<string, int>("levelflags3",  5)},
	{vars.levelNames[2][2],  new Tuple<string, int>("levelflags3",  6)},
	{vars.levelNames[2][3],  new Tuple<string, int>("levelflags3",  7)},
	{vars.levelNames[2][4],  new Tuple<string, int>("levelflags4",  0)},
	{vars.levelNames[2][5],  new Tuple<string, int>("levelflags4",  1)},
	{vars.levelNames[2][6],  new Tuple<string, int>("levelflags4",  2)},
	// Planet Wisp
	{vars.levelNames[3][0],  new Tuple<string, int>("levelflags4",  3)},
	{vars.levelNames[3][1],  new Tuple<string, int>("levelflags4",  4)},
	{vars.levelNames[3][2],  new Tuple<string, int>("levelflags4",  5)},
	{vars.levelNames[3][3],  new Tuple<string, int>("levelflags4",  6)},
	{vars.levelNames[3][4],  new Tuple<string, int>("levelflags4",  7)},
	{vars.levelNames[3][5],  new Tuple<string, int>("levelflags5",  0)},
	{vars.levelNames[3][6],  new Tuple<string, int>("levelflags5",  1)},
	// Aquarium Park
	{vars.levelNames[4][0],  new Tuple<string, int>("levelflags5",  2)},
	{vars.levelNames[4][1],  new Tuple<string, int>("levelflags5",  3)},
	{vars.levelNames[4][2],  new Tuple<string, int>("levelflags5",  4)},
	{vars.levelNames[4][3],  new Tuple<string, int>("levelflags5",  5)},
	{vars.levelNames[4][4],  new Tuple<string, int>("levelflags5",  6)},
	{vars.levelNames[4][5],  new Tuple<string, int>("levelflags5",  7)},
	{vars.levelNames[4][6],  new Tuple<string, int>("levelflags6",  0)},
	// Asteroid Coaster
	{vars.levelNames[5][0],  new Tuple<string, int>("levelflags6",  1)},
	{vars.levelNames[5][1],  new Tuple<string, int>("levelflags6",  2)},
	{vars.levelNames[5][2],  new Tuple<string, int>("levelflags6",  3)},
	{vars.levelNames[5][3],  new Tuple<string, int>("levelflags6",  4)},
	{vars.levelNames[5][4],  new Tuple<string, int>("levelflags6",  5)},
	{vars.levelNames[5][5],  new Tuple<string, int>("levelflags6",  6)},
	{vars.levelNames[5][6],  new Tuple<string, int>("levelflags6",  7)},
	// Terminal Velocity
	{vars.levelNames[6][0],  new Tuple<string, int>("levelflags7",  0)},
	{vars.levelNames[6][1],  new Tuple<string, int>("levelflags7",  2)},  // This is NOT a typo
	{vars.levelNames[6][2],  new Tuple<string, int>("levelflags7",  1)},
	// Sonic Simulator
	{vars.levelNames[7][0],  new Tuple<string, int>("levelflags8",  4)},
	{vars.levelNames[7][1],  new Tuple<string, int>("levelflags8",  5)},
	{vars.levelNames[7][2],  new Tuple<string, int>("levelflags8",  6)},
	{vars.levelNames[7][3],  new Tuple<string, int>("levelflags8",  7)},
	{vars.levelNames[7][4],  new Tuple<string, int>("levelflags9",  0)},
	{vars.levelNames[7][5],  new Tuple<string, int>("levelflags9",  1)},
	{vars.levelNames[7][6],  new Tuple<string, int>("levelflags9",  2)},
	{vars.levelNames[7][7],  new Tuple<string, int>("levelflags9",  3)},
	{vars.levelNames[7][8],  new Tuple<string, int>("levelflags9",  4)},
	{vars.levelNames[7][9],  new Tuple<string, int>("levelflags9",  5)},
	{vars.levelNames[7][10], new Tuple<string, int>("levelflags9",  6)},
	{vars.levelNames[7][11], new Tuple<string, int>("levelflags9",  7)},
	{vars.levelNames[7][12], new Tuple<string, int>("levelflags10", 0)},
	{vars.levelNames[7][13], new Tuple<string, int>("levelflags10", 1)},
	{vars.levelNames[7][14], new Tuple<string, int>("levelflags10", 2)},
	{vars.levelNames[7][15], new Tuple<string, int>("levelflags10", 3)},
	{vars.levelNames[7][16], new Tuple<string, int>("levelflags10", 4)},
	{vars.levelNames[7][17], new Tuple<string, int>("levelflags10", 5)},
	{vars.levelNames[7][18], new Tuple<string, int>("levelflags10", 6)},
	{vars.levelNames[7][19], new Tuple<string, int>("levelflags10", 7)},
	{vars.levelNames[7][20], new Tuple<string, int>("levelflags11", 0)}};

	// Define basic status variables we need in the run
	vars.totalIGT = 0f;
}

startup
{	
	// Defining Worlds	
	string[][] worldName = new string[][] {
		new string[] {"tropicalResort", "sweetMountain", "starlightCarnival", "planetWisp", "aquariumPark", "asteroidCoaster", "terminalVelocity", "specialStages"},
		new string[] {"Tropical Resort", "Sweet Mountain", "Starlight Carnival", "Planet Wisp", "Aquarium Park", "Asteroid Coaster", "Terminal Velocity", "Sonic Simulator"}
	};

	// Defining a codename for each stage included in the game. These names will be used as references for everything that relates to a single stage.
	vars.levelNames = new string[][]
	{
		new string[] {"tropicalResortAct1", "tropicalResortAct2", "tropicalResortAct3", "tropicalResortAct4", "tropicalResortAct5", "tropicalResortAct6", "tropicalResortBoss"},                      // Tropical Resort
		new string[] {"sweetMountainAct1", "sweetMountainAct2", "sweetMountainAct3", "sweetMountainAct4", "sweetMountainAct5", "sweetMountainAct6", "sweetMountainBoss"},                             // Sweet Mountain
		new string[] {"starlightCarnivalAct1", "starlightCarnivalAct2", "starlightCarnivalAct3", "starlightCarnivalAct4", "starlightCarnivalAct5", "starlightCarnivalAct6", "starlightCarnivalBoss"}, // Starlight Carnival
		new string[] {"planetWispAct1", "planetWispAct2", "planetWispAct3", "planetWispAct4", "planetWispAct5", "planetWispAct6", "planetWispBoss"},                                                  // Planet Wisp
		new string[] {"aquariumParkAct1", "aquariumParkAct2", "aquariumParkAct3", "aquariumParkAct4", "aquariumParkAct5", "aquariumParkAct6", "aquariumParkBoss"},                                    // Aquarium Park
		new string[] {"asteroidCoasterAct1", "asteroidCoasterAct2", "asteroidCoasterAct3", "asteroidCoasterAct4", "asteroidCoasterAct5", "asteroidCoasterAct6", "asteroidCoasterBoss"},               // Asteroid Coaster
		new string[] {"terminalVelocityAct1", "terminalVelocityBoss", "terminalVelocityAct2"},                                                                                                        // Terminal Velocity
		new string[] {"1-1", "1-2", "1-3", "2-1", "2-2", "2-3", "3-1", "3-2", "3-3", "4-1", "4-2", "4-3", "5-1", "5-2", "5-3", "6-1", "6-2", "6-3", "7-1", "7-2", "7-3"}                              // Special Stages
	};

	// Add settings for each level, using the codenames from above
	settings.Add("1", false, "Support for Egg Shuttle is limited at this moment");
	settings.Add("2", false, "IGT works, autosplitting in Egg Shuttle will be added soon");
	settings.Add("3", false, "Any% and All Chaos Emeralds categories are fully supported");
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

	// If the timer is stopped (for example when you reset a run) make sure to reset the IGT variable
	if (timer.CurrentPhase == TimerPhase.NotRunning) vars.totalIGT = 0f;

	// Fixing the IGT
	vars.watchers["IGT"].Current = vars.Truncate(vars.watchers["IGT"].Current);

	// Defining levelCompleted
	current.levelCompleted = new Dictionary<string, bool>();
	foreach (var entry in vars.plotBools) current.levelCompleted.Add(entry.Key, vars.bitCheck(entry.Value.Item1, entry.Value.Item2));

	// IGT logic: Use an internal totalIGT variable in which we will store the accumulated IGT every time the game IGT resets
	if (vars.watchers["IGT"].Old != 0 && vars.watchers["IGT"].Current == 0) vars.totalIGT += vars.watchers["IGT"].Old;
}

start
{
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
