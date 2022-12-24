// TimeSplitters: Future Perfect
// IGT calculator
// Coding: Jujstme

state("Dolphin") {}

init
{
    // Default state for the Init Task
    vars.InitCompleted = false;

    // Default values
    current.IGT = TimeSpan.Zero;
    refreshRate = 60;

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

                new MemoryWatcher<byte>(MEM1 + 0x6109C3) { Name = "FrameRate" },
                new MemoryWatcher<int>(MEM1 + 0x611908) { Name = "IGT" },
                new MemoryWatcher<byte>(MEM1 + 0x611937) { Name = "Status" },
            };

            vars.DebugPrint("    => Done");
            vars.InitCompleted = true;
        }
    }));

    vars.InitTask();
}

startup
{
    // Debug functions
    var debug = true; // Easy flag to quickly enable and disable debug outputs. When they're not needed anymore all it takes is to set this to false.
    vars.DebugPrint = (Action<string>)((string obj) => { if (debug) print("[TimeSplitters] " + obj); });

    // Default values
    vars.AccumulatedIGT = TimeSpan.Zero;

    // Custom func
    vars.IntToLittleEndian = (Func<int, int>)(input => {
        byte[] temp = BitConverter.GetBytes(input);
        Array.Reverse(temp);
        return BitConverter.ToInt32(temp, 0);
    });

    // CancellationTokenSource - used in the Init Task
    vars.CancelSource = new CancellationTokenSource();
}

update
{
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

    // From now on, we want the "proper" update block

    // Calculate the IGT based on 
    current.IGT = vars.watchers["Status"].Current > 7 || vars.watchers["Status"].Current == 2
        ? old.IGT
        : TimeSpan.FromSeconds(Math.Truncate((vars.IntToLittleEndian(vars.watchers["IGT"].Current) / (double)vars.watchers["FrameRate"].Current) * 10) / 10);

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
