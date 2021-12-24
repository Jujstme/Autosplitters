state("HaloInfinite") {}

init
{
    // Basic check: if game is not a 64bit .exe, we hooked the wrong game process, so there's no need to continue
    if (!game.Is64Bit()) throw new Exception("Not a 64bit application!");

    // This is used as a flag to disable autosplitting if the game version is unsupported for whatever reason
    vars.IsAutosplitterEnabled = true;

    // Initialize the main watcher variable
    vars.watchers = new MemoryWatcherList();
    
    // Determine game version through the Arbiter.dll module
    switch (modules.Where(x => x.ModuleName == "Arbiter.dll").FirstOrDefault().ModuleMemorySize)
    {
        case 0x1263000: version = "6.10020.17952.0"; break;
        case 0x133F000: version = "6.10020.19048.0"; break;
        default: version = "Unknown game version"; break;
    }
    
    switch (version)
    {
        case "6.10020.19048.0":
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4FFDD04)) { Name = "LoadStatus" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x4FFDD08)) { Name = "LoadStatusPercentage" });
            vars.watchers.Add(new StringWatcher(new DeepPointer(modules.First().BaseAddress + 0x4CA11B0), 255) { Name = "StatusString" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x47E73E0)) { Name = "LoadScreen" });
            vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(modules.First().BaseAddress + 0x522A6D0)) { Name = "LoadingIcon" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB5550)) { Name = "OutpostTremonius" });
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
            // vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB7394)) { Name = "Road" });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(modules.First().BaseAddress + 0x482C908, 0xB740C)) { Name = "SilentAuditorium" });
            break;
            
        default:
            // If game version is not known, then try to find the memory addresses through signature scanning
            IntPtr ptr;
            SignatureScanner scanner;
            var FoundVars = new Dictionary<string, bool>{
                { "LoadStatusPercentage", false },
                { "StatusString", false },
                { "LoadScreen", false },
                { "CampaignData", false }
            };
            
            Thread.Sleep(3000);
            
            // Find the require memory addresses through sigScanning
            foreach (var page in game.MemoryPages(true).Where(m => (long)m.BaseAddress >= (long)modules.First().BaseAddress))
            {
                scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

                if (!FoundVars["LoadStatusPercentage"])
                {
                    ptr = scanner.Scan(new SigScanTarget(2, "89 05 ???????? 48 81 C4 ???????? 41 5F"));
                    if (ptr != IntPtr.Zero)
                    {
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr))) { Name = "LoadStatusPercentage" });
                        // If LoadStatus breaks in future game updates, we can scan for it using this alternative sigscan: 89 45 94 8B 05 ???????? 89 45 98
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + game.ReadValue<int>(ptr))) { Name = "LoadStatus" });
                        vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr) + 0x22C9C8)) { Name = "LoadingIcon" });
                        FoundVars["LoadStatusPercentage"] = true;
                    }
                }

                if (!FoundVars["StatusString"])
                {
                    ptr = scanner.Scan(new SigScanTarget(12, "00 00 00 00 00 00 00 00 00 00 00 00 6C 6F 61 64"));
                    if (ptr != IntPtr.Zero)
                    {
                        vars.watchers.Add(new StringWatcher(new DeepPointer(ptr), 255) { Name = "StatusString" });
                        FoundVars["StatusString"] = true;
                    }
                }

                if (!FoundVars["LoadScreen"])
                {
                    ptr = scanner.Scan(new SigScanTarget(2, "80 3D ???????? 00 74 17 48 8D 0D ???????? E8 ???????? 84 C0"));
                    if (ptr != IntPtr.Zero)
                    {
                        vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(ptr + 5 + game.ReadValue<int>(ptr))) { Name = "LoadScreen" });
                        FoundVars["LoadScreen"] = true;
                    }
                }
                
                if (!FoundVars["CampaignData"])
                {
                    ptr = scanner.Scan(new SigScanTarget(3, "4C 8D 35 ???????? 48 8D 0D ???????? 66"));
                    if (ptr != IntPtr.Zero)
                    {
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB5550)) { Name = "OutpostTremonius" });
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB746C)) { Name = "FOBGolf" });
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB55B0)) { Name = "Tower" });
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB72BC)) { Name = "TravelToDigSite" });
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB5308)) { Name = "Spire" });
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB7344)) { Name = "EastAAGun" });
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB7354)) { Name = "NorthAAGun" });
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB7364)) { Name = "WestAAGun" });
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB7384)) { Name = "PelicanSpartanKillers" });
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB9370)) { Name = "SequenceNorthernBeacon" });
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB9378)) { Name = "SequenceSouthernBeacon" });
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB9380)) { Name = "SequenceEasternBeacon" });
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB9388)) { Name = "SequenceSouthwesternBeacon" });
                        // vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB7394)) { Name = "Road" });
                        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0xB740C)) { Name = "SilentAuditorium" });
                        FoundVars["CampaignData"] = true;
                    }
                }

                // Once we found all the required addresses, we can exit the loop
                if (FoundVars["LoadStatusPercentage"] && FoundVars["StatusString"] && FoundVars["LoadScreen"] && FoundVars["CampaignData"]) break;
            }

            // If, for some reason, we didn't find all the addresses, this code will disable autosplitting functionality
            // and display a warning message
            if (!FoundVars["LoadStatusPercentage"] || !FoundVars["StatusString"] || !FoundVars["LoadScreen"] || !FoundVars["CampaignData"])
            {
                MessageBox.Show("This game version is not currently supported by the load remover.\n" +
                                "Failed to retrieve the needed memory addresses.\n\n" + 
                                "Load times removal and autosplitting functionality will be disabled.",
                                "LiveSplit - Halo Infinite", MessageBoxButtons.OK, MessageBoxIcon.Information);
                vars.IsAutosplitterEnabled = false;
            }
            break;
    }

    // Defining other variables we're gonna use in the update action
    current.Map = "";
    current.IsLoading = true;
}

startup
{
    settings.Add("chkBanished_Ship", true, "Warship Gbraakon");
    settings.Add("chkUnderbelly", true, "Foundation");
    settings.Add("chkOutpostTremonius", true, "Outpost Tremonius");
    settings.Add("chkFOBGolf", true, "FOB Golf");
    settings.Add("chkTower", true, "The Tower");
    settings.Add("chkDigSite", true, "Excavation Site");
    settings.Add("chkTravelToDigSite", true, "Reach the Excavation Site", "chkDigSite");
    settings.Add("chkBassus", true, "Bassus", "chkDigSite");
    settings.Add("chkConservatory", true, "Conservatory");
    settings.Add("chkSpire", true, "Spire");
    settings.Add("chkSpireApproach", true, "Approach the Command Spire", "chkSpire");
    settings.Add("chkSpireAdjutantResolution", true, "Adjutant Resolution", "chkSpire");
    settings.Add("chkPelicanDown", true, "Pelican Down");
    settings.Add("chkPelicanEastAAGun", true, "East AA Gun", "chkPelicanDown");
    settings.Add("chkPelicanNorthAAGun", true, "North AA Gun", "chkPelicanDown");
    settings.Add("chkPelicanWestAAGun", true, "West AA Gun", "chkPelicanDown");
    settings.Add("chkPelicanSpartanKillers", true, "Hyperius and Tovarus", "chkPelicanDown");
    settings.Add("chkSequence", true, "The Sequence");
    settings.Add("chkSequenceEasternBeacon", true, "Eastern Beacon", "chkSequence");
    settings.Add("chkSequenceSouthernBeacon", true, "Southern Beacon", "chkSequence");
    settings.Add("chkSequenceNorthernBeacon", true, "Northern Beacon", "chkSequence");
    settings.Add("chkSequenceSouthwesternBeacon", true, "Southwestern Beacon", "chkSequence");
    settings.Add("chkSequenceEnterCommandSpire", true, "Enter the Nexus", "chkSequence");
    settings.Add("chkNexus", true, "Nexus");
    settings.Add("chkSpire2", true, "The Command Spire");
    settings.Add("chkReachTheTop", true, "Reach the top", "chkSpire2");
    settings.Add("chkDeactivateSpire2", true, "Deactivate the command spire", "chkSpire2");
    settings.Add("chkRepository", true, "Repository");
    settings.Add("chkRoad", true, "The Road");
    settings.Add("HoR", true, "House of Reckoning");
    settings.Add("SilentAuditorium", true, "Silent Auditorium");

    settings.SetToolTip("chkBanished_Ship", "Will trigger a split after completing the mission \"Warship Gbraakon\".");
    settings.SetToolTip("chkUnderbelly", "Will trigger a split after completing the mission \"Foundation\".");
    settings.SetToolTip("chkOutpostTremonius", "Will trigger a split after taking control of Outpost Tremonius.");
    settings.SetToolTip("chkFOBGolf", "Will trigger a split after taking control of FOB Golf.");
    settings.SetToolTip("chkTower", "Will trigger a split after freeing Spartan Griffin upon completion of the mission \"The Tower\".");
    settings.SetToolTip("chkTravelToDigSite", "Will trigger a split after the first cutscene in the excavation site.");
    settings.SetToolTip("chkBassus", "Will trigger a split upon entering the Conservatory, after Bassus' defeat.");
    settings.SetToolTip("chkConservatory", "Will trigger a split after completing the mission \"Conservatory\".");
    settings.SetToolTip("chkSpireApproach", "Will trigger a split upon entering the first spire.");
    settings.SetToolTip("chkSpireAdjutantResolution", "Will trigger a split after defeting Adjuvant resolution and dectivating the spire.");
    settings.SetToolTip("chkPelicanEastAAGun", "Will trigger a split upon destruction of the East AA Gun.");
    settings.SetToolTip("chkPelicanNorthAAGun", "Will trigger a split upon destruction of the North AA Gun.");
    settings.SetToolTip("chkPelicanWestAAGun", "Will trigger a split upon destruction of the West AA Gun.");
    settings.SetToolTip("chkPelicanSpartanKillers", "Will trigger a split when finding Echo-216 after defeting the Spartan killers Hyperius and Tovarus.");
    settings.SetToolTip("chkSequenceEasternBeacon", "Will trigger a split after activating the Eastern Beacon.");
    settings.SetToolTip("chkSequenceSouthernBeacon", "Will trigger a split after activating the Southern Beacon.");
    settings.SetToolTip("chkSequenceNorthernBeacon", "Will trigger a split after activating the Northern Beacon.");
    settings.SetToolTip("chkSequenceSouthwesternBeacon", "Will trigger a split after activating the Southwestern Beacon.");
    settings.SetToolTip("chkSequenceEnterCommandSpire", "Will trigger a split upon entering the Nexus.");
    settings.SetToolTip("chkNexus", "Will trigger a split upon completing the mission \"Nexus\".");
    settings.SetToolTip("chkReachTheTop", "Will trigger a split upon reaching the top of the Command Spire.");
    settings.SetToolTip("chkDeactivateSpire2", "Will trigger a split after deactivation of the Command Spire.");
    settings.SetToolTip("chkRepository", "Will trigger a split upon completion of the mission \"Repository\".");
    settings.SetToolTip("chkRoad", "Will trigger a split upon entering the House of Reckoning.");
    settings.SetToolTip("HoR", "Will trigger a split upon completion of the House of Reckoning.");
    settings.SetToolTip("SilentAuditorium", "Will trigger a split upon defeat of the Harbringer.");

    // In order to avoid duplicated splitting when reloading a map, we need to set up a Dictionary which tells us whether we already triggered a split or not
    string[] splits = new string[] { "Banished_Ship", "Foundation", "OutpostTremonius", "FOB Golf", "Tower", "TravelToDigSite", "Bassus", "Conservatory", "SpireApproach",
                                 "SpireAdjutantResolution", "PelicanEast", "PelicanNorth", "PelicanWest", "PelicanSpartanKillers", "SequenceEasternBeacon",
                                 "SequenceSouthernBeacon", "SequenceNorthernBeacon", "SequenceSouthwesternBeacon", "SequenceEnterCommandSpire", "Nexus",
                                 "ReachTheTop", "Spire2", "Repository", "Road", "HoR", "SilentAuditorium" };
    vars.splits = new Dictionary<string, bool>();
    foreach (string s in splits) vars.splits.Add(s, false);
}

update
{
    // If the game is not supported, explicitly return false to shut down the autosplitter
    if (!vars.IsAutosplitterEnabled) return false;
    
    // Update the watchers
    vars.watchers.UpdateAll(game);
    
    // Redefine game variables
    current.Map = vars.watchers["StatusString"].Current.Substring(vars.watchers["StatusString"].Current.LastIndexOf("\\") + 1);

    current.IsLoading = vars.watchers["StatusString"].Current.Substring(0, vars.watchers["StatusString"].Current.LastIndexOf(" ")) == "loading" ||
            vars.watchers["LoadStatus"].Current == 3 ||
            // vars.watchers["LoadStatus"].Current < 4 ||
            vars.watchers["LoadingIcon"].Current || vars.watchers["LoadScreen"].Current ||
            (vars.watchers["LoadStatusPercentage"].Current == 100 && vars.watchers["LoadStatus"].Current < 4) ||
            (vars.watchers["LoadStatusPercentage"].Current != 0 && vars.watchers["LoadStatusPercentage"].Current != 100);
 
    // If the timer isn't running (eg. a run reset), reset the splits dictionary
    if (timer.CurrentPhase == TimerPhase.NotRunning) { foreach (var s in new List<string>(vars.splits.Keys)) vars.splits[s] = false; }
}

split
{
    // Warship Gbraakon
    if (!vars.splits["Banished_Ship"] && old.Map == "dungeon_banished_ship" && current.Map == "dungeon_underbelly") { vars.splits["Banished_Ship"] = true; return settings["chkBanished_Ship"]; }
    // Foundation
    else if (!vars.splits["Foundation"] && old.Map == "dungeon_underbelly" && current.Map == "island01") { vars.splits["Foundation"] = true; return settings["chkUnderbelly"]; }
    // Outpost Tremonius
    else if (!vars.splits["OutpostTremonius"] && current.Map == "island01" && vars.watchers["OutpostTremonius"].Changed && vars.watchers["OutpostTremonius"].Old == 0) { vars.splits["OutpostTremonius"] = true; return settings["chkOutpostTremonius"]; }
    // FOB Golf
    else if (!vars.splits["FOB Golf"] && current.Map == "island01" && vars.watchers["FOBGolf"].Changed && vars.watchers["FOBGolf"].Current == 10) { vars.splits["FOB Golf"] = true; return settings["chkFOBGolf"]; }
    // Tower
    else if (!vars.splits["Tower"] && current.Map == "island01" && vars.watchers["Tower"].Changed && vars.watchers["Tower"].Current == 10) { vars.splits["Tower"] = true; return settings["chkTower"]; }
    // Travel to Dig Site
    else if (!vars.splits["TravelToDigSite"] && current.Map == "island01" && vars.watchers["TravelToDigSite"].Changed && vars.watchers["TravelToDigSite"].Current == 10) { vars.splits["TravelToDigSite"] = true; return settings["chkTravelToDigSite"]; }
    // Bassus
    else if (!vars.splits["Bassus"] && old.Map == "island01" && current.Map == "dungeon_forerunner_dallas") { vars.splits["Bassus"] = true; return settings["chkBassus"]; }
    // Conservatory
    else if (!vars.splits["Conservatory"] && old.Map == "dungeon_forerunner_dallas" && current.Map == "island01") { vars.splits["Conservatory"] = true; return settings["chkConservatory"]; }
    // Spire approach
    else if (!vars.splits["SpireApproach"] && old.Map == "island01" && current.Map == "dungeon_spire_01") { vars.splits["SpireApproach"] = true; return settings["chkSpireApproach"]; }
    // Spire: Adjutant resolution
    else if (!vars.splits["SpireAdjutantResolution"] && current.Map == "island01" && vars.watchers["Spire"].Changed && vars.watchers["Spire"].Current == 10) { vars.splits["SpireAdjutantResolution"] = true; return settings["chkSpireAdjutantResolution"]; }
    // Pelican down: East AA gun
    else if (!vars.splits["PelicanEast"] && current.Map == "island01" && vars.watchers["EastAAGun"].Changed && vars.watchers["EastAAGun"].Current == 10) { vars.splits["PelicanEast"] = true; return settings["chkPelicanEastAAGun"]; }
    // Pelican down: North AA gun
    else if (!vars.splits["PelicanNorth"] && current.Map == "island01" && vars.watchers["NorthAAGun"].Changed && vars.watchers["NorthAAGun"].Current == 10) { vars.splits["PelicanNorth"] = true; return settings["chkPelicanNorthAAGun"]; }
    // Pelican down: West AA gun
    else if (!vars.splits["PelicanWest"] && current.Map == "island01" && vars.watchers["WestAAGun"].Changed && vars.watchers["WestAAGun"].Current == 10) { vars.splits["PelicanWest"] = true; return settings["chkPelicanWestAAGun"]; }
    // Pelican down: Spartan Killers
    else if (!vars.splits["PelicanSpartanKillers"] && current.Map == "island01" && vars.watchers["PelicanSpartanKillers"].Changed && vars.watchers["PelicanSpartanKillers"].Current == 10) { vars.splits["PelicanSpartanKillers"] = true; return settings["chkPelicanSpartanKillers"]; }
    // Sequence: Northern Beacon
    else if (!vars.splits["SequenceNorthernBeacon"] && current.Map == "island01" && vars.watchers["SequenceNorthernBeacon"].Changed && vars.watchers["SequenceNorthernBeacon"].Current == 10) { vars.splits["SequenceNorthernBeacon"] = true; return settings["chkSequenceNorthernBeacon"]; }
    // Sequence: Southern Beacon
    else if (!vars.splits["SequenceSouthernBeacon"] && current.Map == "island01" && vars.watchers["SequenceSouthernBeacon"].Changed && vars.watchers["SequenceSouthernBeacon"].Current == 10) { vars.splits["SequenceSouthernBeacon"] = true; return settings["chkSequenceSouthernBeacon"]; }
    // Sequence: Eastern Beacon
    else if (!vars.splits["SequenceEasternBeacon"] && current.Map == "island01" && vars.watchers["SequenceEasternBeacon"].Changed && vars.watchers["SequenceEasternBeacon"].Current == 10) { vars.splits["SequenceEasternBeacon"] = true; return settings["chkSequenceEasternBeacon"]; }
    // Sequence: Southwestern Beacon
    else if (!vars.splits["SequenceSouthwesternBeacon"] && current.Map == "island01" && vars.watchers["SequenceSouthwesternBeacon"].Changed && vars.watchers["SequenceSouthwesternBeacon"].Current == 10) { vars.splits["SequenceSouthwesternBeacon"] = true; return settings["chkSequenceSouthwesternBeacon"]; }
    // Sequence: enter the Spire
    else if (!vars.splits["SequenceEnterCommandSpire"] && old.Map == "island01" && current.Map == "dungeon_forerunner_houston") { vars.splits["SequenceEnterCommandSpire"] = true; return settings["chkSequenceEnterCommandSpire"]; }
    // Nexus
    else if (!vars.splits["Nexus"] && old.Map == "dungeon_forerunner_houston" && current.Map == "dungeon_spire_02") { vars.splits["Nexus"] = true; return settings["chkNexus"]; }
    // Spire2: Reach the top
    else if (!vars.splits["ReachTheTop"] && old.Map == "dungeon_spire_02" && current.Map == "island01") { vars.splits["ReachTheTop"] = true; return settings["chkReachTheTop"]; }
    // Spire2: deactivate the spires
    else if (!vars.splits["Spire2"] && old.Map == "island01" && current.Map == "dungeon_forerunner_austin") { vars.splits["Spire2"] = true; return settings["chkSpire2"]; }
    // Repository
    else if (!vars.splits["Repository"] && old.Map == "dungeon_forerunner_austin" && current.Map == "island01") { vars.splits["Repository"] = true; return settings["chkRepository"]; }
    // Road
    else if (!vars.splits["Road"] && old.Map == "island01" && current.Map == "dungeon_boss_hq_interior") { vars.splits["Road"] = true; return settings["chkRoad"]; }
    // House of Reckoning
    else if (!vars.splits["HoR"] && old.Map == "dungeon_boss_hq_interior" && current.Map == "dungeon_cortana_palace") { vars.splits["HoR"] = true; return settings["HoR"]; }
    // Silent Auditorium
    else if (!vars.splits["SilentAuditorium"] && current.Map == "dungeon_cortana_palace" && vars.watchers["SilentAuditorium"].Changed && vars.watchers["SilentAuditorium"].Current == 10) { vars.splits["SilentAuditorium"] = true; return settings["SilentAuditorium"]; }
}

start
{
    return current.Map == "dungeon_banished_ship" && old.IsLoading && !current.IsLoading;
}

isLoading
{
    return current.IsLoading;
}

exit
{
    timer.IsGameTimePaused = true;
}
