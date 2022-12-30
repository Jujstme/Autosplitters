// TimeSplitters: Future Perfect
// IGT calculator
// Supports both the GCN and the PS2 version
// Coding: Jujstme
// Last update: Dec 30th, 2022

state("LiveSplit") {}

startup
{
    var ASM = Assembly.Load(File.ReadAllBytes("Components/emu-help"));
    vars.PS2Helper = ASM.CreateInstance("PS2");
    vars.GCNHelper = ASM.CreateInstance("GCN");
    vars.HelperArray = new dynamic[] { vars.PS2Helper, vars.GCNHelper };
    

    // PS2 Helper
    vars.PS2Helper.Gamecodes = new Dictionary<string, string>
    {
        { "SLES-52993", "PAL"  },
        { "SLUS-21148", "NTSC" }
    };

    vars.PS2Helper.Load = (Func<IntPtr, MemoryWatcherList>)(wram => new MemoryWatcherList
    {
        new StringWatcher(wram + 0x3BA13, 10) { Name = "PAL_Gamecode" },
        new StringWatcher(wram + 0x3BA13, 10) { Name = "NTSC_Gamecode" },

        // PAL
        new MemoryWatcher<byte>(wram + 0x8BCA8) { Name = "PAL_FrameRate" },
        new MemoryWatcher<int>(wram + 0x460A8) { Name = "PAL_IGT" },
        new MemoryWatcher<byte>(wram + 0x4608C) { Name = "PAL_Status" },

        // NTSC
        new MemoryWatcher<byte>(IntPtr.Zero) { Name = "NTSC_FrameRate", Enabled = false, Current = 60, Old = 60 },
        new MemoryWatcher<int>(wram + 0x45FA8) { Name = "NTSC_IGT" },
        new MemoryWatcher<byte>(wram + 0x45F8C) { Name = "NTSC_Status" },
    });


    // GCN Helper
    vars.GCNHelper.Gamecodes = new string[] { "G3FD69", "G3FE69", "G3FF69", "G3FP69", "G3FS69" };

    vars.GCNHelper.Load = (Func<IntPtr, MemoryWatcherList>)(MEM1 => new MemoryWatcherList
    {  
        new MemoryWatcher<byte>(MEM1 + 0x6109C3) { Name = "FrameRate" },
        new MemoryWatcher<int>(MEM1 + 0x611908) { Name = "IGT" },
        new MemoryWatcher<byte>(MEM1 + 0x611937) { Name = "Status" },      
    });
    

    // Helper selector
    vars.HelperUpdate = (Func<bool>)(() =>
    {
        foreach (var entry in vars.HelperArray)
        {
            if (entry.Update())
            {
                vars.Helper = entry;
                return true;
            }
        }
        return false;
    });

    // Default values
    vars.AccumulatedIGT = TimeSpan.Zero;
}

init
{
    current.IGT = TimeSpan.Zero;
}

update
{
    if(!vars.HelperUpdate())
        return false;

    // Update script
    current.IGT = vars.Helper["Status"].Current > 7 || vars.Helper["Status"].Current == 2
        ? old.IGT
        : TimeSpan.FromSeconds(Math.Truncate(vars.Helper["IGT"].Current * 10d / vars.Helper["FrameRate"].Current) / 10);

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

shutdown
{
    foreach (var entry in vars.HelperArray)
        entry.Dispose();
}
