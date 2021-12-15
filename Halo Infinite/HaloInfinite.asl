// The script currently only provides a loadless timer for Halo Infinite
// Splitting will be implemented when the Halo community defines the splits required for the speedrun

state("HaloInfinite") {}

init
{
    if (!game.Is64Bit()) throw new Exception("Not a 64bit application!");

    // Initialize the main watcher variable
    vars.watchers = new MemoryWatcherList();

    // Initialize variables needed for sigscanning
    IntPtr ptr;
    SignatureScanner scanner;
    long gameBaseAddress = (long)modules.First().BaseAddress;
    var pages = game.MemoryPages(true).Where(m => (long)m.BaseAddress >= gameBaseAddress);
    Dictionary<string, bool> FoundVars = new Dictionary<string, bool>{
        {"LoadStatusPercentage", false},
        {"StatusString", false},
        {"LoadScreen", false}
    };

    foreach (var page in pages)
    {
        scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

        if (!FoundVars["LoadStatusPercentage"]) {
            ptr = scanner.Scan(new SigScanTarget(2,
                "89 05 ????????",      // mov [HaloInfinite.exe+43265A8],eax
                "48 81 C4 ????????",   // add rsp,00006378
                "41 5F"));             // pop r15
            if (ptr != IntPtr.Zero) {
                vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr))) { Name = "LoadStatusPercentage" });
                vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + game.ReadValue<int>(ptr))) { Name = "LoadStatus" });
                FoundVars["LoadStatusPercentage"] = true;
            }
        }

        if (!FoundVars["StatusString"]) {
            ptr = scanner.Scan(new SigScanTarget(12, "00 00 00 00 00 00 00 00 00 00 00 00 6C 6F 61 64"));
            if (ptr != IntPtr.Zero) {
                vars.watchers.Add(new StringWatcher(new DeepPointer(ptr), 255) { Name = "StatusString" });
                FoundVars["StatusString"] = true;
            }
        }

        if (!FoundVars["LoadScreen"]) {
            ptr = scanner.Scan(new SigScanTarget(2,
                "80 3D ???????? 00",    // cmp byte ptr [HaloInfinite.exe+3E030A0],00  <----
                "74 17",                // je HaloInfinite.exe+161FAF4
                "48 8D 0D ????????",    // lea rcx,[HaloInfinite.exe+3E030A8]
                "E8 ????????",          // call HaloInfinite.exe+D18C20
                "84 C0"));              // test al,al
            if (ptr != IntPtr.Zero) {
                vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(ptr + 5 + game.ReadValue<int>(ptr))) { Name = "LoadScreen" });
                FoundVars["LoadScreen"] = true;
            }
        }

        if (FoundVars["LoadStatusPercentage"] && FoundVars["StatusString"] && FoundVars["LoadScreen"]) break;
    }

/*
    // Old method, still kept in here in case of need
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
