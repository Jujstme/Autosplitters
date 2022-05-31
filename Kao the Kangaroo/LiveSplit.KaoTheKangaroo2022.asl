// Autosplitter and load time remover for Kao The Kangaroo (2022)
// Coding: Jujstme
// contacts: just.tribe@gmail.com
// Version: 1.0.0 (May 31st, 2022)
// Thanks to Ero for helping me understanding how Unreal Engine works

state("Kao-Win64-Shipping") {}

startup
{
    // Settings
    // --> ID, Setting name, parent, enabled
    dynamic[,] Settings =
    {
        { "autoStart", "Enable auto start", null, true },
        { "autosplitting", "Autosplitting options", null, true },
            { "intro", "Intro", "autosplitting", true },
            { "dojo", "Walt's dojo", "autosplitting", true },
            { "forest", "Dark forest", "autosplitting", true },
            { "terror", "Terror's lair", "autosplitting", true },
            { "caves", "Lava caves", "autosplitting", true },
            { "durian", "Durian valley", "autosplitting", true },
            { "river", "River track", "autosplitting", true },
            { "park", "Monkey park", "autosplitting", true },
            { "throne", "Jungle throne", "autosplitting", true },
            { "canyon", "Frosty canyon", "autosplitting", true },
            { "funfair", "Sparkly funfair", "autosplitting", true },
            { "crystal", "Crystal caverns", "autosplitting", true },
            { "dad", "Eternal chambers", "autosplitting", true }
    };
    // Autobuild the settings based on the info provided above
    for (int i = 0; i < Settings.GetLength(0); i++) settings.Add(Settings[i, 0], Settings[i, 3], Settings[i, 1], Settings[i, 2]);


    vars.Maps = new Dictionary<string, string>{
        { "intro", "Level_Intro_01" },
        { "dojo", "Level_KaoIsland_01" },
        { "forest", "Level_KaoIsland_02" },
        { "terror", "Level_KaoIsland_03" },
        { "caves", "Level_KaoIsland_04" },
        { "durian", "Level_Jungle_01" },
        { "river", "Level_Jungle_02" },
        { "park", "Level_Jungle_03" },
        { "throne", "Level_Jungle_04" },
        { "canyon", "Level_Frozen_01" },
        { "slopes", "Level_Frozen_02" },
        { "springs", "Level_Frozen_03" },
        { "spirits", "Level_Frozen_04" },
        { "funfair", "Level_IsleOfEternity_01" },
        { "crystal", "Level_IsleOfEternity_03" },
        { "dad", "Level_IsleOfEternity_04" }
    };

    // SplitBools: a dictionary of booleans that will tell us if we met the conditions to split at a certain point during the run
    vars.SplitBools = new Dictionary<string, Func<bool>>{
        { "intro", () => vars.watchers["Level"].Old == vars.Maps["intro"] && vars.watchers["Level"].Changed },
        { "dojo", () => vars.watchers["Level"].Old == vars.Maps["dojo"] && vars.watchers["Level"].Changed },
        // { "webskip", () => vars.watchers["Level"].Old == vars.Maps["island"] && vars.watchers["Level"].Changed },
        { "forest", () => vars.watchers["Level"].Old == vars.Maps["forest"] && vars.watchers["Level"].Changed },
        { "terror", () => vars.watchers["Level"].Old == vars.Maps["terror"] && vars.watchers["Level"].Changed },
        { "caves", () => vars.watchers["Level"].Old == vars.Maps["caves"] && vars.watchers["Level"].Changed },
        { "durian", () => vars.watchers["Level"].Old == vars.Maps["durian"] && vars.watchers["Level"].Changed },
        { "river", () => vars.watchers["Level"].Old == vars.Maps["river"] && vars.watchers["Level"].Changed },
        { "park", () => vars.watchers["Level"].Old == vars.Maps["park"] && vars.watchers["Level"].Changed },
        { "throne", () => vars.watchers["Level"].Old == vars.Maps["throne"] && vars.watchers["Level"].Changed },
        { "canyon", () => vars.watchers["Level"].Old == vars.Maps["canyon"] && vars.watchers["Level"].Changed },
        { "slopes", () => vars.watchers["Level"].Old == vars.Maps["slopes"] && vars.watchers["Level"].Changed },
        { "springs", () => vars.watchers["Level"].Old == vars.Maps["springs"] && vars.watchers["Level"].Changed },
        { "spirits", () => vars.watchers["Level"].Old == vars.Maps["spirits"] && vars.watchers["Level"].Changed },
        { "funfair", () => vars.watchers["Level"].Old == vars.Maps["funfair"] && vars.watchers["Level"].Changed },
        { "crystal", () => vars.watchers["Level"].Old == vars.Maps["crystal"] && vars.watchers["Level"].Changed },
        { "dad", () => vars.watchers["Level"].Current == vars.Maps["dad"] && !vars.watchers["Level"].Changed && vars.watchers["FBHealth"].Current > 0 && vars.watchers["FBHealth"].Current == 0 }
    };
    vars.AlreadySplitted = new List<string>();

    var Debug = false;
    vars.DebugPrint = (Action<string>)((string obj) => { if (Debug) print("[KAO] " + obj); });
}

init
{
    // Define main watchers variable
    vars.watchers = new MemoryWatcherList();
    var scanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);
    var ptr = IntPtr.Zero;
    Action checkptr = () => { if (ptr == IntPtr.Zero) throw new NullReferenceException(); };

    ptr = scanner.Scan(new SigScanTarget(5, "89 43 60 8B 05") { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
    checkptr();
    vars.DebugPrint("  => isLoading: address found at 0x" + ((long)ptr - (long)modules.First().BaseAddress).ToString("X"));
    vars.watchers.Add(new MemoryWatcher<bool>(ptr) { Name = "isLoading" });

    ptr = scanner.Scan(new SigScanTarget(10, "80 7C 24 ?? 00 ?? ?? 48 8B 3D ???????? 48") { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
    checkptr();
    vars.DebugPrint("  => GWorld address found at 0x" + ((long)ptr - (long)modules.First().BaseAddress).ToString("X"));
    vars.watchers.Add(new StringWatcher(new DeepPointer(ptr, 0x180, 0x268, 0x40, 0x8, 0x8, 0x2B), 250) { Name = "Level" });
    vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(ptr, 0x180, 0x38, 0x0, 0x30, 0x800, 0x4F8)) { Name = "FBHealth" }); // Thanks Ero for the pointer path

    ptr = scanner.Scan(new SigScanTarget(2, "2B 1D ???????? 45 33 C0") { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
    checkptr();
    vars.DebugPrint("  => StartTrigger address found at 0x" + ((long)ptr - (long)modules.First().BaseAddress).ToString("X"));
    vars.watchers.Add(new MemoryWatcher<byte>(ptr) { Name = "StartTrigger" });
}

update
{
    vars.watchers.UpdateAll(game);

    if (timer.CurrentPhase == TimerPhase.NotRunning && vars.AlreadySplitted.Count > 0)
    {
        vars.AlreadySplitted = new List<string>();
    }
}

isLoading
{
    return vars.watchers["isLoading"].Current;
}

start
{
    return settings["autoStart"] && vars.watchers["StartTrigger"].Current == vars.watchers["StartTrigger"].Old + 1 && vars.watchers["Level"].Current == vars.Maps["intro"];
}

split
{
    foreach (var entry in vars.SplitBools)
    {
        if (!vars.AlreadySplitted.Contains(entry.Key) && entry.Value())
        {
            vars.AlreadySplitted.Add(entry.Key);
            return settings[entry.Key];
        }
    }
}
