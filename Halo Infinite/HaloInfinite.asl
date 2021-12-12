// The script currently only provides a loadless timer for Halo Infinite
// Splitting will be implemented when the Halo community defines the splits required for the speedrun
// Sigscanning doesn't work on this game's .exe so the script needs to be updated after every patch

state("HaloInfinite") {}

init
{
    if (!game.Is64Bit()) throw new Exception("Not a 64bit application!");

    version = modules.First().FileVersionInfo.FileVersion;

    // Initialize the main watcher variable
    vars.watchers = new MemoryWatcherList();
	
    switch (version) {
        case "6.10020.17952.0": // Release version
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x43265A4)) { Name = "LoadStatus" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x43265A8)) { Name = "LoadStatusPercentage" });
            vars.watchers.Add(new StringWatcher(new DeepPointer(modules.First().BaseAddress + 0x462F2C0), 255) { Name = "StatusString" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x3E030A0)) { Name = "LoadScreen" });
            break;
        default:
            version = "Unsupported";
            MessageBox.Show("You are running an unsupported version of the game.\nAutosplitter will be disabled.", "LiveSplit - Halo Infinite", MessageBoxButtons.OK, MessageBoxIcon.Information);
			break;
	}	
}

startup
{
    MessageBox.Show("Disclaimer: the current load removal works by directly accessing the game memory.\n\nBy using this autosplitter, you acknowledge it is unknown whether this triggers any known anti-cheat measure.\n\nPress OK to continue.", "LiveSplit - Halo Infinite", MessageBoxButtons.OK, MessageBoxIcon.Information);
}

update
{
    if (version == "Unsupported") return false;
    vars.watchers.UpdateAll(game);

    current.CurrentMapName = vars.watchers["StatusString"].Current.Substring(vars.watchers["StatusString"].Current.LastIndexOf("\\") + 1);

    current.IsLoading = vars.watchers["StatusString"].Current.Substring(0, vars.watchers["StatusString"].Current.LastIndexOf(" ")) == "loading" ||
            vars.watchers["LoadStatus"].Current == 3 ||
            // vars.watchers["LoadStatus"].Current < 4 ||
            vars.watchers["LoadScreen"].Current || (vars.watchers["LoadStatusPercentage"].Current != 0 && vars.watchers["LoadStatusPercentage"].Current != 100);
}

start
{
    return current.CurrentMapName == "dungeon_banished_ship" && old.IsLoading && !current.IsLoading;
}

isLoading
{
    return current.IsLoading ?? true;
}
