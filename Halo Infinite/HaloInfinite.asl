// Autosplitter and Load Time remover by Jujstme
// Made thanks to the contributions from the HaloRuns community.
// Thanks to all guys who helped in writing this
// Coding: Jujstme
// contacts: just.tribe@gmail.com
// Version: 1.0.10.0 (May 29th, 2022)

/* Changelog
    - 1.0.10.0: added support for v6.10022.10499.0
    - 1.0.9.1: Dropped sigscans because they don't work properly across different versions of the game. Rewrote the offsets manually
    - 1.0.9: updated sigscans to work with Season2 patch
    - 1.0.8.6: added support for version v6.10021.12835.0 (new Arbiter.dll patch) (Mar 22nd, 2022)
    - 1.0.8.5: added support for version v6.10021.12835.0 (Feb 24th 2022 patch)
    - 1.0.8.4: added support for version v6.10021.11755.0 (Feb 4th 2022 patch)
    - 1.0.8.3: added support for version v6.10021.10921.0 (Jan 19th 2022 patch)
    - 1.0.8.2: added support for version v6.10020.17952.0
    - 1.0.8.1: fixed a bug concerning the use of "old" and "current" state variables
    - 1.0.8: slightly improved splitting logic
    - 1.0.7: completely reworked the load removal logic
    - 1.0.6.1: updated the LoadScreen variable
    - 1.0.6.0: fixed sigscanning
*/

state("HaloInfinite") {}

startup
{
    // Long list of settings we want to implement in the autosplitter.
    // Settings that have "split" in their tooltip will be considered for the autosplitting dictionary
    // Format:
    //   { parent, settingID, settingText, settingToolTip, defaultState }
    dynamic[,] Settings =
    {
        { null, "startOnWarship", "Start the timer only when gaining control on Warship Gbraakon", null, false },
        { null, "autosplitting", "Auto Splitting", null, true },
            { "autosplitting", "warshipGbraakon", "Warship Gbraakon", "Will trigger a split after completing the mission \"Warship Gbraakon\".", true },
            { "autosplitting", "foundation", "Foundation", "Will trigger a split after completing the mission \"Foundation\".", true },
            { "autosplitting", "outpostTremonius", "Outpost Tremonius", "Will trigger a split after taking control of Outpost Tremonius.", true },
            { "autosplitting", "FOBGolf", "FOB Golf", "Will trigger a split after taking control of FOB Golf.", true },
            { "autosplitting", "tower", "Tower", "Will trigger a split after freeing Spartan Griffin upon completion of the mission \"The Tower\".", true },
            { "autosplitting", "excavationSite", "Excavation Site", null, true },
                { "excavationSite", "reachTheDigSite", "Reach the Excavation Site", "Will trigger a split after the first cutscene in the excavation site.", true },
                { "excavationSite", "bassus", "Bassus", "Will trigger a split upon entering the Conservatory, after Bassus' defeat.", true },
            { "autosplitting", "conservatory", "Conservatory", "Will trigger a split after completing the mission \"Conservatory\".", true },
            { "autosplitting", "spire", "Spire", null, true},
                { "spire", "spireApproach", "Approach the command spire", "Will trigger a split upon entering the first spire.", true },
                { "spire", "adjutantResolution", "Adjutant Resolution", "Will trigger a split after defeting Adjuvant resolution and dectivating the spire.", true },
            { "autosplitting", "pelicanDown", "Pelican Down", null, true },
                { "pelicanDown", "EastAAGun", "East AA Gun", "Will trigger a split upon destruction of the East AA Gun.", true },
                { "pelicanDown", "NorthAAGun", "North AA Gun", "Will trigger a split upon destruction of the North AA Gun.", true },
                { "pelicanDown", "WestAAGun", "West AA Gun", "Will trigger a split upon destruction of the West AA Gun.", true },
                { "pelicanDown", "spartanKillers", "Hyperius and Tovarus", "Will trigger a split when finding Echo-216 after defeting the Spartan killers Hyperius and Tovarus.", true },
            { "autosplitting", "sequence", "The Sequence", null, true },
                { "sequence", "easternBeacon", "Eastern Beacon", "Will trigger a split after activating the Eastern Beacon.", true },
                { "sequence", "southernBeacon", "Southern Beacon", "Will trigger a split after activating the Southern Beacon.", true },
                { "sequence", "northernBeacon", "Northern Beacon", "Will trigger a split after activating the Northern Beacon.", true },
                { "sequence", "southwesternBeacon", "Southwestern Beacon", "Will trigger a split after activating the Southwestern Beacon.", true },
                { "sequence", "enterNexus", "Enter the Nexus", "Will trigger a split upon entering the Nexus.", true },
            { "autosplitting", "nexus", "Nexus", "Will trigger a split upon completing the mission \"Nexus\".", true },
            { "autosplitting", "commandSpire", "Command Spire", null, true },
                { "commandSpire", "reachTheTop", "Reach the Top", "Will trigger a split upon reaching the top of the Command Spire.", true },
                { "commandSpire", "deactivateCommandSpire", "Deactivate the Command Spire", "Will trigger a split after deactivation of the Command Spire.", true },
            { "autosplitting", "repository", "Repository", "Will trigger a split upon completion of the mission \"Repository\".", true },
            { "autosplitting", "road", "Road", "Will trigger a split upon entering the House of Reckoning.", true },
            { "autosplitting", "houseOfReckoning", "House of Reckoning", "Will trigger a split upon completion of the House of Reckoning.", true },
            { "autosplitting", "silentAuditorium", "Silent Auditorium", "Will trigger a split upon defeat of the Harbringer.", true }
    };
    for (int i = 0; i < Settings.GetLength(0); i++)
    {
        settings.Add(Settings[i, 1], Settings[i, 4], Settings[i, 2], Settings[i, 0]);
        if (!string.IsNullOrEmpty(Settings[i, 3])) settings.SetToolTip(Settings[i, 1], Settings[i, 3]);
    }

    // Define a new ExpandoObject to store some named constants we will need later on
    vars.Maps = new ExpandoObject();
    vars.Maps.MainMenu         = "mainmenu";
    vars.Maps.WarshipGbraakon  = "dungeon_banished_ship";
    vars.Maps.Foundation       = "dungeon_underbelly";
    vars.Maps.ZetaHalo         = "island01";
    vars.Maps.Conservatory     = "dungeon_forerunner_dallas";
    vars.Maps.Spire01          = "dungeon_spire_01";
    vars.Maps.Nexus            = "dungeon_forerunner_houston";
    vars.Maps.Spire02          = "dungeon_spire_02";
    vars.Maps.Repository       = "dungeon_forerunner_austin";
    vars.Maps.HouseOfReckoning = "dungeon_boss_hq_interior";
    vars.Maps.SilentAuditorium = "dungeon_cortana_palace";

    // We need to define two dictionaries we will use to manage autosplitting
    // SplitBools: a dictionary of booleans that will tell us if we met the conditions to split at a certain point during the run
    // AlreadyTriggeredSplits: pretty much self-explanatory, it records if we already triggered a certain splits, avoiding unwanted double splitting
    vars.SplitBools = new Dictionary<string, Func<bool>>{
        { "warshipGbraakon", () => !vars.AlreadyTriggeredSplits["warshipGbraakon"] && vars.Map.Old == vars.Maps.WarshipGbraakon && vars.Map.Current == vars.Maps.Foundation },
        { "foundation", () => !vars.AlreadyTriggeredSplits["foundation"] && vars.Map.Old == vars.Maps.Foundation && vars.Map.Current == vars.Maps.ZetaHalo },
        { "outpostTremonius", () => !vars.AlreadyTriggeredSplits["outpostTremonius"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["OutpostTremonius"].Changed && vars.watchers["OutpostTremonius"].Current == 6 },
        { "FOBGolf", () => !vars.AlreadyTriggeredSplits["FOBGolf"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["FOBGolf"].Changed && vars.watchers["FOBGolf"].Current == 10 },
        { "tower", () => !vars.AlreadyTriggeredSplits["tower"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["Tower"].Changed && vars.watchers["Tower"].Current == 10 },
        { "reachTheDigSite", () => !vars.AlreadyTriggeredSplits["reachTheDigSite"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["TravelToDigSite"].Changed && vars.watchers["TravelToDigSite"].Current == 10 },
        { "bassus", () => !vars.AlreadyTriggeredSplits["bassus"] && vars.Map.Old == vars.Maps.ZetaHalo && vars.Map.Current == vars.Maps.Conservatory },
        { "conservatory", () => !vars.AlreadyTriggeredSplits["conservatory"] && vars.Map.Old == vars.Maps.Conservatory && vars.Map.Current == vars.Maps.ZetaHalo },
        { "spireApproach", () => !vars.AlreadyTriggeredSplits["spireApproach"] && vars.Map.Old == vars.Maps.ZetaHalo && vars.Map.Current == vars.Maps.Spire01 },
        { "adjutantResolution", () => !vars.AlreadyTriggeredSplits["adjutantResolution"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["Spire"].Changed && vars.watchers["Spire"].Current == 10 },
        { "EastAAGun", () => !vars.AlreadyTriggeredSplits["EastAAGun"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["PelicanSpartanKillers"].Current != 10 && vars.watchers["EastAAGun"].Changed && vars.watchers["EastAAGun"].Current == 10 },
        { "NorthAAGun", () => !vars.AlreadyTriggeredSplits["NorthAAGun"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["PelicanSpartanKillers"].Current != 10 && vars.watchers["NorthAAGun"].Changed && vars.watchers["NorthAAGun"].Current == 10 },
        { "WestAAGun", () => !vars.AlreadyTriggeredSplits["WestAAGun"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["PelicanSpartanKillers"].Current != 10 && vars.watchers["WestAAGun"].Changed && vars.watchers["WestAAGun"].Current == 10 },
        { "spartanKillers", () => !vars.AlreadyTriggeredSplits["spartanKillers"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["EastAAGun"].Old == 10 && vars.watchers["NorthAAGun"].Old == 10 && vars.watchers["WestAAGun"].Old == 10 && vars.watchers["PelicanSpartanKillers"].Changed && vars.watchers["PelicanSpartanKillers"].Current == 10 },
        { "easternBeacon", () => !vars.AlreadyTriggeredSplits["easternBeacon"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["SequenceEasternBeacon"].Changed && vars.watchers["SequenceEasternBeacon"].Current == 10 },
        { "southernBeacon", () => !vars.AlreadyTriggeredSplits["southernBeacon"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["SequenceSouthernBeacon"].Changed && vars.watchers["SequenceSouthernBeacon"].Current == 10 },
        { "northernBeacon", () => !vars.AlreadyTriggeredSplits["northernBeacon"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["SequenceNorthernBeacon"].Changed && vars.watchers["SequenceNorthernBeacon"].Current == 10 },
        { "southwesternBeacon", () => !vars.AlreadyTriggeredSplits["southwesternBeacon"] && vars.Map.Current == vars.Maps.ZetaHalo && vars.watchers["SequenceSouthwesternBeacon"].Changed && vars.watchers["SequenceSouthwesternBeacon"].Current == 10 },
        { "enterNexus", () => !vars.AlreadyTriggeredSplits["enterNexus"] && vars.Map.Old == vars.Maps.ZetaHalo && vars.Map.Current == vars.Maps.Nexus },
        { "nexus", () => !vars.AlreadyTriggeredSplits["nexus"] && vars.Map.Old == vars.Maps.Nexus && vars.Map.Current == vars.Maps.Spire02 },
        { "reachTheTop", () => !vars.AlreadyTriggeredSplits["reachTheTop"] && vars.Map.Old == vars.Maps.Spire02 && vars.Map.Current == vars.Maps.ZetaHalo },
        { "deactivateCommandSpire", () => !vars.AlreadyTriggeredSplits["deactivateCommandSpire"] && vars.Map.Old == vars.Maps.ZetaHalo && vars.Map.Current == vars.Maps.Repository },
        { "repository", () => !vars.AlreadyTriggeredSplits["repository"] && vars.Map.Old == vars.Maps.Repository && vars.Map.Current == vars.Maps.ZetaHalo },
        { "road", () => !vars.AlreadyTriggeredSplits["road"] && vars.Map.Old == vars.Maps.ZetaHalo && vars.Map.Current == vars.Maps.HouseOfReckoning },
        { "houseOfReckoning", () => !vars.AlreadyTriggeredSplits["houseOfReckoning"] && vars.Map.Old == vars.Maps.HouseOfReckoning && vars.Map.Current == vars.Maps.SilentAuditorium },
        { "silentAuditorium", () => !vars.AlreadyTriggeredSplits["silentAuditorium"] && vars.Map.Current == vars.Maps.SilentAuditorium && vars.watchers["SilentAuditorium"].Changed && vars.watchers["SilentAuditorium"].Current == 10 }
    };
    vars.AlreadyTriggeredSplits = new Dictionary<string, bool>();
    foreach (var entry in vars.SplitBools.Keys)
        vars.AlreadyTriggeredSplits.Add(entry, false);

    // Define a GetCurrentMap function we use to get the current map name
    vars.GetCurrentMap = (Func<string>)(() => vars.watchers["StatusString"].Current.Substring(vars.watchers["StatusString"].Current.LastIndexOf("\\") + 1));

    // Define load state
    vars.GetLoadState = (Func<bool>)( () =>
            vars.watchers["LoadStatus"].Current ||
            !vars.watchers["DoNotFreeze"].Current ||
            vars.watchers["LoadStatus2"].Current > 0 && vars.watchers["LoadStatus2"].Current < 4 ||
            vars.watchers["LoadSplashScreen"].Current >= 1 && vars.watchers["LoadSplashScreen"].Current <= 4
            );

    // Additional vars we use in place of the old and current state variables
    vars.IsLoading = new ExpandoObject();
    vars.IsLoading.Old = false;
    vars.IsLoading.Current = false;

    vars.Map = new ExpandoObject();
    vars.Map.Old = string.Empty;
    vars.Map.Current = string.Empty;

    // Debug
    bool Debug = false;  // Disabled by default, as Halo's anti-cheat system actively monitors debug outputs
    vars.DebugPrint = (Action<string>)((string obj) => { if (Debug) print("[Halo Infinite] " + obj); });
}

init
{
    vars.DebugPrint("Autosplitter Init:");

    var ArbiterModuleSize = modules.Where(x => x.ModuleName == "Arbiter.dll").FirstOrDefault().ModuleMemorySize;
    vars.DebugPrint("  => Arbiter.dll module size: 0x" + ArbiterModuleSize.ToString("X"));

    // Identify the game version. This is used later, so if a game version is known, we can avoid using sigscanning.
    if (!new Dictionary<int, string>{
        { 0x1263000, "v6.10020.17952.0" }, // Season 1
        { 0x133F000, "v6.10020.19048.0" },
        { 0x1262000, "v6.10021.10921.0" },
        { 0x125D000, "v6.10021.11755.0" },
        { 0x17F7000, "v6.10021.12835.0" },
        { 0x1829000, "v6.10021.12835.0" },
        { 0x1827000, "v6.10021.16272.0" },
        // { 0x17DE000, "v6.10021.18539.0" }, // Season 2, disabled for now
        { 0x1806000, "v6.10022.10499.0" },
    }.TryGetValue(ArbiterModuleSize, out version))
    {
        vars.DebugPrint("   => Game version is not among the ones hardcoded in the autosplitter.");
        //vars.DebugPrint("   => Switching to sigscanning...");
        version = "Unknown game version";
    } else {
        vars.DebugPrint("  => Recognized game version: " + version);
    }

    // Basic variable, pretty self-explanatory.
    // We will change it to false if we need to disable the autosplitter for whatever reason.
    vars.IsAutosplitterEnabled = true;

    // Main watchers variable
    vars.watchers = new MemoryWatcherList();

    /* For the autosplitter to work we need 7 variables
     *   - LoadStatus: it's a byte, but treated as a bool in the autosplitter. It fluctuates between 0 and 3, but basically tells the system when we are loading a map in the main menu
     *   - LoadStatus2: byte value, goes from 0 to 4. When 0, we are idling in the menu. When 4, we are ingame
     *   - LoadSplashScreen: it monitors the load splash screen. When the splash screen is displayed, the value can range between 1 and 4
     *   - DoNotFreeze: bool value. It's 0 whenever the game freezes due to loading. It's 1 otherwise
     *   - StatusString: string variable that is used by the autosplitter to determine the current map
     *   - IsLoadingInCutscene: bool value, ugly hack used to remove time when the "loading" message is displayed during cutscenes
     *   - PlotBoolsOffset: it's the main offset used for the plot flags. Used for the autosplitting functions
     */

    // We use a switch statement so, if a game version is recognized, the script will directly grab whatever offsets I manually inputted here.
    // Basically, we want to avoid using sigscanning when possible, as this game and its anti-debug features don't really like it
    switch (version)
    {
        case "v6.10020.17952.0":
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x433037C)) { Name = "LoadStatus" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x43265A4)) { Name = "LoadStatus2" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x43A9384)) { Name = "LoadSplashScreen" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x43A8049)) { Name = "DoNotFreeze" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x3EC2071)) { Name = "IsLoadingInCutscene" });
            vars.watchers.Add(new StringWatcher(new DeepPointer(modules.First().BaseAddress + 0x462F2C0), 255) { Name = "StatusString" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB55D0)) { Name = "WarshipGbraakonStartTrigger" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB5558)) { Name = "OutpostTremonius" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB746C)) { Name = "FOBGolf" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB55B0)) { Name = "Tower" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB72BC)) { Name = "TravelToDigSite" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB5308)) { Name = "Spire" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB7344)) { Name = "EastAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB7354)) { Name = "NorthAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB7364)) { Name = "WestAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB7384)) { Name = "PelicanSpartanKillers" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB9370)) { Name = "SequenceNorthernBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB9378)) { Name = "SequenceSouthernBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB9380)) { Name = "SequenceEasternBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB9388)) { Name = "SequenceSouthwesternBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E485C8, 0xB740C)) { Name = "SilentAuditorium" });			
        break;

        case "v6.10020.19048.0":
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x5007ADC)) { Name = "LoadStatus" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4FFDD04)) { Name = "LoadStatus2" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x50A1B0C)) { Name = "LoadSplashScreen" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x509E5BC)) { Name = "DoNotFreeze" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x48A6AB7)) { Name = "IsLoadingInCutscene" });
            vars.watchers.Add(new StringWatcher(new DeepPointer(modules.First().BaseAddress + 0x4CA11B0), 255) { Name = "StatusString" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB55D0)) { Name = "WarshipGbraakonStartTrigger" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB5558)) { Name = "OutpostTremonius" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB746C)) { Name = "FOBGolf" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB55B0)) { Name = "Tower" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB72BC)) { Name = "TravelToDigSite" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB5308)) { Name = "Spire" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB7344)) { Name = "EastAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB7354)) { Name = "NorthAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB7364)) { Name = "WestAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB7384)) { Name = "PelicanSpartanKillers" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB9370)) { Name = "SequenceNorthernBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB9378)) { Name = "SequenceSouthernBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB9380)) { Name = "SequenceEasternBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB9388)) { Name = "SequenceSouthwesternBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB740C)) { Name = "SilentAuditorium" });
        break;

        case "v6.10021.10921.0":
        case "v6.10021.11755.0":
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x433133C)) { Name = "LoadStatus" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4327564)) { Name = "LoadStatus2" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x43AA344)) { Name = "LoadSplashScreen" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x43A9009)) { Name = "DoNotFreeze" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x3EC3031)) { Name = "IsLoadingInCutscene" });
            vars.watchers.Add(new StringWatcher(new DeepPointer(modules.First().BaseAddress + 0x4630240), 255) { Name = "StatusString" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB55D0)) { Name = "WarshipGbraakonStartTrigger" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB5558)) { Name = "OutpostTremonius" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB746C)) { Name = "FOBGolf" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB55B0)) { Name = "Tower" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB72BC)) { Name = "TravelToDigSite" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB5308)) { Name = "Spire" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB7344)) { Name = "EastAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB7354)) { Name = "NorthAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB7364)) { Name = "WestAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB7384)) { Name = "PelicanSpartanKillers" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB9370)) { Name = "SequenceNorthernBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB9378)) { Name = "SequenceSouthernBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB9380)) { Name = "SequenceEasternBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB9388)) { Name = "SequenceSouthwesternBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x3E49588, 0xB740C)) { Name = "SilentAuditorium" });
        break;
        
        case "v6.10021.12835.0":
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x4643A1C)) { Name = "LoadStatus" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4639C44)) { Name = "LoadStatus2" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x46B1604)) { Name = "LoadSplashScreen" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x46B02C1)) { Name = "DoNotFreeze" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x41D5711)) { Name = "IsLoadingInCutscene" });
            vars.watchers.Add(new StringWatcher(new DeepPointer(modules.First().BaseAddress + 0x492CCA0), 255) { Name = "StatusString" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB55D0)) { Name = "WarshipGbraakonStartTrigger" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB5558)) { Name = "OutpostTremonius" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB746C)) { Name = "FOBGolf" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB55B0)) { Name = "Tower" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB72BC)) { Name = "TravelToDigSite" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB5308)) { Name = "Spire" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB7344)) { Name = "EastAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB7354)) { Name = "NorthAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB7364)) { Name = "WestAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB7384)) { Name = "PelicanSpartanKillers" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB9370)) { Name = "SequenceNorthernBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB9378)) { Name = "SequenceSouthernBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB9380)) { Name = "SequenceEasternBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB9388)) { Name = "SequenceSouthwesternBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4155BC8, 0xB740C)) { Name = "SilentAuditorium" });
        break;

        case "v6.10021.16272.0":
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x4648ADC)) { Name = "LoadStatus" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x463ED04)) { Name = "LoadStatus2" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x46B6684)) { Name = "LoadSplashScreen" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x46B5341)) { Name = "DoNotFreeze" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x41D47B1)) { Name = "IsLoadingInCutscene" });
            vars.watchers.Add(new StringWatcher(new DeepPointer(modules.First().BaseAddress + 0x4931B60), 255) { Name = "StatusString" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB55D0)) { Name = "WarshipGbraakonStartTrigger" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB5558)) { Name = "OutpostTremonius" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB746C)) { Name = "FOBGolf" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB55B0)) { Name = "Tower" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB72BC)) { Name = "TravelToDigSite" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB5308)) { Name = "Spire" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB7344)) { Name = "EastAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB7354)) { Name = "NorthAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB7364)) { Name = "WestAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB7384)) { Name = "PelicanSpartanKillers" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB9370)) { Name = "SequenceNorthernBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB9378)) { Name = "SequenceSouthernBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB9380)) { Name = "SequenceEasternBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB9388)) { Name = "SequenceSouthwesternBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB740C)) { Name = "SilentAuditorium" });
        break;

        case "v6.10021.18539.0":  // Season 2
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x453C1EC)) { Name = "LoadStatus" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4531C54)) { Name = "LoadStatus2" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x45B88A4)) { Name = "LoadSplashScreen" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x45B7559)) { Name = "DoNotFreeze" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x40D9E90)) { Name = "IsLoadingInCutscene" });
            vars.watchers.Add(new StringWatcher(new DeepPointer(modules.First().BaseAddress + 0x487EE00), 255) { Name = "StatusString" });
            // Needs good offsets for plot bools
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB55D0)) { Name = "WarshipGbraakonStartTrigger" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB5558)) { Name = "OutpostTremonius" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB746C)) { Name = "FOBGolf" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB55B0)) { Name = "Tower" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB72BC)) { Name = "TravelToDigSite" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB5308)) { Name = "Spire" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB7344)) { Name = "EastAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB7354)) { Name = "NorthAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB7364)) { Name = "WestAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB7384)) { Name = "PelicanSpartanKillers" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB9370)) { Name = "SequenceNorthernBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB9378)) { Name = "SequenceSouthernBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB9380)) { Name = "SequenceEasternBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB9388)) { Name = "SequenceSouthwesternBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x415AC88, 0xB740C)) { Name = "SilentAuditorium" });
        break;

        case "v6.10022.10499.0":
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x49012FC)) { Name = "LoadStatus" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x48F6D64)) { Name = "LoadStatus2" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4971F94)) { Name = "LoadSplashScreen" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x4970C49)) { Name = "DoNotFreeze" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x44E5E50)) { Name = "IsLoadingInCutscene" });
            vars.watchers.Add(new StringWatcher(new DeepPointer(modules.First().BaseAddress + 0x4C75320), 255) { Name = "StatusString" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xB92C4)) { Name = "WarshipGbraakonStartTrigger" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xB924C)) { Name = "OutpostTremonius" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xBB160)) { Name = "FOBGolf" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xB92A4)) { Name = "Tower" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xBAFB0)) { Name = "TravelToDigSite" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xB8FFC)) { Name = "Spire" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xBB038)) { Name = "EastAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xBB048)) { Name = "NorthAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xBB058)) { Name = "WestAAGun" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xBB078)) { Name = "PelicanSpartanKillers" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xBD064)) { Name = "SequenceNorthernBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xBD06C)) { Name = "SequenceSouthernBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xBD074)) { Name = "SequenceEasternBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xBD07C)) { Name = "SequenceSouthwesternBeacon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x446EDE0, 0xBB100)) { Name = "SilentAuditorium" });
        break;

        default:
            if (true)
            {     
                MessageBox.Show("This game version is not currently supported by the autosplitter.\n\n" +
                                "Load time removal and autosplitting functionality will be disabled.",
                                "LiveSplit - Halo Infinite", MessageBoxButtons.OK, MessageBoxIcon.Information);
                vars.IsAutosplitterEnabled = false;
            }
        break;

        case "debug":		
            // This is used only for debug purposes for finding new offsets in recent patches
            if (game.StartTime > DateTime.Now - TimeSpan.FromSeconds(5d)) throw new Exception("Game launched less than 5 seconds ago. Retrying...");
            vars.DebugPrint("  => Sigscanning - Finding base addresses and offsets...");

            IntPtr ptr;
            SignatureScanner scanner;
            var FoundVars = new Dictionary<string, bool>();

            foreach (var page in memory.MemoryPages(true).Where(m => (long)m.BaseAddress >= (long)modules.First().BaseAddress))
            {
                scanner = new SignatureScanner(memory, page.BaseAddress, (int)page.RegionSize);

                // Game Version
                if (!FoundVars.ContainsKey("GameVersion")) FoundVars.Add("GameVersion", false);
                if (!FoundVars["GameVersion"])
                {
                    ptr = scanner.Scan(new SigScanTarget(9, "00 00 62 75 69 6C 64 3A 20"));
                    if (ptr != IntPtr.Zero)
                    {
                        version = "v" + game.ReadString(ptr, 15);
                        vars.DebugPrint("   => Game version identified: " + version );
                        FoundVars["GameVersion"] = true;
                    }
                }

                // LoadStatus
                if (!FoundVars.ContainsKey("LoadStatus")) FoundVars.Add("LoadStatus", false);
                if (!FoundVars["LoadStatus"])
                {
                    ptr = scanner.Scan(new SigScanTarget(3, "0F BF 05 ???????? 3B C3")
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
                    if (ptr != IntPtr.Zero)
                    {
                        vars.DebugPrint("   => Offset found for LoadStatus at: 0x" + ((long)ptr - (long)modules.First().BaseAddress).ToString("X") );
                        FoundVars["LoadStatus"] = true;
                    }
                }

                // LoadStatus2
                if (!FoundVars.ContainsKey("LoadStatus2")) FoundVars.Add("LoadStatus2", false);
                if (!FoundVars["LoadStatus2"])
                {
                    ptr = scanner.Scan(new SigScanTarget(6, "89 44 24 74 8B 05")
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
                    if (ptr != IntPtr.Zero)
                    {
                        vars.DebugPrint("   => Offset found for LoadStatus2 at: 0x" + ((long)ptr - (long)modules.First().BaseAddress).ToString("X") );
                        FoundVars["LoadStatus2"] = true;
                    }
                }

                // LoadSplashScreen
                if (!FoundVars.ContainsKey("LoadSplashScreen")) FoundVars.Add("LoadSplashScreen", false);
                if (!FoundVars["LoadSplashScreen"])
                {
                    ptr = scanner.Scan(new SigScanTarget(4, "32 DB 83 3D")
                        { OnFound = (p, s, addr) => addr + 0x5 + p.ReadValue<int>(addr) });
                    if (ptr != IntPtr.Zero)
                    {
                        vars.DebugPrint("   => Offset found for LoadSplashScreen at: 0x" + ((long)ptr - (long)modules.First().BaseAddress).ToString("X") );
                        FoundVars["LoadSplashScreen"] = true;
                    }
                }

                // DoNotFreeze
                if (!FoundVars.ContainsKey("DoNotFreeze")) FoundVars.Add("DoNotFreeze", false);
                if (!FoundVars["DoNotFreeze"])
                {
                    ptr = scanner.Scan(new SigScanTarget(4, "75 0E 8A 05")
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
                    if (ptr != IntPtr.Zero)
                    {
                        vars.DebugPrint("   => Offset found for DoNotFreeze at: 0x" + ((long)ptr - (long)modules.First().BaseAddress).ToString("X") );
                        FoundVars["DoNotFreeze"] = true;
                    }
                }

                // StatusString
                if (!FoundVars.ContainsKey("StatusString")) FoundVars.Add("StatusString", false);
                if (!FoundVars["StatusString"])
                {
                    ptr = scanner.Scan(new SigScanTarget(9, "00 00 00 00 00 00 00 00 00 6C 6F 61"));
                    if (ptr != IntPtr.Zero)
                    {
                        vars.DebugPrint("   => Offset found for StatusString at: 0x" + ((long)ptr - (long)modules.First().BaseAddress).ToString("X") );
                        FoundVars["StatusString"] = true;
                    }
                }

                // IsLoadingInCutscene
                if (!FoundVars.ContainsKey("IsLoadingInCutscene")) FoundVars.Add("IsLoadingInCutscene", false);
                if (!FoundVars["IsLoadingInCutscene"])
                {
                    //ptr = scanner.Scan(new SigScanTarget(2, "C6 05 ???????? ?? 75 08")
                    //    { OnFound = (p, s, addr) => addr + 0x5 + p.ReadValue<int>(addr) });
                    ptr = scanner.Scan(new SigScanTarget(2, "88 0D ???????? 75 0A")
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
                    if (ptr != IntPtr.Zero)
                    {
                        vars.DebugPrint("   => Offset found for IsLoadingInCutscene at: 0x" + ((long)ptr - (long)modules.First().BaseAddress).ToString("X") );
                        FoundVars["IsLoadingInCutscene"] = true; 
                    }
                }

                // If the script successfully found all the addresses, there's no need to continue the loop, so break it
                if (FoundVars.All(m => m.Value)) break;
            }

            if (FoundVars.Any(m => !m.Value))
            {
                foreach (var entry in FoundVars) { if (!entry.Value) vars.DebugPrint("   => WARNING: Failed to find offset for " + entry.Key + "!"); }
                // If sigscanning fails, then disable the autosplitter and return.
                // At this point, the only way to re-enable the autosplitter is to either relaunch LiveSplit, reopen the ASL script or re-launch the game.
                // throw new Exception();
                vars.DebugPrint("  => Some addresses were not found. Disabling autosplitting functionality...");
        
                MessageBox.Show("This game version is not currently supported by the autosplitter.\n\n" +
                                "Load time removal and autosplitting functionality will be disabled.",
                                "LiveSplit - Halo Infinite", MessageBoxButtons.OK, MessageBoxIcon.Information);
                vars.IsAutosplitterEnabled = false;
                return;
            }
            vars.DebugPrint("  => All addresses found. No Errors.");
        break;
    }

    vars.DebugPrint("  => Init completed.");
}

update
{
    // If we explicitly disabled the autosplitter, return false
    if (!vars.IsAutosplitterEnabled) return false;

    // Update the watchers
    vars.watchers.UpdateAll(game);

    // Update our custom state variables
    vars.Map.Old = vars.Map.Current; vars.Map.Current = vars.GetCurrentMap();
    vars.IsLoading.Old = vars.IsLoading.Current; vars.IsLoading.Current = vars.GetLoadState();

    // If the timer isn't running (eg. a run reset), reset the splits dictionary
    if (timer.CurrentPhase == TimerPhase.NotRunning && ((Dictionary<string, bool>)(vars.AlreadyTriggeredSplits)).Any(x => x.Value))
    {
        foreach (var s in new List<string>(vars.AlreadyTriggeredSplits.Keys))
            vars.AlreadyTriggeredSplits[s] = false;
    }
}

isLoading
{
    return vars.IsLoading.Current || vars.watchers["IsLoadingInCutscene"].Current;
}

split
{
    foreach (var entry in vars.SplitBools)
    {
        if (entry.Value())
        {
            vars.AlreadyTriggeredSplits[entry.Key] = true;
            if (settings[entry.Key])
            {
                vars.DebugPrint("  => Split triggered. Split id: " + entry.Key);
                return true;
            } 
        }
    }
}

start
{
    return settings["startOnWarship"]
            ? vars.Map.Current == vars.Maps.WarshipGbraakon && vars.watchers["WarshipGbraakonStartTrigger"].Current == 3 && !vars.IsLoading.Current
            : vars.Map.Current == vars.Maps.WarshipGbraakon && vars.IsLoading.Old && !vars.IsLoading.Current && vars.watchers["WarshipGbraakonStartTrigger"].Current == 0;
}

exit
{
    timer.IsGameTimePaused = true;
}
