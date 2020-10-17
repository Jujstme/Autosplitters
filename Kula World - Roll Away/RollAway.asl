// IGT timer autosplitter for Kula World / Roll Away
// Supported versions: PAL, NTSC, NTSC-J
// Supported emulators: ePSXe (from v1.6.0 to v2.0.5), Retroarch
// Coding: Jujstme
// Version: 1.2
// In case of bugs, please contact me at just.tribe@gmail.com

state("retroarch"){}
state("ePSXe"){} 

init
{
    IntPtr memoryOffset = IntPtr.Zero;
	int wramOffset;

    if (memory.ProcessName.ToLower().Contains("epsxe")) {
		// Listing ePSXe supported versions with the offsets needed to identify the starting point of emulated RAM
        var versions = new Dictionary<int, int>{
            { 0x182A000, 0xA82020 },   // ePSXe v2.0.5
			{ 0x1553000, 0x825140 },   // ePSXe v2.0.2-1
			{ 0x1359000, 0x81A020 },   // ePSXe v2.0.0
			{ 0xA08000, 0x68B6A0 },   // ePSXe v1.9.25
			{ 0x9D3000, 0x6579A0 },   // ePSXe v1.9.0
			{ 0x9C2000, 0x652EA0 },   // ePSXe v1.8.0
			{ 0x8B7000, 0x54C020 },   // ePSXe v1.7.0
			{ 0x4E2000, 0x1B6E40 },   // ePSXe v1.6.0
        };
        if (versions.TryGetValue(modules.First().ModuleMemorySize, out wramOffset)) {
			memoryOffset = (IntPtr)modules.First().BaseAddress + wramOffset;
        }
	} else if (memory.ProcessName.ToLower().Contains("retroarch")) {
		
		// Supported libretro modules are Beetle_PSX, Beetle_PSX_HW, PCSX_Rearmed and Duckstation
		// Support for Duckstation is spotty and largely untested. Might break anytime.
		ProcessModuleWow64Safe libretromodule = modules.Where(m => m.ModuleName == "mednafen_psx_hw_libretro.dll" || m.ModuleName == "mednafen_psx_libretro.dll" || m.ModuleName == "pcsx_rearmed_libretro.dll" || m.ModuleName == "duckstation_libretro.dll").First();

		if (libretromodule.ModuleName == "mednafen_psx_hw_libretro.dll") {
			memoryOffset = (IntPtr)0x40000000;
		} else if (libretromodule.ModuleName == "mednafen_psx_libretro.dll") {
			memoryOffset = (IntPtr)0x40000000;
		} else if (libretromodule.ModuleName == "pcsx_rearmed_libretro.dll") {
			memoryOffset = (IntPtr)0x30000000;
		} else if (libretromodule.ModuleName == "duckstation_libretro.dll") {
			var versions = new Dictionary<int, int>{
				{ 0x4B0A000, 0x2D4030 },   // Duckstation 64bit
				{ 0x55B000, 0x22CF88 },   // Duckstation 32bit
			};
			if (versions.TryGetValue(libretromodule.ModuleMemorySize, out wramOffset)) {
				memoryOffset = (IntPtr)libretromodule.BaseAddress + wramOffset;
			}
		}
    }
	
	if (memoryOffset == IntPtr.Zero) {
		throw new Exception("Memory not yet initialized.");
	}
	

	vars.watchers = new MemoryWatcherList
	{
		new StringWatcher(memoryOffset + 0x9334, 4) { Name = "gameversion" },
		new MemoryWatcher<int>(memoryOffset + 0xA5584) { Name = "levelIGT_ntsc" },
		new MemoryWatcher<byte>(memoryOffset + 0xA3408) { Name = "levelNo_ntsc" },
		new MemoryWatcher<byte>(memoryOffset + 0xA340C) { Name = "worldNo_ntsc" },
		new MemoryWatcher<bool>(memoryOffset + 0xA342C) { Name = "demomode_ntsc" },
		new MemoryWatcher<int>(memoryOffset + 0xA5110) { Name = "levelIGT_pal" },
		new MemoryWatcher<byte>(memoryOffset + 0xA2EA0) { Name = "levelNo_pal" },
		new MemoryWatcher<byte>(memoryOffset + 0xA2EA4) { Name = "worldNo_pal" },
		new MemoryWatcher<bool>(memoryOffset + 0xA566C) { Name = "demomode_pal" },
		new MemoryWatcher<int>(memoryOffset + 0xA1ED0) { Name = "levelIGT_ntscj" },
		new MemoryWatcher<byte>(memoryOffset + 0x9F50C) { Name = "levelNo_ntscj" },
		new MemoryWatcher<byte>(memoryOffset + 0x9F510) { Name = "worldNo_ntscj" },
		new MemoryWatcher<bool>(memoryOffset + 0x9F534) { Name = "demomode_ntscj" },
	};

}


startup
{
   settings.Add("levelsplit", false, "Split at the end of each level");
   settings.SetToolTip("levelsplit", "If enabled, LiveSplit will trigger a split at the end of every level (150 splits).\nIf disabled, LiveSplit will trigger a split only at the end of each world (10 splits).\n\nDefault: disabled");
}

start
{
   vars.progressIGT = 0;
   vars.totalIGT = 0;
   return(current.levelIGT != 0 && old.levelIGT == 0 && !current.demomode);
}

update
{
	// Update the state variables according to the version of the game currently loaded
	vars.watchers.UpdateAll(game);
	if (vars.watchers["gameversion"].Current == "SLUS") {
		current.levelIGT = vars.watchers["levelIGT_ntsc"].Current;
		current.levelNo = vars.watchers["levelNo_ntsc"].Current;
		current.worldNo = vars.watchers["worldNo_ntsc"].Current;
		current.demomode = vars.watchers["demomode_ntsc"].Current;
		vars.updatetime = 60;
	} else if (vars.watchers["gameversion"].Current == "SCES") {
		current.levelIGT = vars.watchers["levelIGT_pal"].Current;
		current.levelNo = vars.watchers["levelNo_pal"].Current;
		current.worldNo = vars.watchers["worldNo_pal"].Current;
		current.demomode = vars.watchers["demomode_pal"].Current;
		vars.updatetime = 50;
	} else if (vars.watchers["gameversion"].Current == "SCPS") {
		current.levelIGT = vars.watchers["levelIGT_ntscj"].Current;
		current.levelNo = vars.watchers["levelNo_ntscj"].Current;
		current.worldNo = vars.watchers["worldNo_ntscj"].Current;
		current.demomode = vars.watchers["demomode_ntscj"].Current;
		vars.updatetime = 60;
	};
	
	// Update the IGT according to the game's internal timer (50FPS timer for PAL, 60FPS timer for NTSC)
	if (current.levelIGT == 0 && old.levelIGT != 0) {
		vars.totalIGT += vars.progressIGT;
	}
	vars.progressIGT = current.levelIGT / vars.updatetime;
}

gameTime
{
  return TimeSpan.FromSeconds(vars.progressIGT + vars.totalIGT);
}

split
{
	if (settings["levelsplit"]) {
		return ((current.levelNo != old.levelNo) && current.levelNo < 15 && !(current.levelNo == 0 && current.worldNo == 0));
	} else {
		return (current.worldNo > old.worldNo);	
	}
}

isLoading
{
  return true;
}