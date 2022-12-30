// Kula World
// Autosplitter and automatic in-game timer calculator
// Coding: Jujstme

// This script also serves as a example script for use with emu-help

// LiveSplit itself is used as a state descriptor.
// It's kinda of a hack, but a necessity to make the script run.
// The emu-help will internally look for the emulators it supports.
// --> Tip: if emu-help gets updated with support for new emulators, you won't need to update the script.
state("LiveSplit") {}

startup
{
    // Creates a persistent instance of the PS1 class (for PS1 emulators)
    vars.Helper = Assembly.Load(File.ReadAllBytes("Components/emu-help")).CreateInstance("PS1");

    // In order to make the helper work, you need to define a Dictionary<string, string> with valid IDs
    // for the game you want to support in your script. The following Keys are relative to the game "Kula World"
    // You can look up for known IDs on https://psxdatacenter.com/
    // The autosplitter will work only for the games with the IDs defined in this Dictionary.
    vars.Helper.Gamecodes = new Dictionary<string, string>
    {
        { "SCES-01000", "PAL" },
        { "SLUS-00724", "NTSC-U" },
        { "SCPS-10064", "NTSC-J" }
    };

    // Define a new MemoryWatcherList with the addresses we need in our autosplitter.
    // All addresses are relative offsets to the base WRAM address, which is picked up
    // automatically by the helper.
    // The three StringWatchers defined here are required for the autosplitter to work,
    // as they correspond to the addresses at which the helper needs to check whether
    // the game being run by the emulator is among the supported ones or not.
    // The PAL / NTSC-U / NTSC-J definitions allow for easy identification
    vars.Helper.Load = (Func<IntPtr, MemoryWatcherList>)(wram => new MemoryWatcherList{
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
    
    // Our standard startup code can be put below this point
    vars.AccumulatedIGT = TimeSpan.Zero;
    settings.Add("level", false, "Split at the end of each level (instead of at the end of each world)");

}

update
{
    // This line is required to run the main loop inside the helper
    if (!vars.Helper.Update()) return false;

    // Below this point we can put all the code we want for the update block.
    // Note I use:
    // - vars.Helper["DemoMode"].Current --> which internally calls vars.Helper.Watchers["PAL_DemoMode"].Current (in this case for SCES-01000)
    // - vars.Helper.GameRegion (which corrsponds to the Value defined in the Gamecodes Dictionary - easy way to discriminate between the various versions of a game if required).
    current.IGT = vars.Helper["DemoMode"].Current ? TimeSpan.Zero : TimeSpan.FromSeconds(vars.Helper["IGT"].Current / (vars.Helper.GameRegion == "PAL" ? 50d : 60d));

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
    return vars.Helper["IGT"].Current != 0 && vars.Helper["IGT"].Old == 0 && !vars.Helper["DemoMode"].Current;
}

split
{
    return settings["level"]
        ? !vars.Helper["DemoMode"].Current && vars.Helper["LevelNo"].Changed && vars.Helper["LevelNo"].Current < 15 && !(vars.Helper["LevelNo"].Current == 0 && vars.Helper["WorldNo"].Current == 0)
        : !vars.Helper["DemoMode"].Current && vars.Helper["WorldNo"].Current > vars.Helper["WorldNo"].Old;
}

gameTime
{
    return vars.AccumulatedIGT + current.IGT;
}

shutdown
{
    // Terminates the main Task being run inside the helper
    // Please don't remove this line from this block
    vars.Helper.Dispose();
}
