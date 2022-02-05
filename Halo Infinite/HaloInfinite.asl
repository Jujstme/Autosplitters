// Autosplitter and Load Time remover by Jujstme
// Made thanks to the contributions from the HaloRuns community.
// Thanks to all guys who helped in writing this
// Coding: Jujstme
// contacts: just.tribe@gmail.com
// Version: 1.0.8.4 (Feb 5th, 2022)

/* Changelog
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
}

init
{
    // Identify the game version. This is used later, so if a game version is known, we can avoid using sigscanning.
    if (!new Dictionary<int, string>{
        { 0x1263000, "v6.10020.17952.0" },
        { 0x133F000, "v6.10020.19048.0" },
        { 0x1262000, "v6.10021.10921.0" },
        { 0x125D000, "v6.10021.11755.0" }
    }.TryGetValue(modules.Where(x => x.ModuleName == "Arbiter.dll").FirstOrDefault().ModuleMemorySize, out version)) version = "Unknown game version";

    // Basic variable, pretty self-explanatory.
    // We will change it to false if we need to disable the autosplitter for whatever reason.
    vars.IsAutosplitterEnabled = true;

    // Offset dictionaries
    var LoadStatusVars = new Dictionary<string, Tuple<IntPtr, string>>();
    IntPtr PlotBoolsOffset = IntPtr.Zero;

    // These offsets should stay constant regardless of the game version... I hope.
    var PlotBools = new Dictionary<string, int>{
        { "WarshipGbraakonStartTrigger", 0xB55D0 },
        { "OutpostTremonius",            0xB5558 },
        { "FOBGolf",                     0xB746C },
        { "Tower",                       0xB55B0 },
        { "TravelToDigSite",             0xB72BC },
        { "Spire",                       0xB5308 },
        { "EastAAGun",                   0xB7344 },
        { "NorthAAGun",                  0xB7354 },
        { "WestAAGun",                   0xB7364 },
        { "PelicanSpartanKillers",       0xB7384 },
        { "SequenceNorthernBeacon",      0xB9370 },
        { "SequenceSouthernBeacon",      0xB9378 },
        { "SequenceEasternBeacon",       0xB9380 },
        { "SequenceSouthwesternBeacon",  0xB9388 },
        { "SilentAuditorium",            0xB740C }
    };

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
            PlotBoolsOffset = modules.First().BaseAddress + 0x3E485C8;
            LoadStatusVars = new Dictionary<string, Tuple<IntPtr, string>>{
                { "LoadStatus",           new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x433037C, "bool") },
                { "LoadStatus2",          new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x43265A4, "byte") },
                { "LoadSplashScreen",     new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x43A9384, "byte") },
                { "DoNotFreeze",          new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x43A8049, "bool") },
                { "StatusString",         new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x462F2C0, "string") },
                { "IsLoadingInCutscene",  new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x3EC2071, "bool") }
            };
        break;

        case "v6.10020.19048.0":
            PlotBoolsOffset = modules.First().BaseAddress + 0x482C908;
            LoadStatusVars = new Dictionary<string, Tuple<IntPtr, string>>{
                { "LoadStatus",           new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x5007ADC, "bool") },
                { "LoadStatus2",          new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x4FFDD04, "byte") },
                { "LoadSplashScreen",     new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x50A1B0C, "byte") },
                { "DoNotFreeze",          new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x509E5BC, "bool") },
                { "StatusString",         new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x4CA11B0, "string") },
                { "IsLoadingInCutscene",  new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x48A6AB7, "bool") }
            };
        break;

        case "v6.10021.10921.0":
        case "v6.10021.11755.0":
            PlotBoolsOffset = modules.First().BaseAddress + 0x3E49588;
            LoadStatusVars = new Dictionary<string, Tuple<IntPtr, string>>{
                { "LoadStatus",           new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x433133C, "bool") },
                { "LoadStatus2",          new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x4327564, "byte") },
                { "LoadSplashScreen",     new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x43AA344, "byte") },
                { "DoNotFreeze",          new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x43A9009, "bool") },
                { "StatusString",         new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x4630240, "string") },
                { "IsLoadingInCutscene",  new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x3EC3031, "bool") }
            };
        break;

        default:
            // If we are dealing with a new or unsupported game version, we have no other choice than trying to use sigscanning.
            // This portion of the code will then attempt to use sigscanning to recover the memory offsets.

            // If the game has been launched from less than 5 seconds, throw an exception and re-execute the script.
            // This is necessary to give the game enough time to decrypt some of the memory pages needed for sigscanning
            if (game.StartTime > DateTime.Now - TimeSpan.FromSeconds(5d)) throw new Exception("Game launched less than 5 seconds ago. Retrying...");

            IntPtr ptr;
            SignatureScanner scanner;
            var FoundVars = new Dictionary<string, bool>();

            foreach (var page in memory.MemoryPages(true).Where(m => (long)m.BaseAddress >= (long)modules.First().BaseAddress && (long)m.BaseAddress < (long)modules.First().BaseAddress + int.MaxValue))
            {
                scanner = new SignatureScanner(memory, page.BaseAddress, (int)page.RegionSize);

                // LoadStatus
                if (!FoundVars.ContainsKey("LoadStatus")) FoundVars.Add("LoadStatus", false);
                if (!FoundVars["LoadStatus"])
                {
                    ptr = scanner.Scan(new SigScanTarget(3,
                        "48 8B 05 ????????",        // mov rax,[HaloInfinite.exe+5007A50]  <---
                        "48 89 45 80")              // mov [rbp-80],rax
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) + 0x8C });
                    if (ptr != IntPtr.Zero)
                    {
                        LoadStatusVars["LoadStatus"] = new Tuple<IntPtr, string>(ptr, "bool");
                        FoundVars["LoadStatus"] = true;
                    }
                }

                // LoadStatus2
                if (!FoundVars.ContainsKey("LoadStatus2")) FoundVars.Add("LoadStatus2", false);
                if (!FoundVars["LoadStatus2"])
                {
                    ptr = scanner.Scan(new SigScanTarget(6,
                        "89 44 24 74",           // mov [rsp+74],eax
                        "8B 05 ????????")        // mov eax,[HaloInfinite.exe+4FFDD04]  <---
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
                    if (ptr != IntPtr.Zero)
                    {
                        LoadStatusVars["LoadStatus2"] = new Tuple<IntPtr, string>(ptr, "byte");
                        FoundVars["LoadStatus2"] = true;
                    }
                }

                // LoadSplashScreen
                if (!FoundVars.ContainsKey("LoadSplashScreen")) FoundVars.Add("LoadSplashScreen", false);
                if (!FoundVars["LoadSplashScreen"])
                {
                    ptr = scanner.Scan(new SigScanTarget(2,
                        "83 3D ???????? ??",  // cmp dword ptr [HaloInfinite.exe+43AA344],03  <---
                        "74 08",              // je HaloInfinite.exe+55B649
                        "8A C3")              // mov al,bl
                        { OnFound = (p, s, addr) => addr + 0x5 + p.ReadValue<int>(addr) });
                    if (ptr != IntPtr.Zero)
                    {
                        LoadStatusVars["LoadSplashScreen"] = new Tuple<IntPtr, string>(ptr, "byte");
                        FoundVars["LoadSplashScreen"] = true;
                    }
                }

                // DoNotFreeze
                if (!FoundVars.ContainsKey("DoNotFreeze")) FoundVars.Add("DoNotFreeze", false);
                if (!FoundVars["DoNotFreeze"])
                {
                    ptr = scanner.Scan(new SigScanTarget(2,
                        "8A 05 ????????",    // mov al,[HaloInfinite.exe+43A9009]  <---
                        "3C 01",             // cmp al,01
                        "74 09")             // je HaloInfinite.exe+823B37
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
                    if (ptr != IntPtr.Zero)
                    {
                        LoadStatusVars["DoNotFreeze"] = new Tuple<IntPtr, string>(ptr, "bool");
                        FoundVars["DoNotFreeze"] = true;
                    }
                }

                // StatusString
                if (!FoundVars.ContainsKey("StatusString")) FoundVars.Add("StatusString", false);
                if (!FoundVars["StatusString"])
                {
                    ptr = scanner.Scan(new SigScanTarget(5,
                        "33 FF",                 // xor edi,edi
                        "4C 8D 35 ????????",     // lea r14,[HaloInfinite.exe+4C9FDB0]  <---
                        "33 C0")                 // xor eax,eax
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) + 0x1400 });
                    if (ptr != IntPtr.Zero)
                    {
                        LoadStatusVars["StatusString"] = new Tuple<IntPtr, string>(ptr, "string");
                        FoundVars["StatusString"] = true;
                    }
                }

                // IsLoadingInCutscene
                if (!FoundVars.ContainsKey("IsLoadingInCutscene")) FoundVars.Add("IsLoadingInCutscene", false);
                if (!FoundVars["IsLoadingInCutscene"])
                {
                    ptr = scanner.Scan(new SigScanTarget(6,
                        "4D 8B C3",              // mov r8,r11
                        "48 8B 1D ????????")     // mov rbx,[HaloInfinite.exe+3EC3028]  <---
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) + 0x9 });
                    if (ptr != IntPtr.Zero)
                    {
                        LoadStatusVars["IsLoadingInCutscene"] = new Tuple<IntPtr, string>(ptr, "bool");
                        FoundVars["IsLoadingInCutscene"] = true; 
                    }
                }

                // PlotBoolsOffset
                if (!FoundVars.ContainsKey("CampaignData")) FoundVars.Add("CampaignData", false);
                if (!FoundVars["CampaignData"])
                {
                    ptr = scanner.Scan(new SigScanTarget(3,
                        "48 8D 05 ????????",     // lea rax,[HaloInfinite.exe+3E49588]  <---
                        "8B CA")                 // mov ecx,edx
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
                    if (ptr != IntPtr.Zero)
                    {
                        PlotBoolsOffset = ptr;
                        FoundVars["CampaignData"] = true;
                    }
                }

                // If the script successfully found all the addresses, there's no need to continue the loop, so break it
                if (FoundVars.All(m => m.Value)) break;
            }

            if (FoundVars.Any(m => !m.Value))
            {
                // If sigscanning fails, then disable the autosplitter and return.
                // At this point, the only way to re-enable the autosplitter is to either relaunch LiveSplit, reopen the ASL script or re-launch the game.
                MessageBox.Show("This game version is not currently supported by the autosplitter.\n\n" +
                                "Load time removal and autosplitting functionality will be disabled.",
                                "LiveSplit - Halo Infinite", MessageBoxButtons.OK, MessageBoxIcon.Information);
                vars.IsAutosplitterEnabled = false;
                return;
            }
        break;
    }

    // Finally, once we have all the needed offsets, define our watchers
    vars.watchers = new MemoryWatcherList();
    foreach (var entry in LoadStatusVars)
    {
        switch (entry.Value.Item2)
        {
            case "byte": vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(entry.Value.Item1)) { Name = entry.Key }); break;
            case "string": vars.watchers.Add(new StringWatcher(new DeepPointer(entry.Value.Item1), 255) { Name = entry.Key }); break;
            case "bool": vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(entry.Value.Item1)) { Name = entry.Key }); break;
        }
    }
    foreach (var entry in PlotBools)
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(PlotBoolsOffset, entry.Value)) { Name = entry.Key });
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
            if (settings[entry.Key]) return true;
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
