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
        { "intro",   "Intro",             null, true },
        { "dojo",    "Walt's Dojo",       null, true },
        { "forest",  "Dark Forest",       null, true },
        { "terror",  "Terror's Lair",     null, true },
        { "caves",   "Lava Caves",        null, true },
        { "durian",  "Durian Valley",     null, true },
        { "river",   "River Track",       null, true },
        { "park",    "Monkey Park",       null, true },
        { "throne",  "Jungle Throne",     null, true },
        { "canyon",  "Frosty Canyon",     null, true },
        { "slopes",  "Icy Slopes",        null, true },
        { "springs", "Hot Springs",       null, true },
        { "spirits", "Temple of Spirits", null, true },
        { "funfair", "Sparkly Funfair",   null, true },
        { "crystal", "Crystal Caverns",   null, true },
        { "dad",     "Eternal Chambers",  null, true }
    };
    // Autobuild the settings based on the info provided above
    for (int i = 0; i < Settings.GetLength(0); i++) settings.Add(Settings[i, 0], Settings[i, 3], Settings[i, 1], Settings[i, 2]);


    vars.Levels = new Dictionary<string, string>{
        { "mainmenu",   "Level_MainMenu" },
        { "intro",      "Level_Intro_01" },
        { "dojo",       "Level_KaoIsland_01" },
        { "forest",     "Level_KaoIsland_02" },
        { "terror",     "Level_KaoIsland_03" },
        { "caves",      "Level_KaoIsland_04" },
        { "durian",     "Level_Jungle_01" },
        { "river",      "Level_Jungle_02" },
        { "park",       "Level_Jungle_03" },
        { "throne",     "Level_Jungle_04" },
        { "canyon",     "Level_Frozen_01" },
        { "slopes",     "Level_Frozen_02" },
        { "springs",    "Level_Frozen_03" },
        { "spirits",    "Level_Frozen_04" },
        { "funfair",    "Level_IsleOfEternity_01" },
        { "crystal",    "Level_IsleOfEternity_03" },
        { "dad",        "Level_IsleOfEternity_04" }
    };

    // SplitBools: a dictionary of booleans that will tell us if we met the conditions to split at a certain point during the run
    vars.SplitBools = new Dictionary<string, Func<bool>>{
        { "intro",      () => vars.watchers["Level"].Old == vars.Levels["intro"]   && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "dojo",       () => vars.watchers["Level"].Old == vars.Levels["dojo"]    && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "forest",     () => vars.watchers["Level"].Old == vars.Levels["forest"]  && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "terror",     () => vars.watchers["Level"].Old == vars.Levels["terror"]  && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "caves",      () => vars.watchers["Level"].Old == vars.Levels["caves"]   && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "durian",     () => vars.watchers["Level"].Old == vars.Levels["durian"]  && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "river",      () => vars.watchers["Level"].Old == vars.Levels["river"]   && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "park",       () => vars.watchers["Level"].Old == vars.Levels["park"]    && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "throne",     () => vars.watchers["Level"].Old == vars.Levels["throne"]  && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "canyon",     () => vars.watchers["Level"].Old == vars.Levels["canyon"]  && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "slopes",     () => vars.watchers["Level"].Old == vars.Levels["slopes"]  && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "springs",    () => vars.watchers["Level"].Old == vars.Levels["springs"] && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "spirits",    () => vars.watchers["Level"].Old == vars.Levels["spirits"] && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "funfair",    () => vars.watchers["Level"].Old == vars.Levels["funfair"] && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "crystal",    () => vars.watchers["Level"].Old == vars.Levels["crystal"] && vars.watchers["Level"].Old != vars.watchers["Level"].Current },
        { "dad",        () => vars.watchers["Level"].Current == vars.Levels["dad"] && vars.watchers["Level"].Old == vars.watchers["Level"].Current && vars.watchers["FBHealth"].Current > 0 && vars.watchers["FBHealth"].Current == 0 }
    };

    vars.AlreadySplitted = new List<string>();
}

init
{
    // Define main watchers variable
    vars.watchers = new MemoryWatcherList();
    var scanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);
    var ptr = IntPtr.Zero;
    Action checkptr = () => { if (ptr == IntPtr.Zero) throw new NullReferenceException(); };

    ptr = scanner.Scan(new SigScanTarget(5, "89 43 60 8B 05") { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) }); checkptr();
    vars.watchers.Add(new MemoryWatcher<bool>(ptr) { Name = "isLoading" });

    ptr = scanner.Scan(new SigScanTarget(10, "80 7C 24 ?? 00 ?? ?? 48 8B 3D ???????? 48") { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) }); checkptr();
    // TIL thanks to Ero about ReadStringType. And also the pointer paths.
    vars.watchers.Add(new StringWatcher(new DeepPointer(ptr, 0x4A0, 0x0), ReadStringType.UTF16, 255) { Name = "LevelPath" });
    vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(ptr, 0x180, 0x38, 0x0, 0x30, 0x800, 0x4F8)) { Name = "FBHealth" });

    ptr = scanner.Scan(new SigScanTarget(2, "2B 1D ???????? 45 33 C0") { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) }); checkptr();
    vars.watchers.Add(new MemoryWatcher<byte>(ptr) { Name = "StartTrigger" });

    // Dummy watchers
    vars.watchers.Add(new StringWatcher(IntPtr.Zero, 1) { Name = "Level", Enabled = false });
}

update
{
    // Updating the main watchers variable
    vars.watchers.UpdateAll(game);

    // Dummy watchers
    vars.watchers["Level"].Old = vars.watchers["LevelPath"].Old.Split('/')[vars.watchers["LevelPath"].Old.Split('/').Length - 1];
    vars.watchers["Level"].Current = vars.watchers["LevelPath"].Current.Split('/')[vars.watchers["LevelPath"].Current.Split('/').Length - 1];
}

isLoading
{
    return vars.watchers["isLoading"].Current;
}

start
{
    return vars.watchers["StartTrigger"].Current == vars.watchers["StartTrigger"].Old + 1 && vars.watchers["Level"].Old == vars.Levels["mainmenu"];
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

onReset
{
    vars.AlreadySplitted = new List<string>();
}
