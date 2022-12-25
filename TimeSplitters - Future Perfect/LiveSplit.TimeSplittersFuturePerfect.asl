// TimeSplitters: Future Perfect
// IGT calculator
// Supports both the GCN and the PS2 version
// Emulators supported: Dolphin, PCSX2
// Coding: Jujstme
// Last update: Dec 25th, 2022

state("Dolphin") {}
state("pcsx2-qtx64-avx2") {}
state("pcsx2-qtx64") {}
state("pcsx2") {}

init
{
    // Default values
    refreshRate = 60;
    current.IGT = TimeSpan.Zero;

    // Determine which emulator is running and sets the version accordingly. Default is the GCN version
    vars.version = game.ProcessName.ToLower().Contains("pcsx2") ? "PS2" : "GCN";

    switch ((string)vars.version)
    {
        case "PS2":
            // Known IDs for the PAL and NTSC versions of the game
            vars.Gamecodes = new Dictionary<string, string>
            {
                { "SLES-52993", "_PAL"  },
                { "SLUS-21148", "_NTSC" }
            };

            // Setting up sigscanning
            var scanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);

            IntPtr WRAMbase = game.Is64Bit()
                ? scanner.Scan(new SigScanTarget(4, "48 8B 8C C2 ???????? 48 85 C9") { OnFound = (p, s, addr) => modules.First().BaseAddress + p.ReadValue<int>(addr) + 0x5E3 * 8 })
                : scanner.Scan(new SigScanTarget(3, "8B 04 85 ???????? 85 C0 78 10") { OnFound = (p, s, addr) => p.ReadPointer(addr) + 0x5E3 * 4 });

            if (WRAMbase == IntPtr.Zero)
                throw new NullReferenceException("Sigscan failed");
            
            vars.watchers = new MemoryWatcherList
            {
                new StringWatcher(new DeepPointer(WRAMbase, 0x3BA13), 10) { Name = "Gamecode" },

                // PAL
                new MemoryWatcher<byte>(new DeepPointer(WRAMbase, 0x8BCA8)) { Name = "FrameRate_PAL" },
                new MemoryWatcher<int>(new DeepPointer(WRAMbase, 0x460A8)) { Name = "IGT_PAL" },
                new MemoryWatcher<byte>(new DeepPointer(WRAMbase, 0x4608C)) { Name = "Status_PAL" },
                // NTSC
                new MemoryWatcher<int>(new DeepPointer(WRAMbase, 0x45FA8)) { Name = "IGT_NTSC" },
                new MemoryWatcher<byte>(new DeepPointer(WRAMbase, 0x45F8C)) { Name = "Status_NTSC" },
            };
            break;
        
        case "GCN":
            // In Dolphin, two discontiguous memory regions are used (MEM1 and MEM2).
            // For GCN games, only MEM1 is relevant, whereas in Wii game both MEM1 and MEM2 are used.
            // This function runs a Task that asynchronously looks for MEM1/MEM2.
            // As the base address of MEM1/MEM2 can change when when the emulation is restarted,
            // this allows to re-run the task again if needed.
            vars.InitTask = (Action)(() => {
                vars.InitCompleted = false;
                vars.CancelSource = new CancellationTokenSource();

                System.Threading.Tasks.Task.Run(async () =>
                {
                    // Game codes
                    var Gamecodes = new List<string>{ "G3FD69", "G3FE69", "G3FF69", "G3FP69", "G3FS69" };
                    vars.CheckGameCode = (Func<bool>)(() => Gamecodes.Contains(vars.watchers["Gamecode"].Current));

                    // Base address for MEM1
                    IntPtr MEM1 = IntPtr.Zero;

                    while (!vars.CancelSource.IsCancellationRequested && MEM1 == IntPtr.Zero)
                    {
                        MEM1 = game.MemoryPages(true).FirstOrDefault(p => p.Type == MemPageType.MEM_MAPPED && p.State == MemPageState.MEM_COMMIT && (int)p.RegionSize == 0x2000000).BaseAddress;
                        
                        if (MEM1 == IntPtr.Zero)
                            await System.Threading.Tasks.Task.Delay(2000, vars.CancelSource.Token);
                    }

                    if (!vars.CancelSource.IsCancellationRequested)
                    {
                        vars.watchers = new MemoryWatcherList
                        {
                            // KeepAlive is just part of a very basic check. Since the first bytes of MEM1 is always part of the internal game code, it will always be true.
                            // It only returns false if the ReadAction fails, signalling the memory page is no longer valid.
                            new MemoryWatcher<bool>(MEM1) { Name = "KeepAlive", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull },
                            new StringWatcher(MEM1, 6) { Name = "Gamecode" },
                            new MemoryWatcher<byte>(MEM1 + 0x6109C3) { Name = "FrameRate" },
                            new MemoryWatcher<int>(MEM1 + 0x611908) { Name = "IGT" },
                            new MemoryWatcher<byte>(MEM1 + 0x611937) { Name = "Status" },
                        };
                        vars.InitCompleted = true;
                    }
                });
            });

            vars.InitTask();
            break;
    }
}

startup
{    
    // Default values
    vars.AccumulatedIGT = TimeSpan.Zero;
    vars.CancelSource = new CancellationTokenSource();

    // Custom func
    vars.IntToLittleEndian = (Func<int, int>)(input => {
        byte[] temp = BitConverter.GetBytes(input);
        Array.Reverse(temp);
        return BitConverter.ToInt32(temp, 0);
    });
}

update
{
    switch ((string)vars.version)
    {
        case "GCN":
            // If the Init Task has not completed, this prevents the autosplitter from proceeding further
            if (!vars.InitCompleted)
                return false;

            // Update the watchers
            vars.watchers.UpdateAll(game);

            // If KeepAlive returns false (see above in the init block) we want to re-run the Init Task and look for the memory addresses again
            if (!vars.watchers["KeepAlive"].Current)
            {
                vars.InitTask();
                return false;
            }

            // If the game code is incorrect (eg. running another game inside Dolphin) the autosplitter needs to be disabled
            if (!vars.CheckGameCode())
                return false;

            current.IGT = vars.watchers["Status"].Current > 7 || vars.watchers["Status"].Current == 2 ? old.IGT : TimeSpan.FromSeconds(Math.Truncate((vars.IntToLittleEndian(vars.watchers["IGT"].Current) / (double)vars.watchers["FrameRate"].Current) * 10) / 10);
            break;

        case "PS2":
            // First, update the watchers
            vars.watchers.UpdateAll(game);

            // If the game doesn't have a valid ID, it means PCSX2 loaded another game. In that case, disable autosplitting funcionality
            if (vars.watchers["Gamecode"].Current == null || !vars.Gamecodes.ContainsKey(vars.watchers["Gamecode"].Current))
                return false;

            // gc is used to differentiale between PAL and NTSC versions of the game, as they use different addresses
            var gc = vars.Gamecodes[vars.watchers["Gamecode"].Current];

            current.IGT = vars.watchers["Status" + gc].Current > 7 || vars.watchers["Status" + gc].Current == 2 ? old.IGT : TimeSpan.FromSeconds(Math.Truncate((vars.watchers["IGT" + gc].Current / (double)(gc == "_PAL" ? vars.watchers["FrameRate" + gc].Current : 60)) * 10) / 10);
            break;
    }

    // This part below is common to both game versions
    if (timer.CurrentPhase == TimerPhase.NotRunning)
        vars.AccumulatedIGT = TimeSpan.Zero;

    if (current.IGT < old.IGT)
        vars.AccumulatedIGT += old.IGT;
}

gameTime
{
    return current.IGT + vars.AccumulatedIGT;
}

isLoading
{
    return true;
}

exit
{
    vars.CancelSource.Cancel();
}

shutdown
{
    vars.CancelSource.Cancel();
}
