// IGT timer autosplitter for Hot Shot Racing
// Coding: Jujstme
// Version: 1.3
// In case of bugs, please contact me at just.tribe@gmail.com

state("HotshotRacing") {}

startup
{
    string[,] Settings =
    {
        { null, "StartTime", "Start the timer on the \"3\" at the countdown", "If enabled, LiveSplit will start the timer when the \"3\" appears during the countdown on the first race.\nIf disabled, LiveSplit will start the timer at the start of the first race.\n\nDefault: disabled", "false"},
        { null, "GPsplit", "Split only at the final race of each Grand Prix", "If enabled, LiveSplit will trigger a split only upon completion of a Grand Prix.\nIf disabled, LiveSplit will trigger a split at the completion of each race.\n\nDefault: disabled", "false"}
    };
    
    for (int i = 0; i < Settings.GetLength(0); i++)
    {
        settings.Add(Settings[i, 1], bool.Parse(Settings[i, 4]), Settings[i, 2], Settings[i, 0]);
        if (!string.IsNullOrEmpty(Settings[i, 3])) settings.SetToolTip(Settings[i, 1], Settings[i, 3]);
    }
    
    vars.totaligt = 0;
    vars.progressIGT = 0;
}

init
{
    vars.watchers = new MemoryWatcherList();
    var scanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);
    IntPtr ptr;

    ptr = scanner.Scan(new SigScanTarget(3, "48 8B 05 ???????? 48 8B 48 20 8B 51 38") { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) }); if (ptr == IntPtr.Zero) throw new Exception();
    vars.watchers.Add(new MemoryWatcher<float>(new DeepPointer(ptr, 0x2A8)) { Name = "runstart", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });
    
    ptr = scanner.Scan(new SigScanTarget(2, "8B 05 ???????? 85 C0 7E 2B") { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) }); if (ptr == IntPtr.Zero) throw new Exception();
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr)) { Name = "racestatus" }); // 0 idle; 1 stage intro: 3 countdown; 4 racing; 5 results screen

    ptr = scanner.Scan(new SigScanTarget(4, "41 89 B4 CE ????????") { OnFound = (p, s, addr) => modules.First().BaseAddress + 0x38 + p.ReadValue<int>(addr) }); if (ptr == IntPtr.Zero) throw new Exception();
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr)) { Name = "racecompleted" }); // becomes 1 when completing a race, becomes 3 in case of TimeOut
    
    ptr = scanner.Scan(new SigScanTarget(3, "48 8B 05 ???????? F3 0F10 40 04 C3") { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) }); if (ptr == IntPtr.Zero) throw new Exception();
    vars.watchers.Add(new MemoryWatcher<float>(new DeepPointer(ptr, 0x4)) { Name = "igt", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull }); // starts at the start of every race and stops at the results screen

    ptr = scanner.Scan(new SigScanTarget(5, "8B F7 48 83 3D ???????? 00 75 41") { OnFound = (p, s, addr) => addr + 0x5 + p.ReadValue<int>(addr) }); if (ptr == IntPtr.Zero) throw new Exception();
    vars.watchers.Add(new MemoryWatcher<float>(new DeepPointer(ptr, 0x0, 0xE8, 0x34)) { Name = "totalracetime", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull }); // updates itself each time you complete a lap (final lap included)
    
    ptr = scanner.Scan(new SigScanTarget(3, "44 39 2D ???????? 76 6C") { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) }); if (ptr == IntPtr.Zero) throw new Exception();
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr)) { Name = "trackorder" }); // Becomes 4 at the end of a GP
} 

start
{
    // Reset the variables if you reset a run
    vars.totaligt = 0;
    vars.progressIGT = 0;

    if (settings["StartTime"]) {
    return(vars.watchers["runstart"].Current >= 2 && vars.watchers["igt"].Current == 0 && vars.watchers["racestatus"].Current == 3 && vars.watchers["trackorder"].Current == 0); 
    } else {
    return(vars.watchers["igt"].Current != 0 && vars.watchers["igt"].Old == 0 && vars.watchers["trackorder"].Current == 0);
    }
}


update
{
    vars.watchers.UpdateAll(game);

    // During a race, the IGT is calculated by the game and is added to the total
    if (vars.watchers["racecompleted"].Current == 0)	{
			
      // If you restart an event or a race, the IGT of the failed race is still considered and added
      if (vars.watchers["igt"].Old != 0 && vars.watchers["igt"].Current == 0 && vars.watchers["racestatus"].Old == 4) {
        vars.totaligt = vars.watchers["igt"].Old + vars.totaligt;
        vars.progressIGT = vars.totaligt;
      }
      else
      {
        vars.progressIGT = vars.watchers["igt"].Current + vars.totaligt;
      }
    }

    // How to behave the moment you complete a race:
    if (vars.watchers["racecompleted"].Current == 1 && vars.watchers["racecompleted"].Old == 0)
    {
      vars.totaligt = (Math.Truncate(1000 * (vars.watchers["totalracetime"].Current + vars.totaligt)) / 1000);
      vars.progressIGT = vars.totaligt;
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
    return (vars.watchers["trackorder"].Current == 4 && vars.watchers["racecompleted"].Current == 1 && vars.watchers["racecompleted"].Old == 0);
    }
    else
    {
    return (vars.watchers["racecompleted"].Current == 1 && vars.watchers["racecompleted"].Old == 0);
    }
}

isLoading
{
    return true;
}
