state("MassEffect1") {}
state("MassEffect2") {}
state("MassEffect3") {}

init
{
    // Exclude script from running if you open the Legendary edition of the game, which shares the same .exe name
    if (!game.Is64Bit()) throw new Exception("Not a 64bit application! Check if you're running the Legendary Edition of the game!");

    // Determine which game you're currently running and sets the variables accordingly
    switch (memory.ProcessName) {
        case "MassEffect1" : version = "Mass Effect 1 LE"; vars.trilogy = 1; break;
        case "MassEffect2" : version = "Mass Effect 2 LE"; vars.trilogy = 2; break;
        case "MassEffect3" : version = "Mass Effect 3 LE"; vars.trilogy = 3; break;
    }

    // Custom functions
    vars.bitCheck = new Func<string, int, bool>((string plotEvent, int b) => ((byte)(vars.watchers[plotEvent].Current) & (1 << b)) != 0);
    Func<IntPtr, int, int> targetAddress = new Func<IntPtr, int, int>((IntPtr rel, int offset) => (int)((long)rel - (long)modules.First().BaseAddress + memory.ReadValue<int>(rel) + offset));

    // Initialize the main watcher variable
    vars.watchers = new MemoryWatcherList();

    // Initialize variables needed for signature scanning
    var scanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);
    IntPtr ptr = IntPtr.Zero;
    Dictionary<string, int> plotBools = new Dictionary<string, int>();

    // Variables used by all 3 games
    ptr = scanner.Scan(new SigScanTarget(4,
        "75 18",             // jne MassEffect1.exe+310FD6           // jne MassEffect2+475742               // jne MassEffect3.exe+480D12
        "8B 0D ????????",    // mov ecx,[MassEffect1.exe+16516B0]    // mov ecx,[MassEffect2.exe+16232F0]    // mov ecx,[MassEffect3.exe+1767AA0]  <----
        "85 C9"));           // test ecx,ecx                         // test ecx,ecx                         // test ecx,ecx
    if (ptr == IntPtr.Zero) throw new Exception("Could not find address!");
    vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(targetAddress(ptr, 4))) { Name = "isLoading" });      // This value is 0 while the game displays cutscenes, otherwise it stays at 1


    // Game-specific variables

    if (vars.trilogy == 1) {
    // Mass Effect 1 uses an additional variable for loading messages
        ptr = scanner.Scan(new SigScanTarget(2,
            "83 3D ???????? 00",  // cmp dword ptr [MassEffect1.exe+17775B8],00  <----
            "74 20",              // je MassEffect1.exe+2596F1
            "48 8B 03"));         // mov rax,[rbx]
        if (ptr == IntPtr.Zero) throw new Exception("Could not find address!");
        vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(targetAddress(ptr, 5))) { Name = "isLoading2" }); // This value is 1 in load messages, otherwise it's 0 
    }

    if (vars.trilogy == 2) {
    // Mass Effect 2 plot bools for automatic splitting
        ptr = scanner.Scan(new SigScanTarget(8,
            "48 85 C0",             // test rax,rax
            "74 42",                // je MassEffect2.exe+6DAA15
            "4C 8B 05 ????????"));  // mov r8,[MassEffect2.exe+1B675B0]  <----
        if (ptr == IntPtr.Zero) throw new Exception("Could not find address!");

        // Main story progression 
        plotBools.Add("plotPrologue", 0x14A);      // Used for prologue mission
        plotBools.Add("plotCR0", 0x43);            // CR0, CR1, CR2 and CR3 are the CRitical missions that drive the story forward (Freedom's progress, Horizon, Collector Ship and Normany crew abduction)
        plotBools.Add("plotCR123", 0x27);          // CR0, CR1, CR2 and CR3 are the CRitical missions that drive the story forward (Freedom's progress, Horizon, Collector Ship and Normany crew abduction)
        plotBools.Add("plotIFF", 0xB3);            // Corresponds to Legion acquisition, which is one and the same with the reaper IFF mission
        plotBools.Add("crewAbduct", 0x12E);        // Used in place of CR3 for "reasons"
        plotBools.Add("suicideOculus", 0xFE);      // Suicide mission: destroying the oculus
        plotBools.Add("suicideValve", 0x16F);      // Suicide mission: making it through the ventilation system
        plotBools.Add("suicideBubble", 0x170);     // Suicide mission: making it through the biotic bubble part
        plotBools.Add("suicideReaper", 0x1BC);     // Used for signalling the end of the game

        // Dossiers
        plotBools.Add("crewAcq1", 0x278);          // For Mordin, Jack, Garrus, Tali
        plotBools.Add("crewAcq2", 0x4D);           // For Grunt
        plotBools.Add("crewAcq3", 0x279);          // For Thane
        plotBools.Add("crewAcq4", 0x47);           // For Samara
        plotBools.Add("crewAcq5", 0x32);           // For Zaeed
        plotBools.Add("crewAcq6", 0xB9);           // For Kasumi

        // Loyalty missions
        plotBools.Add("loyaltyMissions1", 0xBB);   // Loyalty mission status for Miranda, Jacob, Jack, Legion, Kasumi, Garrus, Thane and Tali
        plotBools.Add("loyaltyMissions2", 0xBC);   // Loyalty mission status for Mordin, Grunt, Samara/Morinth and Zaeed

        // N7 Missions
        plotBools.Add("WMF", 0x1A8);               // N7: Wrecked Merchant Freighter
        plotBools.Add("ARS", 0x225);               // N7: Abandoned Research Station
        plotBools.Add("ADS", 0x18C);               // N7: Archeological Dig Site
        plotBools.Add("MSVE", 0x156);              // N7: MSV Estevanico
        plotBools.Add("ESD", 0x28A);               // N7: Eclipse Smuggling Depot (and N7: Endangered Research Station)
        plotBools.Add("LO", 0x288);                // N7: Lost Operative

        // Address checks put in place for avoiding unwanted splitting
        plotBools.Add("WakeUp", 0x119);            // Bool for the "wake up" scene at Lazarus Lab

        foreach(KeyValuePair<string, int> entry in plotBools) vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(targetAddress(ptr, 4), 0x16C, 0xA34, 0x60, entry.Value)) { Name = entry.Key });


        // XYZ position
        ptr = scanner.Scan(new SigScanTarget(21,
            "41 8B DC",             // mov ebx,r12d
            "85 DB",                // test ebx,ebx
            "78 3A",                // js MassEffect2.exe+598505
            "3B 1D ????????",       // cmp ebx,[MassEffect2.exe+1760018
            "7D 32",                // jnl MassEffect2.exe+598505
            "48 63 FB",             // movsxd rdi,ebx
            "48 8B 05 ????????"));  // mov rax,[MassEffect2.exe+1760010]  <----
        if (ptr == IntPtr.Zero) throw new Exception("Could not find address!");
        plotBools = new Dictionary<string, int>();
        plotBools.Add("XPOS", 0x118);              // XPOS
        plotBools.Add("YPOS", 0x11C);              // YPOS
        plotBools.Add("ZPOS", 0x120);              // ZPOS
        foreach(KeyValuePair<string, int> entry in plotBools) vars.watchers.Add(new MemoryWatcher<uint>(new DeepPointer(targetAddress(ptr, 4), 0x0, 0x78, entry.Value)) { Name = entry.Key });
    }

    if (vars.trilogy == 3) {
    // Mass Effect 3 plot bools for automatic splitting
        ptr = scanner.Scan(new SigScanTarget(13,
            "C3",                   // ret
            "CC",                   // int 3
            "CC",                   // int 3
            "CC",                   // int 3
            "CC",                   // int 3
            "CC",                   // int 3
            "48 83 EC 28",          // sub rsp,28
            "48 8B 0D ????????",    // mov rcx,[MassEffect3.exe+1CBBC70]   <----
            "48 85 C9",             // test rcx,rcx
            "75 1F",                // jne MassEffect3.exe+AD241F
            "48 8D 0D ????????"));  // lea rcx,[MassEffect3.exe+10AE638]
        if (ptr == IntPtr.Zero) throw new Exception("Could not find address!");

        // Story progression
        plotBools.Add("prologueEarth", 0x9ED);
        plotBools.Add("priorityMars", 0xA09);
        plotBools.Add("priorityCitadel", 0xA14);
        plotBools.Add("priorityPalaven", 0x924);
        plotBools.Add("prioritySurkesh", 0x8A9);
        plotBools.Add("preTuchanka", 0x940);
        plotBools.Add("priorityTuchanka", 0x8FA);
        plotBools.Add("priorityCitadelCerberus", 0x983);
        plotBools.Add("rannochKoris", 0x934);
        plotBools.Add("rannochGethServer", 0x935);
        plotBools.Add("priorityRannoch", 0x967);
        plotBools.Add("priorityThessia", 0x906);
        plotBools.Add("priorityHorizonME3", 0x989);
        plotBools.Add("priorityCerberusHead", 0x9DD);
        plotBools.Add("priorityEarth", 0xA70);
        plotBools.Add("priorityEndingME3", 0xAF3);

        foreach(KeyValuePair<string, int> entry in plotBools) vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(targetAddress(ptr, 4), 0x13C, 0xF0, entry.Value)) { Name = entry.Key });


        // XYZ position
        ptr = scanner.Scan(new SigScanTarget(8,
            "0F1F 44 00 00",        // nop dword ptr [rax+rax+00]
            "85 DB",                // test ebx,ebx
            "78 3A",                // js MassEffect3.exe+59A75E
            "3B 1D ????????",       // cmp ebx,[MassEffect3.exe+18B4248
            "7D 32",                // jnl MassEffect3.exe+59A75E
            "48 63 FB",             // movsxd rdi,ebx
            "48 8B 05 ????????"));  // mov rax,[MassEffect3.exe+18B4240]  <----
        if (ptr == IntPtr.Zero) throw new Exception("Could not find address!");
        plotBools = new Dictionary<string, int>();
        plotBools.Add("XPOS", 0x108); // XPOS
        plotBools.Add("YPOS", 0x10C); // YPOS
        plotBools.Add("ZPOS", 0x110); // ZPOS
        foreach(KeyValuePair<string, int> entry in plotBools) vars.watchers.Add(new MemoryWatcher<uint>(new DeepPointer(targetAddress(ptr, 4), 0x0, 0x78, entry.Value)) { Name = entry.Key });
    }
}

startup
{
  if (timer.CurrentTimingMethod == TimingMethod.RealTime) {
    var timingMessage = MessageBox.Show (
    "This game uses Time without Loads (Game Time) as the main timing method on speedrun.com.\n"+
    "LiveSplit is currently set to show Real Time (RTA).\n\n"+
    "Would you like to set the timing method to Game Time?",
    "Mass Effect Legendary Edition | LiveSplit",
    MessageBoxButtons.YesNo,MessageBoxIcon.Question);
    if (timingMessage == DialogResult.Yes) {
      timer.CurrentTimingMethod = TimingMethod.GameTime;
      MessageBox.Show("Timing method has been set to GameTime!", "Mass Effect Legendary Edition | LiveSplit", MessageBoxButtons.OK, MessageBoxIcon.Information);
    } else if (timingMessage == DialogResult.No) {
      timer.CurrentTimingMethod = TimingMethod.RealTime;
      MessageBox.Show("Timing method will stay set to Real Time (RTA).", "Mass Effect Legendary Edition | LiveSplit", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }
  }

    // ME2 Autosplitting settings
    settings.Add("ME2", true, "Mass Effect 2 - Autosplitting");
    settings.Add("escapeLazarus", true, "Prologue: Awakening", "ME2");
    settings.Add("freedomProgress", true, "Freedom's Progress", "ME2");
    settings.Add("recruitMordin", true, "Dossier: The Professor", "ME2");
    settings.Add("recruitGarrus", true, "Dossier: Archangel", "ME2");
    settings.Add("recruitJack", true, "Dossier: The Convict", "ME2");
    settings.Add("acquireGrunt", true, "Dossier: The Warlord", "ME2");
    settings.Add("horizonCompleted", true, "Horizon", "ME2");
    settings.Add("N7_WMF", true, "N7: Wrecked Merchant Freighter", "ME2");      // Eagle Nebula --> Amun --> Neith
    settings.Add("N7_ARS", true, "N7: Abandoned Research Station", "ME2");      // Jarrahe Station
    settings.Add("N7_ADS", true, "N7: Archeological Dig Site", "ME2");          // Rosetta --> Enoch (Prothean artifact)
    settings.Add("N7_MSVE", true, "N7: MSV Estevanico", "ME2");                 // Hourglass --> Ploitari --> Zanethu
    settings.Add("N7_ESD", true, "N7: Eclipse Smuggling Depot", "ME2");         // Hourglass --> Faryar --> Daratar
    settings.Add("collectorShip", true, "Collector ship", "ME2");
    settings.Add("reaperIFF", true, "Reaper IFF", "ME2");
    settings.Add("N7_ERS", true, "N7: Endangered Research Station", "ME2");     // Caleston Rift --> Solveig --> Sinmara
    settings.Add("N7_LO", true, "N7: Lost Operative", "ME2");                   // Omega Nebula --> Fathar --> Lorek
    settings.Add("crewAbuct", true, "Normandy crew abduction", "ME2");
    settings.Add("ME2SuocideMission", true, "Suicide Mission", "ME2");
    settings.Add("ME2Oculus", true, "Oculus", "ME2SuocideMission");
    settings.Add("ME2Valve", true, "Valve", "ME2SuocideMission");
    settings.Add("ME2Bubble", true, "Bubble", "ME2SuocideMission");
    settings.Add("ME2ending", true, "Human Reaper", "ME2SuocideMission");
    settings.Add("DLCcharactersRectuitment", false, "DLC Characters rectuitment", "ME2");
    settings.Add("recruitKasumi", true, "Dossier: The Master Thief", "DLCcharactersRectuitment");
    settings.Add("recruitZaeed", true, "Dossier: The Veteran", "DLCcharactersRectuitment"); 
    settings.Add("ME2OptionalDossiers", true, "Optional Dossiers", "ME2");
    settings.Add("recruitThane", true, "Dossier: The Assassin", "ME2OptionalDossiers");
    settings.Add("recruitSamara", true, "Dossier: The Justicar", "ME2OptionalDossiers");
    settings.Add("recruitTali", true, "Dossier: Tali", "ME2OptionalDossiers");
    settings.Add("ME2LoyaltyMissions", true, "Loyalty Missions", "ME2");
    settings.Add("loyaltyMiranda", true, "Miranda", "ME2LoyaltyMissions");
    settings.Add("loyaltyJacob", true, "Jacob", "ME2LoyaltyMissions");
    settings.Add("loyaltyJack", true, "Jack", "ME2LoyaltyMissions");
    settings.Add("loyaltyLegion", true, "Legion", "ME2LoyaltyMissions");
    settings.Add("loyaltyKasumi", true, "Kasumi", "ME2LoyaltyMissions");
    settings.Add("loyaltyGarrus", true, "Garrus", "ME2LoyaltyMissions");
    settings.Add("loyaltyThane", true, "Thane", "ME2LoyaltyMissions");
    settings.Add("loyaltyTali", true, "Tali", "ME2LoyaltyMissions");
    settings.Add("loyaltyMordin", true, "Mordin", "ME2LoyaltyMissions");
    settings.Add("loyaltyGrunt", true, "Grunt", "ME2LoyaltyMissions");
    settings.Add("loyaltySamara", true, "Samara", "ME2LoyaltyMissions");
    settings.Add("loyaltyZaeed", true, "Zaeed", "ME2LoyaltyMissions");

    // Mass Effect 3 autosplitting settings
    settings.Add("ME3", true, "Mass Effect 3 - Autosplitting");
    settings.Add("prologue", true, "Earth: Prologue", "ME3");
    settings.Add("priorityMars", true, "Priority: Mars", "ME3");
    settings.Add("priorityCitadel", true, "Priority: Citadel", "ME3");
    settings.Add("priorityPalaven", true, "Priority: Palaven", "ME3");
    settings.Add("prioritySurkesh", true, "Priority: Sur'Kesh", "ME3");
    settings.Add("preTuchanka", true, "Side Missions before Priority: Tuchanka", "ME3");
    settings.Add("turianPlatoon", true, "Tuchanka: Turian Platoon", "preTuchanka");
    settings.Add("koganRachni", true, "Krogan: Attican Traverse", "preTuchanka");
    settings.Add("priorityTuchanka", true, "Priority: Tuchanka", "ME3");
    settings.Add("priorityBeforeThessia", true, "Priority: Citadel (Cerberus Attack)", "ME3");
    settings.Add("priorityGethDreadnought", true, "Priority: Geth Dreadnought", "ME3");
    settings.Add("preRannoch", true, "Side Missions before Priority: Rannoch", "ME3");
    settings.Add("admiralKoris", true, "Rannoch: Admiral Koris", "preRannoch");
    settings.Add("gethServer", true, "Rannoch: Geth Fighters Squadrons", "preRannoch");
    settings.Add("priorityRannoch", true, "Priority: Rannoch", "ME3");
    settings.Add("priorityThessia", true, "Priority: Thessia", "ME3");
    settings.Add("priorityHorizon", true, "Priority: Horizon", "ME3");
    settings.Add("priorityCerberusHQ", true, "Priority: Cerberus Headquarters", "ME3");
    settings.Add("priorityEarth", true, "Priority: Earth", "ME3");  // Triggers when reaching the conduit
    settings.Add("priorityEnding", true, "Priority: The Crucible", "ME3");  
}

update
{
    vars.watchers.UpdateAll(game);

    if (vars.trilogy == 2) {
        // Main story progression missions
        current.lazarusCompleted          = vars.bitCheck("plotPrologue", 5) && !vars.bitCheck("plotCR0", 1);
        current.FreedomProgressCompleted  = vars.bitCheck("plotCR0", 1);
        current.horizonCompleted          = vars.bitCheck("plotCR123", 0);
        current.collectorShipCompleted    = vars.bitCheck("plotCR123", 1);
        current.reaperIFFcompleted        = vars.bitCheck("plotIFF", 3);
        current.crewAbductMissionComplete = vars.bitCheck("crewAbduct", 1);

        // Suicide mission
        current.suicideOculusDestroyed = vars.bitCheck("suicideOculus", 4);
        current.suicideValveCompleted  = vars.bitCheck("suicideValve", 5);
        current.suicideBubbleCompleted = vars.bitCheck("suicideBubble", 0);
        current.suicideMissonCompleted = vars.bitCheck("suicideReaper", 3) || vars.bitCheck("suicideReaper", 5) || vars.bitCheck("suicideReaper", 6);

        // Recruitment missions Phase 1
        current.MordinRecruited    = vars.bitCheck("crewAcq1", 6);
        current.GarrusRecruited    = vars.bitCheck("crewAcq1", 5);
        current.JackRecruited      = vars.bitCheck("crewAcq1", 3);
        current.GruntTankRecovered = vars.bitCheck("crewAcq2", 2);

        // Recruitment missions Phase 2
        current.TaliRecruited   = vars.bitCheck("crewAcq1", 7);
        current.ThaneRecruited  = vars.bitCheck("crewAcq3", 1);
        current.SamaraRecruited = vars.bitCheck("crewAcq4", 4);

        // N7 missions
        current.N7WMF_completed  = vars.bitCheck("WMF", 0);
        current.N7ARS_completed  = vars.bitCheck("ARS", 6);
        current.N7ADS_completed  = vars.bitCheck("ADS", 0);
        current.N7MSVE_completed = vars.bitCheck("MSVE", 2);
        current.N7ESD_completed  = vars.bitCheck("ESD", 2);
        current.N7ERS_completed  = vars.bitCheck("ESD", 3);
        current.N7LO_completed   = vars.bitCheck("LO", 7);

        // DLC recruitments
        current.ZaeedRecruited  = vars.bitCheck("crewAcq5", 4);
        current.KasumiRecruited = vars.bitCheck("crewAcq6", 4);

        // Loyalty missions
        current.MirandaLoyaltyMissionCompleted = vars.bitCheck("loyaltyMissions1", 0);
        current.JacobLoyaltyMissionCompleted   = vars.bitCheck("loyaltyMissions1", 1);
        current.JackLoyaltyMissionCompleted    = vars.bitCheck("loyaltyMissions1", 2);
        current.LegionLoyaltyMissionCompleted  = vars.bitCheck("loyaltyMissions1", 3);
        current.KasumiLoyaltyMissionCompleted  = vars.bitCheck("loyaltyMissions1", 4);
        current.GarrusLoyaltyMissionCompleted  = vars.bitCheck("loyaltyMissions1", 5);
        current.ThaneLoyaltyMissionCompleted   = vars.bitCheck("loyaltyMissions1", 6);
        current.TaliLoyaltyMissionCompleted    = vars.bitCheck("loyaltyMissions1", 7);
        current.MordinLoyaltyMissionCompleted  = vars.bitCheck("loyaltyMissions2", 0);
        current.GruntLoyaltyMissionCompleted   = vars.bitCheck("loyaltyMissions2", 1);
        current.SamaraLoyaltyMissionCompleted  = vars.bitCheck("loyaltyMissions2", 2);
        current.ZaeedLoyaltyMissionCompleted   = vars.bitCheck("loyaltyMissions2", 3);

        // Split Checks
        current.allowSplitting   = vars.bitCheck("WakeUp", 7);
    }

    if (vars.trilogy == 3) {
        // Story progression
        current.prologueEarthCompleted           = vars.bitCheck("prologueEarth", 1);
        current.priorityMarsCompleted            = vars.bitCheck("prologueEarth", 0);
        current.priorityCitadelCompleted         = vars.bitCheck("priorityCitadel", 5);
        current.priorityPalavenCompleted         = vars.bitCheck("priorityPalaven", 3);
        current.prioritySurkeshCompleted         = vars.bitCheck("prioritySurkesh", 7);
        current.priorityTurianPlatoonCompleted   = vars.bitCheck("preTuchanka", 2);
        current.priorityKroganRachniCompleted    = vars.bitCheck("preTuchanka", 3);
        current.priorityTuchankaCompleted        = vars.bitCheck("priorityTuchanka", 4);
        current.priorityCerberusCitadelCompleted = vars.bitCheck("priorityCitadelCerberus", 0);
        current.priorityGethDreadCompleted       = vars.bitCheck("prioritySurkesh", 5);
        current.priorityKorisCompleted           = vars.bitCheck("rannochKoris", 6);
        current.priorityGethServerCompleted      = vars.bitCheck("rannochGethServer", 0);
        current.priorityRannochCompleted         = vars.bitCheck("priorityRannoch", 6);
        current.priorityThessiaCompleted         = vars.bitCheck("priorityThessia", 2);
        current.priorityHorizonME3Completed      = vars.bitCheck("priorityHorizonME3", 7);
        current.priorityCerberusHQCompleted      = vars.bitCheck("priorityCerberusHead", 2);
        current.priorityEarthCompleted           = vars.bitCheck("priorityEarth", 0);
        current.endingReached                    = vars.bitCheck("priorityEndingME3", 2);
  }
}

start
{
    if (vars.trilogy == 1) {
        return false;
    } else if (vars.trilogy == 2) {
        return (vars.watchers["XPOS"].Old == 1136428027 && vars.watchers["YPOS"].Old == 3338886377 && (vars.watchers["XPOS"].Changed || vars.watchers["YPOS"].Changed) && current.allowSplitting);
    } else if (vars.trilogy == 3) {
        return (vars.watchers["XPOS"].Old == 3343853588 && vars.watchers["YPOS"].Old == 1187251110 && vars.watchers["ZPOS"].Old == 1181715610 && (vars.watchers["XPOS"].Changed || vars.watchers["YPOS"].Changed || vars.watchers["ZPOS"].Changed));
    }
}

isLoading
{
    return vars.trilogy == 1 ? (!vars.watchers["isLoading"].Current || vars.watchers["isLoading2"].Current) : !vars.watchers["isLoading"].Current;
}

split
{
    if (vars.trilogy == 2) {
        return current.allowSplitting && old.allowSplitting && (
	
        // Main story progression
        (settings["escapeLazarus"] && current.lazarusCompleted && !old.lazarusCompleted && !current.FreedomProgressCompleted) ||
        (settings["freedomProgress"] && current.FreedomProgressCompleted && !old.FreedomProgressCompleted) ||
        (settings["horizonCompleted"] && current.horizonCompleted && !old.horizonCompleted) ||
        (settings["collectorShip"] && current.collectorShipCompleted && !old.collectorShipCompleted) ||
        (settings["reaperIFF"] && current.reaperIFFcompleted && !old.reaperIFFcompleted) ||
        (settings["crewAbuct"] && current.crewAbductMissionComplete && !old.crewAbductMissionComplete) || 

        // Suicide Mission
        (settings["ME2Oculus"] && current.suicideOculusDestroyed && !old.suicideOculusDestroyed) ||
        (settings["ME2Valve"] && current.suicideValveCompleted && !old.suicideValveCompleted) ||
        (settings["ME2Bubble"] && current.suicideBubbleCompleted && !old.suicideBubbleCompleted) ||
        (settings["ME2ending"] && current.suicideMissonCompleted && !old.suicideMissonCompleted) ||

        // N7 missions
        (settings["N7_WMF"] && current.N7WMF_completed && !old.N7WMF_completed) ||
        (settings["N7_ARS"] && current.N7ARS_completed && !old.N7ARS_completed) ||
        (settings["N7_ADS"] && current.N7ADS_completed && !old.N7ADS_completed) ||
        (settings["N7_MSVE"] && current.N7MSVE_completed && !old.N7MSVE_completed) ||
        (settings["N7_ESD"] && current.N7ESD_completed && !old.N7ESD_completed) ||
        (settings["N7_ERS"] && current.N7ERS_completed && !old.N7ERS_completed) ||
        (settings["N7_LO"] && current.N7LO_completed && !old.N7LO_completed) ||

        // Dossiers (used to split for Phase 1 of the game and for DLC characters)
        (settings["recruitMordin"] && current.MordinRecruited && !old.MordinRecruited) ||
        (settings["recruitGarrus"] && current.GarrusRecruited && !old.GarrusRecruited) ||
        (settings["acquireGrunt"] && current.GruntTankRecovered && !old.GruntTankRecovered) ||
        (settings["recruitJack"] && current.JackRecruited && !old.JackRecruited) ||
        (settings["recruitZaeed"] && current.ZaeedRecruited && !old.ZaeedRecruited) ||
        (settings["recruitKasumi"] && current.KasumiRecruited && !old.KasumiRecruited) ||

        // Phase 2 Dossiers
        (settings["recruitTali"] && current.TaliRecruited && !old.TaliRecruited) ||
        (settings["recruitSamara"] && current.SamaraRecruited && !old.SamaraRecruited) ||
        (settings["recruitThane"] && current.ThaneRecruited && !old.ThaneRecruited) ||

        // Loyalty missions
        (settings["loyaltyMiranda"] && current.MirandaLoyaltyMissionCompleted && !old.MirandaLoyaltyMissionCompleted) ||
        (settings["loyaltyJacob"] && current.JacobLoyaltyMissionCompleted && !old.JacobLoyaltyMissionCompleted) ||
        (settings["loyaltyJack"] && current.JackLoyaltyMissionCompleted && !old.JackLoyaltyMissionCompleted) ||
        (settings["loyaltyLegion"] && current.LegionLoyaltyMissionCompleted && !old.LegionLoyaltyMissionCompleted) ||
        (settings["loyaltyKasumi"] && current.KasumiLoyaltyMissionCompleted && !old.KasumiLoyaltyMissionCompleted) ||
        (settings["loyaltyGarrus"] && current.GarrusLoyaltyMissionCompleted && !old.GarrusLoyaltyMissionCompleted) ||
        (settings["loyaltyThane"] && current.ThaneLoyaltyMissionCompleted && !old.ThaneLoyaltyMissionCompleted) ||
        (settings["loyaltyTali"] && current.TaliLoyaltyMissionCompleted && !old.TaliLoyaltyMissionCompleted) ||
        (settings["loyaltyMordin"] && current.MordinLoyaltyMissionCompleted && !old.MordinLoyaltyMissionCompleted) ||
        (settings["loyaltyGrunt"] && current.GruntLoyaltyMissionCompleted && !old.GruntLoyaltyMissionCompleted) ||
        (settings["loyaltySamara"] && current.SamaraLoyaltyMissionCompleted && !old.SamaraLoyaltyMissionCompleted) ||
        (settings["loyaltyZaeed"] && current.ZaeedLoyaltyMissionCompleted && !old.ZaeedLoyaltyMissionCompleted)

        );
    }

    if (vars.trilogy == 3) {  
        return (

        // Splits at the completion of each priority mission, according to your personal settings
        (settings["prologue"] && current.prologueEarthCompleted && !old.prologueEarthCompleted) ||
        (settings["priorityMars"] && current.priorityMarsCompleted && !old.priorityMarsCompleted) ||
        (settings["priorityCitadel"] && current.priorityCitadelCompleted && !old.priorityCitadelCompleted) ||
        (settings["priorityPalaven"] && current.priorityPalavenCompleted && !old.priorityPalavenCompleted) ||
        (settings["prioritySurkesh"] && current.prioritySurkeshCompleted && !old.prioritySurkeshCompleted) ||
        (settings["turianPlatoon"] && current.priorityTurianPlatoonCompleted && !old.priorityTurianPlatoonCompleted) ||
        (settings["koganRachni"] && current.priorityKroganRachniCompleted && !old.priorityKroganRachniCompleted) ||
        (settings["priorityTuchanka"] && current.priorityTuchankaCompleted && !old.priorityTuchankaCompleted) ||
        (settings["priorityBeforeThessia"] && current.priorityCerberusCitadelCompleted && !old.priorityCerberusCitadelCompleted) ||
        (settings["priorityGethDreadnought"] && current.priorityGethDreadCompleted && !old.priorityGethDreadCompleted) ||
        (settings["admiralKoris"] && current.priorityKorisCompleted && !old.priorityKorisCompleted) ||
        (settings["gethServer"] && current.priorityGethServerCompleted && !old.priorityGethServerCompleted) ||
        (settings["priorityRannoch"] && current.priorityRannochCompleted && !old.priorityRannochCompleted) ||
        (settings["priorityThessia"] && current.priorityThessiaCompleted && !old.priorityThessiaCompleted) ||
        (settings["priorityHorizon"] && current.priorityHorizonME3Completed && !old.priorityHorizonME3Completed) ||
        (settings["priorityCerberusHQ"] && current.priorityCerberusHQCompleted && !old.priorityCerberusHQCompleted) ||
        (settings["priorityEarth"] && current.priorityEarthCompleted && !old.priorityEarthCompleted) ||
        (settings["priorityEnding"] && current.endingReached && !old.endingReached)
        );
    }
}
