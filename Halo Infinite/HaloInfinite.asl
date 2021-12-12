// The script currently only provides a loadless timer for Halo Infinite
// Splitting will be implemented when the Halo community defines the splits required for the speedrun
// Sigscanning doesn't work on this game's .exe so the script needs to be updated after every patch

state("HaloInfinite") {}

init
{
    if (!game.Is64Bit()) throw new Exception("Not a 64bit application!");

    int arbiterModuleSize = modules.Where(x => x.ModuleName == "Arbiter.dll").FirstOrDefault().ModuleMemorySize;

    switch (arbiterModuleSize)
    {
        case 0x1263000: version = "6.10020.17952.0"; break;
        default: version = "Unsupported"; break;
    }

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

/*	
    SigScans to use for newer versions of the game:

    LoadStatus:
      89 35 ????????    // mov [HaloInfinite.exe+43265A4],esi  <----
      F3 0F2C C6        // cvttss2si eax,xmm6

    LoadStatusPercentage: LoadStatus + 0x4
      Alternatively:
        89 05 ????????      // mov [HaloInfinite.exe+43265A8],eax
        48 81 C4 ????????   // add rsp,00006378
        41 5F               // pop r15

    StatusString:
      search for string: loaded levels\ui\mainmenu\mainmenu
      while in the main menu of the game

    LoadScreen
      80 3D ???????? 00    // cmp byte ptr [HaloInfinite.exe+3E030A0],00
      74 17                // je HaloInfinite.exe+161FAF4
      48 8D 0D ????????    // lea rcx,[HaloInfinite.exe+3E030A8]
      E8 ????????          // call HaloInfinite.exe+D18C20
      84 C0                // test al,al
*/

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
