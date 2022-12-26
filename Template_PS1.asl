// Basic template for PS1 emulators
// Coding: Jujstme
// Supports all major PS1 emulators
// List of supported emulators:
//  - ePSXe
//  - Duckstation
//  - Retroarch (supported cores: PCSX-Rearmed, Mednafen/BeetlePSX)
//  - pSX
//  - PCSX-Redux
//  - Xebra
//
// If you need the script to support some other emulator not listed above
// please contact me by opening a new issue on https://github.com/Jujstme/Autosplitters

state("ePSXe") {}
state("duckstation-qt-x64-ReleaseLTCG") {}
state("duckstation-nogui-x64-ReleaseLTCG") {}
state("retroarch") {}
state("psxfin") {}
state("pcsx-redux.main") {}
state("xebra") {}

init
{
    // Known IDs for the PAL and NTSC versions of the game
    // In PS1 games, PAL, NTSC-U and NTSC-J all use different addresses
    vars.Gamecodes = new Dictionary<string, string>
    {
        { "SCES-01000", "PAL" },
        { "SLUS-00724", "NTSC-U" },
        { "SCPS-10064", "NTSC-J" }
    };

    // Input your memory addresses here
    // For the script to work, it NEEDS a StringWatcher of 10 characters that can reliably identify the current running game
    // A good example is to use the unique ID that each PS1 game has --> eg. SCUS-94154 for the NTSC version of Crash Bandicoot 2.
    // Those IDs also need to be added in the startup block
    var GetWatchers = (Func<IntPtr, MemoryWatcherList>)(wram => new MemoryWatcherList{
        new StringWatcher(wram + 0xA350E, 10) { Name = "NTSC-U_Gamecode" },
        new StringWatcher(wram + 0xA2FB6, 10) { Name = "PAL_Gamecode" },
        new StringWatcher(wram + 0x9F5E6, 10) { Name = "NTSC-J_Gamecode" },

        new MemoryWatcher<int>(wram + 0xA5584) { Name = "NTSC-U_IGT" },
        new MemoryWatcher<byte>(wram + 0xA3408) { Name = "NTSC-U_LevelNo" },
        new MemoryWatcher<byte>(wram + 0xA340C) { Name = "NTSC-U_WorldNo" },
        new MemoryWatcher<bool>(wram + 0xA342C) { Name = "NTSC-U_DemoMode" },

        new MemoryWatcher<int>(wram + 0xA5110) { Name = "PAL_IGT" },
        new MemoryWatcher<byte>(wram + 0xA2EA0) { Name = "PAL_LevelNo" },
        new MemoryWatcher<byte>(wram + 0xA2EA4) { Name = "PAL_WorldNo" },
        new MemoryWatcher<bool>(wram + 0xA566C) { Name = "PAL_DemoMode" },

        new MemoryWatcher<int>(wram + 0xA1ED0) { Name = "NTSC-J_IGT" },
        new MemoryWatcher<byte>(wram + 0x9F50C) { Name = "NTSC-J_LevelNo" },
        new MemoryWatcher<byte>(wram + 0x9F510) { Name = "NTSC-J_WorldNo" },
        new MemoryWatcher<bool>(wram + 0x9F534) { Name = "NTSC-J_DemoMode" },
    });


    // Please do not modify the script below this point unless you know what you're doing
    switch(game.ProcessName.ToLower())
    {
        case "epsxe":
            vars.InitTask = (Action)(() => {
                vars.InitCompleted = false;
                vars.CancelSource = new CancellationTokenSource();

                System.Threading.Tasks.Task.Run(async () =>
                {
                    IntPtr WRAMbase = IntPtr.Zero;
                    while (!vars.CancelSource.IsCancellationRequested && WRAMbase == IntPtr.Zero)
                    {
                        SignatureScanner scanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);
                        WRAMbase = scanner.Scan(new SigScanTarget(5, "C1 E1 10 8D 89") { OnFound = (p, s, addr) => p.ReadPointer(addr) });
                        if (WRAMbase == IntPtr.Zero) await System.Threading.Tasks.Task.Delay(50, vars.CancelSource.Token);
                    }

                    if (!vars.CancelSource.IsCancellationRequested)
                    {
                        vars.watchers = GetWatchers(WRAMbase);
                        vars.KeepAlive = (Func<bool>)(() => true);
                        vars.InitCompleted = true;
                    }
                });
            });
            break;
        
        case "psxfin":
            vars.InitTask = (Action)(() => {
                vars.InitCompleted = false;
                vars.CancelSource = new CancellationTokenSource();

                System.Threading.Tasks.Task.Run(async () =>
                {
                    IntPtr WRAMbase = IntPtr.Zero;
                    while (!vars.CancelSource.IsCancellationRequested && WRAMbase == IntPtr.Zero)
                    {
                        WRAMbase = game.MemoryPages(true).FirstOrDefault(p => p.Type == MemPageType.MEM_PRIVATE && (int)p.RegionSize == 0x201000).BaseAddress;
                        if (WRAMbase == IntPtr.Zero) await System.Threading.Tasks.Task.Delay(2000, vars.CancelSource.Token);
                        else WRAMbase += 0x20;
                    }

                    if (!vars.CancelSource.IsCancellationRequested)
                    {
                        vars.watchers = GetWatchers(WRAMbase);
                        vars.KeepAlive = (Func<bool>)(() => true);
                        vars.InitCompleted = true;
                    }
                });
            });
            break;
        
        case "duckstation-qt-x64-releaseltcg":
        case "duckstation-nogui-x64-Releaseltcg":
            vars.InitTask = (Action)(() => {
                vars.InitCompleted = false;
                vars.CancelSource = new CancellationTokenSource();

                System.Threading.Tasks.Task.Run(async () =>
                {
                    IntPtr WRAMbase = IntPtr.Zero;
                    while (!vars.CancelSource.IsCancellationRequested && WRAMbase == IntPtr.Zero)
                    {
                        WRAMbase = game.MemoryPages(true).FirstOrDefault(p => p.Type == MemPageType.MEM_MAPPED && (int)p.RegionSize == 0x200000).BaseAddress;
                        if (WRAMbase == IntPtr.Zero) await System.Threading.Tasks.Task.Delay(2000, vars.CancelSource.Token);
                    }

                    if (!vars.CancelSource.IsCancellationRequested)
                    {
                        vars.watchers = GetWatchers(WRAMbase);
                        vars.KeepAlive = (Func<bool>)(() => { byte[] buffer; return game.ReadBytes(WRAMbase, 1, out buffer); });
                        vars.InitCompleted = true;
                    }
                });
            });
            break;

        case "retroarch":
            vars.InitTask = (Action)(() => {
                vars.InitCompleted = false;
                vars.CancelSource = new CancellationTokenSource();

                System.Threading.Tasks.Task.Run(async () =>
                {
                    IntPtr WRAMbase = IntPtr.Zero;
                    int pageSize = 0;
                    var Cores = new List<string>{ "mednafen_psx_hw_libretro.dll", "mednafen_psx_libretro.dll", "pcsx_rearmed_libretro.dll" };

                    while (!vars.CancelSource.IsCancellationRequested && WRAMbase == IntPtr.Zero)
                    {
                        var core = game.ModulesWow64Safe().FirstOrDefault(m => Cores.Contains(m.ModuleName));
                        if (core == null) { await System.Threading.Tasks.Task.Delay(2000, vars.CancelSource.Token); continue; }

                        switch (core.ModuleName)
                        {
                            case "mednafen_psx_hw_libretro.dll":
                            case "mednafen_psx_libretro.dll":
                                pageSize = 0x200000;
                                break;
                            case "pcsx_rearmed_libretro.dll":
                                pageSize = 0x210000;
                                break;
                        }
                        if (pageSize == 0) { await System.Threading.Tasks.Task.Delay(2000, vars.CancelSource.Token); continue; }
                        
                        WRAMbase = game.MemoryPages(true).FirstOrDefault(p => p.Type == MemPageType.MEM_MAPPED && (int)p.RegionSize == pageSize).BaseAddress;
                        if (WRAMbase == IntPtr.Zero) await System.Threading.Tasks.Task.Delay(2000, vars.CancelSource.Token);
                    }

                    if (!vars.CancelSource.IsCancellationRequested)
                    {
                        vars.watchers = GetWatchers(WRAMbase);
                        vars.KeepAlive = (Func<bool>)(() => { byte[] buffer; return game.ReadBytes(WRAMbase, 1, out buffer); });
                        vars.InitCompleted = true;
                    }
                });
            });
            break;

        case "pcsx-redux.main":
            vars.InitTask = (Action)(() => {
                vars.InitCompleted = false;
                vars.CancelSource = new CancellationTokenSource();

                System.Threading.Tasks.Task.Run(async () =>
                {
                    IntPtr WRAMbase = IntPtr.Zero;
                    int pageCount = 0;
                    while (!vars.CancelSource.IsCancellationRequested && WRAMbase == IntPtr.Zero)
                    {
                        WRAMbase = game.MemoryPages(true).LastOrDefault(p => (int)p.RegionSize == 0x801000).BaseAddress;
                        if (WRAMbase == IntPtr.Zero) await System.Threading.Tasks.Task.Delay(2000, vars.CancelSource.Token);
                        else { WRAMbase += game.Is64Bit() ? 0x40 : 0x20; pageCount = game.MemoryPages(true).Count(); }
                    }

                    if (!vars.CancelSource.IsCancellationRequested)
                    {
                        vars.watchers = GetWatchers(WRAMbase);
                        vars.KeepAlive = (Func<bool>)(() =>  game.MemoryPages(true).Count() == pageCount);
                        vars.InitCompleted = true;
                    }
                });
            });
            break;

        case "xebra":
            vars.InitTask = (Action)(() => {
                vars.InitCompleted = false;
                vars.CancelSource = new CancellationTokenSource();

                SignatureScanner scanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);
                System.Threading.Tasks.Task.Run(async () =>
                {
                    IntPtr WRAMbase = IntPtr.Zero;
                    while (!vars.CancelSource.IsCancellationRequested && WRAMbase == IntPtr.Zero)
                    {
                        WRAMbase = scanner.Scan(new SigScanTarget(1, "E8 ???????? E9 ???????? 89 C8 C1 F8 10") { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
                        if (WRAMbase == IntPtr.Zero) await System.Threading.Tasks.Task.Delay(2000, vars.CancelSource.Token);
                        else WRAMbase = new DeepPointer(WRAMbase + 0x16A, 0).Deref<IntPtr>(game);
                    }

                    if (!vars.CancelSource.IsCancellationRequested)
                    {
                        vars.watchers = GetWatchers(WRAMbase);
                        vars.KeepAlive = (Func<bool>)(() => true);
                        vars.InitCompleted = true;
                    }
                });
            });
            break;
    }

    vars.VerifyGamecode = (Func<bool>)(() => {
        var codewatchers = new List<MemoryWatcher>();
        foreach (var entry in vars.Gamecodes.Values) codewatchers.Add(vars.watchers[entry + "_Gamecode"]);

        foreach (var entry in codewatchers)
        {
            if (entry.Current != null && vars.Gamecodes.ContainsKey(entry.Current.ToString()))
            {
                vars.GameRegion = vars.Gamecodes[entry.Current.ToString()] + "_";
                return true;
            }
        }
        return false;
    });

    vars.PreUpdate = (Func<bool>)(() => {
        if (!vars.InitCompleted)
            return false;
        
        if (!vars.KeepAlive())
        {
            vars.InitTask();
            return false;
        }

        vars.watchers.UpdateAll(game);
        
        if (!vars.VerifyGamecode())
            return false;
        
        return true;
    });

    vars.InitTask();
}

startup
{
    vars.CancelSource = new CancellationTokenSource();
}

update
{
    if (!vars.PreUpdate()) return false;

    current.IGT = vars.watchers[vars.GameRegion + "DemoMode"].Current ? TimeSpan.Zero : TimeSpan.FromSeconds(vars.watchers[vars.GameRegion + "IGT"].Current / (vars.GameRegion == "PAL" ? 50d : 60d));

    if (current.IGT == TimeSpan.Zero && old.IGT != current.IGT)
        vars.AccumulatedIGT += old.IGT;

    if (timer.CurrentPhase == TimerPhase.NotRunning)
        vars.AccumulatedIGT = TimeSpan.Zero;
}

isLoading
{
    return true;
}

start
{
    return vars.watchers[vars.GameRegion + "IGT"].Current != 0 && vars.watchers[vars.GameRegion + "IGT"].Old == 0 && !vars.watchers[vars.GameRegion + "DemoMode"].Current;
}

split
{
    return settings["level"]
        ? !vars.watchers[vars.GameRegion + "DemoMode"].Current && vars.watchers[vars.GameRegion + "LevelNo"].Changed && vars.watchers[vars.GameRegion + "LevelNo"].Current < 15 && !(vars.watchers[vars.GameRegion + "LevelNo"].Current == 0 && vars.watchers[vars.GameRegion + "WorldNo"].Current == 0)
        : !vars.watchers[vars.GameRegion + "DemoMode"].Current && vars.watchers[vars.GameRegion + "WorldNo"].Current > vars.watchers[vars.GameRegion + "WorldNo"].Old;
}

gameTime
{
    return vars.AccumulatedIGT + current.IGT;
}

exit
{
    vars.CancelSource.Cancel();
}

shutdown
{
    vars.CancelSource.Cancel();
}