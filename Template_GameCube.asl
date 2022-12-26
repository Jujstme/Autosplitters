// Basic template for GameCube games
// Coding: Jujstme
// Should support every available version of Dolphin

state("Dolphin") {}

init
{
    // Known gamecodes for the game you want to support
    // You can look for known gamecodes on https://wiki.dolphin-emu.org/
    // For example, known gamecodes for Sonic Adventure 2 Battle are: GSNP8P, GSNE8P, GSBJ8P
    var Gamecodes = new List<string>
    {
        "GSNP8P", "GSNE8P", "GSBJ8P"
    };

    // Input your memory addresses here
    var GetWatchers = (Func<IntPtr, MemoryWatcherList>)(MEM1 => new MemoryWatcherList{
        new MemoryWatcher<int>(MEM1 + 0xA5584) { Name = "IGT" },
        new MemoryWatcher<byte>(MEM1 + 0xA3408) { Name = "LevelNo" },
    });


    // Please do not modify the script below this point unless you know what you're doing
    vars.InitTask = (Action)(() => {
        vars.InitCompleted = false;
        vars.CancelSource = new CancellationTokenSource();

        System.Threading.Tasks.Task.Run(async () =>
        {
            vars.DebugPrint("  => Init Task started");
            IntPtr MEM1 = IntPtr.Zero;

            while (!vars.CancelSource.IsCancellationRequested && MEM1 == IntPtr.Zero)
            {
                vars.DebugPrint("  => Locating base RAM address (MEM1)...");
                MEM1 = game.MemoryPages(true).FirstOrDefault(p => p.Type == MemPageType.MEM_MAPPED && p.State == MemPageState.MEM_COMMIT && (int)p.RegionSize == 0x2000000).BaseAddress;
                if (MEM1 != IntPtr.Zero)
                    vars.DebugPrint("    => MEM1 address found at 0x" + MEM1.ToString("X"));
                else
                {
                    vars.DebugPrint("  => MEM1 address not found. Retrying in 2000ms...");
                    await System.Threading.Tasks.Task.Delay(2000, vars.CancelSource.Token);
                }
            }

            if (!vars.CancelSource.IsCancellationRequested)
            {
                vars.DebugPrint("  => Setting up MemoryWatchers...");
                vars.watchers = GetWatchers(MEM1);
                vars.KeepAlive = (Func<bool>)(() => { byte[] output; return game.ReadBytes(MEM1, 1, out output); });
                vars.CheckGameCode = (Func<bool>)(() => Gamecodes.Contains(game.ReadString(MEM1, 6, " ")));
                vars.DebugPrint("    => Done");
                vars.InitCompleted = true;
                vars.DebugPrint("  => Init completed.");
            }
        });
    });

    vars.PreUpdate = (Func<bool>)(() => {
        if (!vars.InitCompleted)
            return false;
        
        if (!vars.KeepAlive())
        {
            vars.InitTask();
            return false;
        }
        
        if (!vars.CheckGameCode())
            return false;

        vars.watchers.UpdateAll(game);
        return true;
    });

    vars.InitTask();
}

startup
{    
    vars.DebugPrint = (Action<string>)((string obj) => print("[Dolphin] " + obj));
    vars.CancelSource = new CancellationTokenSource();
    vars.ShortToLittleEndian = (Func<short, short>)(input => BitConverter.ToInt16(BitConverter.GetBytes(input).Reverse().ToArray(), 0));
    vars.IntToLittleEndian = (Func<int, int>)(input => BitConverter.ToInt32(BitConverter.GetBytes(input).Reverse().ToArray(), 0));
    vars.FloatToLittleEndian = (Func<float, float>)(input => BitConverter.ToSingle(BitConverter.GetBytes(input).Reverse().ToArray(), 0));
}

update
{
    if (!vars.PreUpdate())
        return false;
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