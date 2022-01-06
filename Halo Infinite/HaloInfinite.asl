// Autosplitter and Load Time remover by Jujstme
// Made thanks to the contributions from the HaloRuns community.
// Thanks to all guys who helped in writing this
// Coding: Jujstme
// contacts: just.tribe@gmail.com
// Version: 1.0.5.0 (Jan 5th, 2022)

state("HaloInfinite") {}

startup
{
    // Long list of settings we want to implement in the autosplitter.
    // Settings that have "split" in their tooltip will be considered for the autosplitting dictionary
    // Format:
    //   { parent, settingID, settingText, settingToolTip, settingParent, defaultState }
    string[,] Settings =
    {
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

    // Define two dictionaries we will use to manage autosplitting
    // SplitBools: a dictionary of booleans that will tell us if we met the conditions to split at a certain point during the run
    // AlreadyTriggeredSplits: pretty much self-explanatory, it records if we already triggered a certain splits, avoiding unwanted double splitting
    // For convenience the code will get the dictionary keys from every voice in the settings in which we used the word "split" in the tooltip. It's very ugly and hacky, but it works and I don't care.
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
    // Identify the game version. This is used later, so if a game version is known, we can avoid using sigscanning.
    if (!new Dictionary<int, string>{
        { 0x1263000, "v6.10020.17952.0" },
        { 0x133F000, "v6.10020.19048.0" }
    }.TryGetValue(modules.Where(x => x.ModuleName == "Arbiter.dll").FirstOrDefault().ModuleMemorySize, out version)) version = "Unknown game version";

    // Basic variable, pretty self-explanatory.
    // We will change it to false if we need to disable the autosplitter for whatever reason.
    vars.IsAutosplitterEnabled = true;

    // Offset dictionaries
    var LoadStatusVars = new Dictionary<string, Tuple<IntPtr, string>>();
    IntPtr PlotBoolsOffset = new IntPtr();

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
     *   - LoadStatus: it's a byte, but treated as a bool, it fluctuates between 0 and 3, but basically tells the system when we are loading a map in the main menu
     *   - LoadStatus2: byte value, goes from 0 to 4. When 0, we are idling in the menu. When 4, we are ingame
     *   - StatusString: string variable that is used by the autosplitter to determine the current map
     *   - LoadScreen: long value, it's non-zero when the main load screen is being displayed
     *   - LoadingIcon: bool value, tells us when the loading icon at the bottom left is being displayed. It allows to remove the load time at the door in Gbraakon
     *   - IsLoadingInCutscene: bool value, ugly hack used to remove time when the "loading" message is displayed during cutscenes
     */

    // Use a switch statement so, if a game version is recognized, the script will directly grab whatever offsets I manually inputted here.
    // Basically, we avoid using sigscanning, with all the associated headaches.
    switch (version)
    {
        case "v6.10020.19048.0":
            LoadStatusVars = new Dictionary<string, Tuple<IntPtr, string>>{
                { "LoadStatus",           new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x5007ADC, "bool") },
                { "LoadStatus2",          new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x4FFDD04, "byte") },
                { "StatusString",         new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x4CA11B0, "string") },
                { "LoadScreen",           new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x50A1A28, "long") },
                { "LoadingIcon",          new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x522A6D0, "bool") },
                { "IsLoadingInCutscene",  new Tuple<IntPtr, string>(modules.First().BaseAddress + 0x48A6AB7, "bool") }
            };
            PlotBoolsOffset = modules.First().BaseAddress + 0x482C908;
        break;

        default:
            // In case of a new game version, this part will attempt to use sigscanning to recover the memory offsets.
            // Note: sigscanning is potentially unrealiable due to how the anti-debug features of this game work.

            // If the game has been launched from less than 5 seconds, throw an exception and re-execute the script.
            // This is necessary to let the game decrypt some of the memory pages needed for sigscanning
            if (game.StartTime > DateTime.Now - TimeSpan.FromSeconds(5d)) throw new Exception("Game launched less than 5 seconds ago. Retrying...");

            IntPtr ptr;
            SignatureScanner scanner;
            var FoundVars = new Dictionary<string, bool>();

            foreach (var page in memory.MemoryPages(true).Where(m => (long)m.BaseAddress >= (long)modules.First().BaseAddress))
            {
                scanner = new SignatureScanner(memory, page.BaseAddress, (int)page.RegionSize);

                if (!FoundVars.ContainsKey("LoadStatus")) FoundVars.Add("LoadStatus", false);
                if (!FoundVars["LoadStatus"])
                {
                    ptr = scanner.Scan(new SigScanTarget(3,
                        "0F BF 05 ????????",    // movsx eax,word ptr [HaloInfinite.exe+5007ADC]  <---
                        "3B C6")                // cmp eax,esi
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
                    if (ptr != IntPtr.Zero)
                    {
                        LoadStatusVars["LoadStatus"] = new Tuple<IntPtr, string>(ptr, "bool");
                        FoundVars["LoadStatus"] = true;
                    }
                }

                if (!FoundVars.ContainsKey("LoadStatus2")) FoundVars.Add("LoadStatus2", false);
                if (!FoundVars["LoadStatus2"])
                {
                    ptr = scanner.Scan(new SigScanTarget(5,
                        "89 45 94",             // mov [rbp-6c],eax
                        "8B 05 ????????")       // mov eax,[HaloInfinite.exe+4FFDD04]
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
                    if (ptr != IntPtr.Zero)
                    {
                        LoadStatusVars["LoadStatus2"] = new Tuple<IntPtr, string>(ptr, "byte");
                        FoundVars["LoadStatus2"] = true;
                    }
                }

                if (!FoundVars.ContainsKey("StatusString")) FoundVars.Add("StatusString", false);
                if (!FoundVars["StatusString"])
                {
                    ptr = scanner.Scan(new SigScanTarget(3,
                        "4C 8D 2D ????????",    // lea r13,[HaloInfinite.exe+4C9FDB0]  <---
                        "33 C0")                // xor eax,eax
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) + 0x1400 });
                    if (ptr != IntPtr.Zero)
                    {
                        LoadStatusVars["StatusString"] = new Tuple<IntPtr, string>(ptr, "string");
                        FoundVars["StatusString"] = true;
                    }
                }

                if (!FoundVars.ContainsKey("LoadScreen")) FoundVars.Add("LoadScreen", false);
                if (!FoundVars["LoadScreen"])
                {
                    ptr = scanner.Scan(new SigScanTarget(1,
                        "E8 ????????",          // call HaloInfinite.exe+EB5960 <---
                        "EB 2A",                // jmp HaloInfinite.exe+145EE92
                        "E8 ????????")          // call HaloInfinite.exe+EB58D0
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) + 0x7F + 0x3 });
                    if (ptr != IntPtr.Zero)
                    {
                        ptr += 0x4 + game.ReadValue<int>(ptr);
                        LoadStatusVars["LoadScreen"] = new Tuple<IntPtr, string>(ptr, "long");
                        FoundVars["LoadScreen"] = true;
                    }
                }

                if (!FoundVars.ContainsKey("LoadingIcon")) FoundVars.Add("LoadingIcon", false);
                if (!FoundVars["LoadingIcon"])
                {
                    ptr = scanner.Scan(new SigScanTarget(1,
                        "E8 ????????",         // call HaloInfinite.GameVariantProperty_SetStringIdProperty_ED50  <---
                        "44 8B 3B")            // mov r15d,[rbx]
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) + 0xBE + 0x3 });
                    if (ptr != IntPtr.Zero)
                    {
                        ptr += 0x4 + game.ReadValue<int>(ptr) + 0x8;
                        LoadStatusVars["LoadingIcon"] = new Tuple<IntPtr, string>(ptr, "bool"); // Hoping it doesn't break on next game update
                        FoundVars["LoadingIcon"] = true;
                    }
                }

                if (!FoundVars.ContainsKey("IsLoadingInCutscene")) FoundVars.Add("IsLoadingInCutscene", false);
                if (!FoundVars["IsLoadingInCutscene"])
                {
                    ptr = scanner.Scan(new SigScanTarget(2,
                        "80 3D ???????? ??",    // cmp byte ptr [HaloInfinite.exe+48A6AB7],00
                        "75 10",                // jne HaloInfinite.exe+DFC7AD
                        "E8 ????????")          // call HaloInfinite.exe+DFC6A0
                        { OnFound = (p, s, addr) => addr + 0x5 + p.ReadValue<int>(addr) });
                    if (ptr != IntPtr.Zero)
                    {
                        LoadStatusVars["IsLoadingInCutscene"] = new Tuple<IntPtr, string>(ptr, "bool");
                        FoundVars["IsLoadingInCutscene"] = true; 
                    }
                }

                if (!FoundVars.ContainsKey("CampaignData")) FoundVars.Add("CampaignData", false);
                if (!FoundVars["CampaignData"])
                {
                    ptr = scanner.Scan(new SigScanTarget(3,
                        "48 8D 3D ????????",    // lea rdi,[HaloInfinite.exe+482C908]  <---
                        "0F1F 84 00 ????????",  // nop dword ptr [rax+rax+00000000]
                        "48 8B 1F")             // mov rbx,[rdi]
                        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
                    if (ptr != IntPtr.Zero)
                    {
                        PlotBoolsOffset = ptr;
                        FoundVars["CampaignData"] = true;
                    }
                }

                // If the script successfully found all the addresses, there's no need to continue the loop, so break it
                if (FoundVars.All(m => m.Value == true)) break;
            }

            if (FoundVars.Any(m => m.Value == false))
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
    foreach (KeyValuePair<string, Tuple<IntPtr, string>> entry in LoadStatusVars)
    {
        switch (entry.Value.Item2)
        {
            case "byte": vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(entry.Value.Item1)) { Name = entry.Key }); break;
            case "string": vars.watchers.Add(new StringWatcher(new DeepPointer(entry.Value.Item1), 255) { Name = entry.Key }); break;
            case "bool": vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(entry.Value.Item1)) { Name = entry.Key }); break;
            case "long": vars.watchers.Add(new MemoryWatcher<long>(new DeepPointer(entry.Value.Item1)) { Name = entry.Key }); break;
        }
    }
    foreach (var entry in PlotBools) vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(PlotBoolsOffset, entry.Value)) { Name = entry.Key });

    // Ultimately, explicitly define current.Map here to avoid throwing an Exception during the first update
    current.Map = string.Empty;
}

update
{
    // If we explicitly disabled the autosplitter, return false
    if (!vars.IsAutosplitterEnabled) return false;

    // Update the watchers
    vars.watchers.UpdateAll(game);

    // Explicitly define a couple of variables for easier access
    current.IsLoading =
            vars.watchers["LoadStatus2"].Current > 0 && vars.watchers["LoadStatus2"].Current < 4
            || vars.watchers["LoadStatus"].Current
            || vars.watchers["LoadingIcon"].Current
            || vars.watchers["LoadScreen"].Current != 0;
    
    current.Map = vars.watchers["StatusString"].Current.Substring(vars.watchers["StatusString"].Current.LastIndexOf("\\") + 1);

    // If the timer isn't running (eg. a run reset), reset the splits dictionary
    if (timer.CurrentPhase == TimerPhase.NotRunning) { foreach (var s in new List<string>(vars.AlreadyTriggeredSplits.Keys)) vars.AlreadyTriggeredSplits[s] = false; }
}

isLoading
{
    return current.IsLoading || vars.watchers["IsLoadingInCutscene"].Current;
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

    foreach (var entry in vars.SplitBools)
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
    return settings["startOnWarship"]
            ? current.Map == vars.Maps.WarshipGbraakon && vars.watchers["WarshipGbraakonStartTrigger"].Current == 3 && !current.IsLoading
            : current.Map == vars.Maps.WarshipGbraakon && old.IsLoading && !current.IsLoading && vars.watchers["WarshipGbraakonStartTrigger"].Current == 0;
}

exit
{
    timer.IsGameTimePaused = true;
}
