// Autosplitter and Load Time remover by Jujstme
// Made thanks to the contributions from the HaloRuns community.
// Thanks to all guys who helped in writing this
// Coding: Jujstme
// contacts: just.tribe@gmail.com
// Version: 1.0.4 (Jan 1st, 2022)

state("HaloInfinite") {}

startup
{
    string[,] Settings =
    {
        { null,             "startOnWarship",         "Start the timer when gaining control on Warship Gbraakon", null, "false" },
        { null,             "pauseAtCutscenes",       "Pause the game timer during cutscenes",       null,    "false" },
        { null,             "pauseAtMainMenu",        "Pause the game timer in the main menu",       null,    "false" },

        { null,             "autosplitting",          "Auto Splitting",               null, "true" },

        { "autosplitting",  "warshipGbraakon",        "Warship Gbraakon",             "Will trigger a split after completing the mission \"Warship Gbraakon\".",                             "true" },
        { "autosplitting",  "foundation",             "Foundation",                   "Will trigger a split after completing the mission \"Foundation\".",                                   "true" },
        { "autosplitting",  "outpostTremonius",       "Outpost Tremonius",            "Will trigger a split after taking control of Outpost Tremonius.",                                     "true" },
        { "autosplitting",  "FOBGolf",                "FOB Golf",                     "Will trigger a split after taking control of FOB Golf.",                                              "true" },
        { "autosplitting",  "tower",                  "Tower",                        "Will trigger a split after freeing Spartan Griffin upon completion of the mission \"The Tower\".",    "true" },

        { "autosplitting",  "excavationSite",         "Excavation Site",              null, "true" },
        { "excavationSite", "reachTheDigSite",        "Reach the Excavation Site",    "Will trigger a split after the first cutscene in the excavation site.",                               "true" },
        { "excavationSite", "bassus",                 "Bassus",                       "Will trigger a split upon entering the Conservatory, after Bassus' defeat.",                          "true" },

        { "autosplitting",  "conservatory",           "Conservatory",                 "Will trigger a split after completing the mission \"Conservatory\".",                                 "true" },

        { "autosplitting",  "spire",                  "Spire",                        null, "true"},
        { "spire",          "spireApproach",          "Approach the command spire",   "Will trigger a split upon entering the first spire.",                                                 "true" },
        { "spire",          "adjutantResolution",     "Adjutant Resolution",          "Will trigger a split after defeting Adjuvant resolution and dectivating the spire.",                  "true" },

        { "autosplitting",  "pelicanDown",            "Pelican Down",                 null, "true" },
        { "pelicanDown",    "EastAAGun",              "East AA Gun",                  "Will trigger a split upon destruction of the East AA Gun.",                                           "true" },
        { "pelicanDown",    "NorthAAGun",             "North AA Gun",                 "Will trigger a split upon destruction of the North AA Gun.",                                          "true" },
        { "pelicanDown",    "WestAAGun",              "West AA Gun",                  "Will trigger a split upon destruction of the West AA Gun.",                                           "true" },
        { "pelicanDown",    "spartanKillers",         "Hyperius and Tovarus",         "Will trigger a split when finding Echo-216 after defeting the Spartan killers Hyperius and Tovarus.", "true" },

        { "autosplitting",  "sequence",               "The Sequence",                 null, "true" },
        { "sequence",       "easternBeacon",          "Eastern Beacon",               "Will trigger a split after activating the Eastern Beacon.",                                           "true" },
        { "sequence",       "southernBeacon",         "Southern Beacon",              "Will trigger a split after activating the Southern Beacon.",                                          "true" },
        { "sequence",       "northernBeacon",         "Northern Beacon",              "Will trigger a split after activating the Northern Beacon.",                                          "true" },
        { "sequence",       "southwesternBeacon",     "Southwestern Beacon",          "Will trigger a split after activating the Southwestern Beacon.",                                      "true" },
        { "sequence",       "enterNexus",             "Enter the Nexus",              "Will trigger a split upon entering the Nexus.",                                                       "true" },

        { "autosplitting",  "nexus",                  "Nexus",                        "Will trigger a split upon completing the mission \"Nexus\".",                                         "true" },

        { "autosplitting",  "commandSpire",           "Command Spire",                null, "true" },
        { "commandSpire",   "reachTheTop",            "Reach the Top",                "Will trigger a split upon reaching the top of the Command Spire.",                                    "true" },
        { "commandSpire",   "deactivateCommandSpire", "Deactivate the Command Spire", "Will trigger a split after deactivation of the Command Spire.",                                       "true" },

        { "autosplitting",  "repository",             "Repository",                   "Will trigger a split upon completion of the mission \"Repository\".",                                 "true" },
        { "autosplitting",  "road",                   "Road",                         "Will trigger a split upon entering the House of Reckoning.",                                          "true" },
        { "autosplitting",  "houseOfReckoning",       "House of Reckoning",           "Will trigger a split upon completion of the House of Reckoning.",                                     "true" },
        { "autosplitting",  "silentAuditorium",       "Silent Auditorium",            "Will trigger a split upon defeat of the Harbringer.",                                                 "true" }
    }; 

    for (int i = 0; i < Settings.GetLength(0); i++)
    {
        settings.Add(Settings[i, 1], bool.Parse(Settings[i, 4]), Settings[i, 2], Settings[i, 0]);
        if (!string.IsNullOrEmpty(Settings[i, 3])) settings.SetToolTip(Settings[i, 1], Settings[i, 3]);
    }

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

    vars.SplitBools = new Dictionary<string, bool>();
    vars.AlreadyTriggeredSplits = new Dictionary<string, bool>();
    for (int i = 0; i < Settings.GetLength(0); i++)
    {
        if (string.IsNullOrEmpty(Settings[i, 3]) || !Settings[i, 3].Contains("split")) continue;
        vars.SplitBools.Add(Settings[i, 1], false);
        vars.AlreadyTriggeredSplits.Add(Settings[i, 1], false);
    }
}

init
{
    // Game versions
    if (!new Dictionary<int, string>{
        { 0x1263000, "v6.10020.17952.0" },
        { 0x133F000, "v6.10020.19048.0" }
    }.TryGetValue(modules.Where(x => x.ModuleName == "Arbiter.dll").FirstOrDefault().ModuleMemorySize, out version)) version = "Unknown game version";

    // Initialize some basic variables I will use later on
    IntPtr baseAddress = modules.First().BaseAddress;
    vars.IsAutosplitterEnabled = true;

    // Offset dictionaries
    var LoadStatusVars = new Dictionary<string, Tuple<int, string>>();
    int PlotBoolsOffset = new int();
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

    switch (version)
    {
        case "v6.10020.19048.0":
            LoadStatusVars = new Dictionary<string, Tuple<int, string>>{
                { "LoadStatus",           new Tuple<int, string>(0x4FFDD04, "byte") },
                { "LoadStatusPercentage", new Tuple<int, string>(0x4FFDD08, "byte") },
                { "StatusString",         new Tuple<int, string>(0x4CA11B0, "string") },
                { "LoadScreen",           new Tuple<int, string>(0x47E73E0, "bool") },
                { "LoadingIcon",          new Tuple<int, string>(0x522A6D0, "bool") },
                { "IsCutScene",           new Tuple<int, string>(0x4845278, "bool") }
            };
            PlotBoolsOffset = 0x482C908;
        break;

        default:
            int ptr;
            SignatureScanner scanner;
            var FoundVars = new Dictionary<string, bool>{
                { "LoadStatusPercentage", false },
                { "StatusString",         false },
                { "LoadScreen",           false },
                { "IsCutScene",           false },
                { "CampaignData",         false }
            };

            Thread.Sleep(1000);

            while (true)
            {
                foreach (var page in game.MemoryPages(true).Where(m => (long)m.BaseAddress >= (long)game.MainModuleWow64Safe().BaseAddress))
                {
                    scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

                    if (!FoundVars["LoadStatusPercentage"])
                    {
                        ptr = (int)scanner.Scan(new SigScanTarget(2, "89 05 ???????? 48 81 C4 ???????? 41 5F") { OnFound = (p, s, addr) => (IntPtr)((addr + 0x4 + p.ReadValue<int>(addr)).ToInt64() - baseAddress.ToInt64()) });
                        if (ptr != 0)
                        {
                            LoadStatusVars["LoadStatusPercentage"] = new Tuple<int, string>(ptr, "byte");
                            LoadStatusVars["LoadStatus"]           = new Tuple<int, string>(ptr - 4, "byte"); // If LoadStatus breaks in future game updates, we can scan for it using this alternative sigscan: 89 45 94 8B 05 ???????? 89 45 98
                            LoadStatusVars["LoadingIcon"]          = new Tuple<int, string>(ptr + 0x22C9C8, "bool"); // Will probably break on next game update
                            FoundVars["LoadStatusPercentage"] = true;
                        }
                    }

                    if (!FoundVars["StatusString"])
                    {
                        ptr = (int)scanner.Scan(new SigScanTarget(12, "00 00 00 00 00 00 00 00 00 00 00 00 6C 6F 61 64") { OnFound = (p, s, addr) => (IntPtr)(addr.ToInt64() - baseAddress.ToInt64()) });
                        if (ptr != 0)
                        {
                            LoadStatusVars["StatusString"] = new Tuple<int, string>(ptr, "string");
                            FoundVars["StatusString"] = true;
                        }
                    }

                    if (!FoundVars["LoadScreen"])
                    {
                        ptr = (int)scanner.Scan(new SigScanTarget(2, "80 3D ???????? 00 74 17 48 8D 0D ???????? E8 ???????? 84 C0") { OnFound = (p, s, addr) => (IntPtr)((addr + 0x5 + p.ReadValue<int>(addr)).ToInt64() - baseAddress.ToInt64()) });
                        if (ptr != 0)
                        {
                            LoadStatusVars["LoadScreen"] = new Tuple<int, string>(ptr, "bool");
                            FoundVars["LoadScreen"] = true;
                        }
                    }

                    if (!FoundVars["IsCutScene"])
                    {
                        ptr = (int)scanner.Scan(new SigScanTarget(3, "48 8D 05 ???????? 48 03 C8 39 99") { OnFound = (p, s, addr) => (IntPtr)((addr + 0x4 + p.ReadValue<int>(addr)).ToInt64() - baseAddress.ToInt64()) });
                        if (ptr != 0)
                        {
                            LoadStatusVars["IsCutScene"] = new Tuple<int, string>(ptr + 0x278, "bool");
                            FoundVars["IsCutScene"] = true;
                        }
                    }

                    if (!FoundVars["CampaignData"])
                    {
                        ptr = (int)scanner.Scan(new SigScanTarget(3, "4C 8D 35 ???????? 48 8D 0D ???????? 66") { OnFound = (p, s, addr) => (IntPtr)((addr + 0x4 + p.ReadValue<int>(addr)).ToInt64() - baseAddress.ToInt64()) });
                        if (ptr != 0)
                        {
                            PlotBoolsOffset = ptr;
                            FoundVars["CampaignData"] = true;
                        }
                    }

                    if (FoundVars["LoadStatusPercentage"] && FoundVars["StatusString"] && FoundVars["LoadScreen"] && FoundVars["CampaignData"] && FoundVars["IsCutScene"]) break;
                }

                if (!FoundVars["LoadStatusPercentage"] || !FoundVars["StatusString"] || !FoundVars["LoadScreen"] || !FoundVars["CampaignData"] || !FoundVars["IsCutScene"])
                {
                    if (MessageBox.Show("You are running a currently unsupported version of the game and LiveSplit failed to automatically find the memory addresses needed for the autosplitter to work.\n\n" +
                                        "If you just booted up the game, you can try running the script again to retrieve the needed memory addresses.\n\n" +
                                        "Do you want to retry?",
                                        "LiveSplit - Halo Infinite", MessageBoxButtons.YesNo, MessageBoxIcon.Information) == DialogResult.Yes) continue;

                    MessageBox.Show("This game version is not currently supported by the autosplitter.\n\n" +
                                    "Load time removal and autosplitting functionality will be disabled.",
                                    "LiveSplit - Halo Infinite", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    vars.IsAutosplitterEnabled = false;
                    return;
                }
                break;
            }
        break;
    }

    vars.watchers = new MemoryWatcherList();
    foreach (KeyValuePair<string, Tuple<int, string>> entry in LoadStatusVars)
    {
        switch (entry.Value.Item2)
        {
            case "byte": vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(baseAddress + entry.Value.Item1)) { Name = entry.Key }); break;
            case "string": vars.watchers.Add(new StringWatcher(new DeepPointer(baseAddress + entry.Value.Item1), 255) { Name = entry.Key }); break;
            case "bool": vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(baseAddress + entry.Value.Item1)) { Name = entry.Key }); break;
        }
    }
    foreach (KeyValuePair<string, int> entry in PlotBools) vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(baseAddress + PlotBoolsOffset, entry.Value)) { Name = entry.Key });

    // Explicitly define current.Map here to avoid throwing an Exception during the first update
    current.Map = string.Empty;
}

update
{
    // If we explicitly disabled the autosplitter, return false
    if (!vars.IsAutosplitterEnabled) return false;

    // Update the watchers
    vars.watchers.UpdateAll(game);

    // Explicitly define a couple of variables for easier access
    current.IsLoading = vars.watchers["StatusString"].Current.Substring(0, vars.watchers["StatusString"].Current.LastIndexOf(" ")) == "loading" ||
            vars.watchers["LoadStatus"].Current == 3 || vars.watchers["LoadingIcon"].Current || vars.watchers["LoadScreen"].Current ||
            (vars.watchers["LoadStatusPercentage"].Current != 0 && vars.watchers["LoadStatusPercentage"].Current != 100) ||
            (vars.watchers["LoadStatusPercentage"].Current == 100 && vars.watchers["LoadStatus"].Current < 4);
    
    current.Map = vars.watchers["StatusString"].Current.Substring(vars.watchers["StatusString"].Current.LastIndexOf("\\") + 1);

    // If the timer isn't running (eg. a run reset), reset the splits dictionary
    if (timer.CurrentPhase == TimerPhase.NotRunning) { foreach (var s in new List<string>(vars.AlreadyTriggeredSplits.Keys)) vars.AlreadyTriggeredSplits[s] = false; }
}

isLoading
{
    return current.IsLoading || (settings["pauseAtMainMenu"] && current.Map == vars.Maps.MainMenu) || (settings["pauseAtCutscenes"] && vars.watchers["IsCutScene"].Current);
}

split
{
    vars.SplitBools["warshipGbraakon"] = !vars.AlreadyTriggeredSplits["warshipGbraakon"] && old.Map == vars.Maps.WarshipGbraakon && current.Map == vars.Maps.Foundation;
    vars.SplitBools["foundation"] = !vars.AlreadyTriggeredSplits["foundation"] && old.Map == vars.Maps.Foundation && current.Map == vars.Maps.ZetaHalo;
    vars.SplitBools["outpostTremonius"] = !vars.AlreadyTriggeredSplits["outpostTremonius"] && current.Map == vars.Maps.ZetaHalo && vars.watchers["OutpostTremonius"].Changed && vars.watchers["OutpostTremonius"].Current == 6;
    vars.SplitBools["FOBGolf"] = !vars.AlreadyTriggeredSplits["FOBGolf"] && current.Map == vars.Maps.ZetaHalo && vars.watchers["FOBGolf"].Changed && vars.watchers["FOBGolf"].Current == 10;
    vars.SplitBools["tower"] = !vars.AlreadyTriggeredSplits["tower"] && current.Map == vars.Maps.ZetaHalo && vars.watchers["Tower"].Changed && vars.watchers["Tower"].Current == 10;
    vars.SplitBools["reachTheDigSite"] = !vars.AlreadyTriggeredSplits["reachTheDigSite"] && current.Map == vars.Maps.ZetaHalo && vars.watchers["TravelToDigSite"].Changed && vars.watchers["TravelToDigSite"].Current == 10;
    vars.SplitBools["bassus"] = !vars.AlreadyTriggeredSplits["bassus"] && old.Map == vars.Maps.ZetaHalo && current.Map == vars.Maps.Conservatory;
    vars.SplitBools["conservatory"] = !vars.AlreadyTriggeredSplits["conservatory"] && old.Map == vars.Maps.Conservatory && current.Map == vars.Maps.ZetaHalo;
    vars.SplitBools["spireApproach"] = !vars.AlreadyTriggeredSplits["spireApproach"] && old.Map == vars.Maps.ZetaHalo && current.Map == vars.Maps.Spire01;
    vars.SplitBools["adjutantResolution"] = !vars.AlreadyTriggeredSplits["adjutantResolution"] && current.Map == vars.Maps.ZetaHalo && vars.watchers["Spire"].Changed && vars.watchers["Spire"].Current == 10;
    vars.SplitBools["EastAAGun"] = !vars.AlreadyTriggeredSplits["EastAAGun"] && current.Map == vars.Maps.ZetaHalo && vars.watchers["PelicanSpartanKillers"].Current != 10 && vars.watchers["EastAAGun"].Changed && vars.watchers["EastAAGun"].Current == 10;
    vars.SplitBools["NorthAAGun"] = !vars.AlreadyTriggeredSplits["NorthAAGun"] && current.Map == vars.Maps.ZetaHalo && vars.watchers["PelicanSpartanKillers"].Current != 10 && vars.watchers["NorthAAGun"].Changed && vars.watchers["NorthAAGun"].Current == 10;
    vars.SplitBools["WestAAGun"] = !vars.AlreadyTriggeredSplits["WestAAGun"] && current.Map == vars.Maps.ZetaHalo && vars.watchers["PelicanSpartanKillers"].Current != 10 && vars.watchers["WestAAGun"].Changed && vars.watchers["WestAAGun"].Current == 10;
    vars.SplitBools["spartanKillers"] = !vars.AlreadyTriggeredSplits["spartanKillers"] && current.Map == vars.Maps.ZetaHalo && vars.watchers["EastAAGun"].Old == 10 && vars.watchers["NorthAAGun"].Old == 10 && vars.watchers["WestAAGun"].Old == 10 && vars.watchers["PelicanSpartanKillers"].Changed && vars.watchers["PelicanSpartanKillers"].Current == 10;
    vars.SplitBools["easternBeacon"] = !vars.AlreadyTriggeredSplits["easternBeacon"] && current.Map == vars.Maps.ZetaHalo && vars.watchers["SequenceEasternBeacon"].Changed && vars.watchers["SequenceEasternBeacon"].Current == 10;
    vars.SplitBools["southernBeacon"] = !vars.AlreadyTriggeredSplits["southernBeacon"] && current.Map == vars.Maps.ZetaHalo && vars.watchers["SequenceSouthernBeacon"].Changed && vars.watchers["SequenceSouthernBeacon"].Current == 10;
    vars.SplitBools["northernBeacon"] = !vars.AlreadyTriggeredSplits["northernBeacon"] && current.Map == vars.Maps.ZetaHalo && vars.watchers["SequenceNorthernBeacon"].Changed && vars.watchers["SequenceNorthernBeacon"].Current == 10;
    vars.SplitBools["southwesternBeacon"] = !vars.AlreadyTriggeredSplits["southwesternBeacon"] && current.Map == vars.Maps.ZetaHalo && vars.watchers["SequenceSouthwesternBeacon"].Changed && vars.watchers["SequenceSouthwesternBeacon"].Current == 10;
    vars.SplitBools["enterNexus"] = !vars.AlreadyTriggeredSplits["enterNexus"] && old.Map == vars.Maps.ZetaHalo && current.Map == vars.Maps.Nexus;
    vars.SplitBools["nexus"] = !vars.AlreadyTriggeredSplits["nexus"] && old.Map == vars.Maps.Nexus && current.Map == vars.Maps.Spire02;
    vars.SplitBools["reachTheTop"] = !vars.AlreadyTriggeredSplits["reachTheTop"] && old.Map == vars.Maps.Spire02 && current.Map == vars.Maps.ZetaHalo;
    vars.SplitBools["deactivateCommandSpire"] = !vars.AlreadyTriggeredSplits["deactivateCommandSpire"] && old.Map == vars.Maps.ZetaHalo && current.Map == vars.Maps.Repository;
    vars.SplitBools["repository"] = !vars.AlreadyTriggeredSplits["repository"] && old.Map == vars.Maps.Repository && current.Map == vars.Maps.ZetaHalo;
    vars.SplitBools["road"] = !vars.AlreadyTriggeredSplits["road"] && old.Map == vars.Maps.ZetaHalo && current.Map == vars.Maps.HouseOfReckoning;
    vars.SplitBools["houseOfReckoning"] = !vars.AlreadyTriggeredSplits["houseOfReckoning"] && old.Map == vars.Maps.HouseOfReckoning && current.Map == vars.Maps.SilentAuditorium;
    vars.SplitBools["silentAuditorium"] = !vars.AlreadyTriggeredSplits["silentAuditorium"] && current.Map == vars.Maps.SilentAuditorium && vars.watchers["SilentAuditorium"].Changed && vars.watchers["SilentAuditorium"].Current == 10;

    foreach (KeyValuePair<string, bool> entry in vars.SplitBools)
    {
        if (entry.Value)
        {
            vars.AlreadyTriggeredSplits[entry.Key] = true;
            if (settings[entry.Key]) return true;
        }
    }
}

start
{
    //return current.Map == vars.Maps.WarshipGbraakon && old.IsLoading && !current.IsLoading && vars.watchers["WarshipGbraakonStartTrigger"].Current == 0;
    return settings["startOnWarship"] ? current.Map == vars.Maps.WarshipGbraakon && vars.watchers["WarshipGbraakonStartTrigger"].Current == 3 && !current.IsLoading
            : current.Map == vars.Maps.WarshipGbraakon && old.IsLoading && !current.IsLoading && vars.watchers["WarshipGbraakonStartTrigger"].Current == 0;
}

exit
{
    timer.IsGameTimePaused = true;
}
