// TimeSplitters: Future Perfect
// IGT calculator
// Coding: Jujstme

state("Dolphin") {}

init
{
    // Default values
    current.IGT = TimeSpan.Zero;
    current.rawIGT = TimeSpan.Zero;

    // Default state for the Init Task
    vars.InitCompleted = false;

    // This function runs a Task that asynchronously looks for the memory
    // addresses needed by the game in the emulated memory in Dolphin.
    // As the WRAM base address can change when when the emulation is restarted,
    // this will look again for the correct memory addresses.
    vars.InitTask = (Action)(() => System.Threading.Tasks.Task.Run(async () =>
    {
        // First, set the InitCompleted status to false.
        // It's probably redundant, but it's important this variable stays set to false until the Task is completed
        vars.InitCompleted = false;

        // Base address for MEM1
        IntPtr MEM1 = IntPtr.Zero;

        vars.DebugPrint("  => Locating base RAM address (MEM1)...");
        while (!vars.CancelSource.IsCancellationRequested && MEM1 == IntPtr.Zero)
        {
            MEM1 = game.MemoryPages(true).FirstOrDefault(p => p.Type == MemPageType.MEM_MAPPED && p.State == MemPageState.MEM_COMMIT && (int)p.RegionSize == 0x2000000).BaseAddress;

            if (MEM1 != IntPtr.Zero)
                vars.DebugPrint("  => MEM1 address found at 0x" + MEM1.ToString("X"));
            else
            {
                vars.DebugPrint("  => MEM1 address not found. Retrying in 2000 ms...");
                await System.Threading.Tasks.Task.Delay(2000, vars.CancelSource.Token);
            }
        }

        if (!vars.CancelSource.IsCancellationRequested)
        {
            vars.DebugPrint("  => Setting up MemoryWatchers...");

            vars.watchers = new MemoryWatcherList
            {
                // KeepAlive is just part of a very basic check. Since the first bytes of MEM1 is always part of the internal game code, it will always be true.
                // It only returns false if the ReadAction fails, signalling the memory page is no longer valid.
                new MemoryWatcher<bool>(MEM1) { Name = "KeepAlive", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull },

                new MemoryWatcher<float>(MEM1 + 0x570A08) { Name = "IGT" },
            };

            vars.DebugPrint("    => Done");
            vars.InitCompleted = true;
        }
    }));

    vars.InitTask();
}

startup
{
    vars.CancelSource = new CancellationTokenSource();

    // Debug functions
    var debug = true; // Easy flag to quickly enable and disable debug outputs. When they're not needed anymore all it takes is to set this to false.
    vars.DebugPrint = (Action<string>)((string obj) => { if (debug) print("[TimeSplitters] " + obj); });

    // Default values
    vars.BufferIGT = TimeSpan.Zero;
    vars.AccumulatedIGT = TimeSpan.Zero;

    // Custom func
    vars.FloatToLittleEndian = (Func<float, float>)(input => {
        byte[] temp = BitConverter.GetBytes(input);
        Array.Reverse(temp);
        return BitConverter.ToSingle(temp, 0);
    });
}

update
{
    // If the Init Task has not completed, this prevents the autosplitter from proceeding further
    if (!vars.InitCompleted) return false;

    vars.watchers.UpdateAll(game);

    // If KeepAlive returna false (see above) we want to re-run the Init Task and look for the memory addresses again
    if (!vars.watchers["KeepAlive"].Current)
    {
        vars.InitTask();
        return false;
    }

    // From now on, we want the "proper" update block
    current.rawIGT = TimeSpan.FromSeconds(vars.FloatToLittleEndian(vars.watchers["IGT"].Current));
    current.IGT = current.rawIGT - vars.BufferIGT;

    if (timer.CurrentPhase == TimerPhase.NotRunning)
    {
        vars.AccumulatedIGT = TimeSpan.Zero;
        vars.BufferIGT = TimeSpan.Zero;
    }

    if (current.rawIGT < old.rawIGT)
        vars.AccumulatedIGT += old.rawIGT;
}

onStart
{
    vars.BufferIGT = current.rawIGT;
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