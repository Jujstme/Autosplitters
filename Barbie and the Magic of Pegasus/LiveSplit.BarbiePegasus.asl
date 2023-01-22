// Autosplitter and load time remover for Barbie and the Magic of Pegasus
// Coding: Jujstme
// contacts: just.tribe@gmail.com
// Version: 1.0.0 (Jan 21st, 2023)

state("Barbie Pegasus") {}

startup
{
    // Settings
    string[,] Settings =
    {
        { "castle",             "Castle" },
        { "forestpuzzles",      "Forbidden forest" },
        { "steppingstones",     "Forbidden forest - stepping stones" },
        { "gianthut",           "Giant's Hut" },
        { "icecavern",          "Ice cavern" },
        { "icesteppingstones",  "Ice cavern - stepping stones" },
        { "icecavernpuzzles",   "Ice cavern puzzles" },
        { "encampment",         "Encampment" },
        { "wenlockapproach",    "Wenlock's castle - exterior" },
        { "wenlocksstones",     "Wenlock's castle - stepping stones" },
        { "wenlock",            "Wenlock" },
    };
    for (int i = 0; i < Settings.GetLength(0); i++)
        settings.Add(Settings[i, 0], true, Settings[i, 1]);


    vars.SplitBools = new Dictionary<string, Func<bool>>
    {
        { "castle",            () => vars.watchers["Scene"].Old == "Cloud City"                             && vars.watchers["Scene"].Current == "Forest - Forest Approach" },
        { "forestpuzzles",     () => vars.watchers["Scene"].Old == "Ferris Shack"                           && vars.watchers["Scene"].Current == "Giants Hut Approach" },
        { "steppingstones",    () => vars.watchers["Scene"].Old == "Giants Hut - Stepping Stone"            && vars.watchers["Scene"].Current == "Giants Hut" },
        { "gianthut",          () => vars.watchers["Scene"].Old == "Giants Hut"                             && vars.watchers["Scene"].Current == "Ice Cavern - Approach" },
        { "icecavern",         () => vars.watchers["Scene"].Old == "Ice Cavern - Stepping Stones Approach"  && vars.watchers["Scene"].Current == "Ice Cavern - Stepping Stones" },
        { "icesteppingstones", () => vars.watchers["Scene"].Old == "Ice Cavern - Stepping Stones"           && vars.watchers["Scene"].Current == "Ice Cavern - Bridge Approach" },
        { "icecavernpuzzles",  () => vars.watchers["Scene"].Old == "Ice Cavern - Cavern Chase"              && vars.watchers["Scene"].Current == "Unknown Level" },
        { "encampment",        () => vars.watchers["Scene"].Old == "Encampment - Mystical Rays"             && vars.watchers["Scene"].Current == "Fjord - Dodging Gryphons" },
        { "wenlockapproach",   () => vars.watchers["Scene"].Old == "Wenlocks - Runes"                       && vars.watchers["Scene"].Current == "Wenlocks - Lantern Game" },
        { "wenlocksstones",    () => vars.watchers["Scene"].Old == "Wenlocks - Stepping Stones"             && vars.watchers["Scene"].Current == "Wenlocks - Wenlocks Puzzle"},
        { "wenlock",           () => vars.watchers["Scene"].Current == "Wenlocks - Good V's Bad"            && !vars.watchers["GameComplete"].Old && vars.watchers["GameComplete"].Current },
    };

    vars.AlreadySplitted = new List<string>();
}

init
{
    IntPtr ptr;
    SignatureScanner scanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);
    Action<IntPtr> CheckPtr = (Action<IntPtr>)((addr) => { if (addr == IntPtr.Zero) throw new NullReferenceException("Sigscan failed"); });
    vars.watchers = new MemoryWatcherList();

    ptr = scanner.Scan(new SigScanTarget(4, "74 ?? 8B 0D ???????? 8B 15 ???????? 51") { OnFound = (p, _, addr) => p.ReadPointer(addr) });
    CheckPtr(ptr);
    vars.watchers.Add(new MemoryWatcher<float>(ptr) { Name = "SplashScreen" });

    ptr = scanner.Scan(new SigScanTarget(1, "E8 ???????? 8B 46 7C") { OnFound = (p, _, addr) => p.ReadPointer(addr + 0x6 + p.ReadValue<int>(addr)) });
    CheckPtr(ptr);
    vars.watchers.Add(new MemoryWatcher<bool>(ptr) { Name = "GameComplete" });

    ptr = scanner.Scan(new SigScanTarget(1, "E8 ???????? E8 ???????? 6A 01 B9 ????????") { OnFound = (p, _, addr) => p.ReadPointer(addr + 0x5 + p.ReadValue<int>(addr)) + 0x4 });
    CheckPtr(ptr);
    vars.watchers.Add(new StringWatcher(ptr, 150) { Name = "Scene" });

    // Default values
    current.isLoading = false;
}

update
{
    // Updating the main watchers variable
    vars.watchers.UpdateAll(game);
    current.isLoading = vars.watchers["SplashScreen"].Current == 0f ? false : vars.watchers["SplashScreen"].Current == 1 ? true : vars.watchers["SplashScreen"].Current != vars.watchers["SplashScreen"].Old ? (vars.watchers["SplashScreen"].Old == 0f ? true :  vars.watchers["SplashScreen"].Old == 1f ? false : old.isLoading) : old.isLoading;
}

start
{
    return vars.watchers["Scene"].Current == "Throne room" && old.isLoading && !current.isLoading;
}

split
{
    foreach (var entry in vars.SplitBools)
    {
        if (vars.AlreadySplitted.Contains(entry.Key))
            continue;

        if (entry.Value())
        {
            vars.AlreadySplitted.Add(entry.Key);
            return settings[entry.Key];
        }
    }
}

isLoading
{
    return current.isLoading;
}

reset
{
    return vars.watchers["Scene"].Current == "Throne room" && old.isLoading && !current.isLoading;
}

onReset
{
    vars.AlreadySplitted.Clear();
}
