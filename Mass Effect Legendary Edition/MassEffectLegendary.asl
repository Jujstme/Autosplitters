state("MassEffect1") {}
state("MassEffect2") {}
state("MassEffect3") {}

init
{
    if (game.Is64Bit())
    {
      switch (memory.ProcessName)
      {
        case "MassEffect1" :
          version = "Mass Effect 1 LE";
          vars.trilogy = 1;
            break;
        case "MassEffect2" :
          version = "Mass Effect 2 LE";
          vars.trilogy = 2;
          break;
        case "MassEffect3" :
          version = "Mass Effect 3 LE";
          vars.trilogy = 3;
          break;
      }
    }

    var page = modules.First();
    var scanner = new SignatureScanner(game, page.BaseAddress, page.ModuleMemorySize);

    IntPtr ptr = scanner.Scan(new SigScanTarget(4,
        "75 18",             // jne MassEffect1.exe+310FD6           // jne MassEffect2+475742               // jne MassEffect3.exe+480D12
        "8B 0D ????????",    // mov ecx,[MassEffect1.exe+16516B0]    // mov ecx,[MassEffect2.exe+16232F0]    // mov ecx,[MassEffect3.exe+1767AA0]  <----
        "85 C9"              // test ecx,ecx                         // test ecx,ecx                         // test ecx,ecx
    ));
    if (ptr == IntPtr.Zero) throw new Exception("Could not find address!");
    int relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
    vars.isLoading = new MemoryWatcher<bool>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr)));

    // For Mass Effect 1  an additional variable is used for loading messages
    if (vars.trilogy == 1) {
        ptr = scanner.Scan(new SigScanTarget(2,
            "83 3D ???????? 00",  // cmp dword ptr [MassEffect1.exe+17775B8],00  <----
            "74 20",              // je MassEffect1.exe+2596F1
            "48 8B 03"            // mov rax,[rbx]
        ));
        if (ptr == IntPtr.Zero) throw new Exception("Could not find address!");
        relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 5;
        // This value is 1 in load messages, otherwise it's 0
        vars.isLoading2 = new MemoryWatcher<bool>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr)));
    }


    // Mass Effect 2 plot bools for automatic splitting
    if (vars.trilogy == 2) {
        ptr = scanner.Scan(new SigScanTarget(8,
            "48 85 C0",          // test rax,rax
            "74 42",             // je MassEffect2.exe+6DAA15
            "4C 8B 05 ????????"  // mov r8,[MassEffect2.exe+1B675B0]  <----
        ));
        if (ptr == IntPtr.Zero) throw new Exception("Could not find address!");
        relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;	
        vars.watchers = new MemoryWatcherList();

        // Main story progression
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x14A)) { Name = "plotPrologue" }); // Used for prologue mission
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x43)) { Name = "plotCR0" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x27)) { Name = "plotCR123" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0xB3)) { Name = "plotIFF" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x12E)) { Name = "crewAbduct" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0xFE)) { Name = "suicideOculus" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x16F)) { Name = "suicideValve" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x170)) { Name = "suicideBubble" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x1BC)) { Name = "suicideReaper" });

        // Mission tracking
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr) - 0x1B0 , 0xE8, 0x8, 0x68, 0x14, 0x70, 0x5C)) { Name = "missionTracking" });    // MIGHT BREAK

        // Dossiers
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x278)) { Name = "crewAcq1" }); // For Mordin, Jack, Garrus
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x4D)) { Name = "crewAcq2" }); // For Grunt
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x32)) { Name = "crewAcq5" }); // For Zaeed
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0xB9)) { Name = "crewAcq6" }); // For Kasumi


        ptr = scanner.Scan(new SigScanTarget(3,
            "48 8B 0D ????????",    // mov rcx,[MassEffect2.exe+1760010]
            "48 8B 0C F9",          // mov rcx,[rcx+rdi*8]
            "E8 FFC0E6FF"           // call MassEffect2.exe+404600
        ));
        if (ptr == IntPtr.Zero) throw new Exception("Could not find address!");
        relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
        vars.watchers.Add(new MemoryWatcher<uint>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x0, 0x40, 0x118)) { Name = "XPOS" });
        vars.watchers.Add(new MemoryWatcher<uint>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x0, 0x40, 0x11C)) { Name = "YPOS" });
        vars.watchers.Add(new MemoryWatcher<uint>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x0, 0x40, 0x120)) { Name = "ZPOS" });
    }


    // Mass Effect 3 Journal entries for automatic splitting
    if (vars.trilogy == 3) {
        ptr = scanner.Scan(new SigScanTarget(7,
            "48 83 EC 28",          // sub rsp,28
            "48 8B 0D ?? ?? ?? ??", // mov rcx,[MassEffect3.exe+1CBBC70]   <----
            "48 85 C9",             // test rcx,rcx
            "75 1F",                // jne MassEffect3.exe+AD241F
            "48 8D 0D 31C25D00"     // call MassEffect3.exe+AB0400
        ));
        if (ptr == IntPtr.Zero) throw new Exception("Could not find address!");
        relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;	
        vars.watchers = new MemoryWatcherList();

        // Story progression
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x9ED)) { Name = "prologueEarth" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0xA09)) { Name = "priorityMars" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0xA14)) { Name = "priorityCitadel" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x924)) { Name = "priorityPalaven" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x8A9)) { Name = "prioritySurkesh" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x940)) { Name = "preTuchanka" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x8FA)) { Name = "priorityTuchanka" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x983)) { Name = "priorityCitadelCerberus" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x8A9)) { Name = "priorityGethDread" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x934)) { Name = "rannochKoris" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x935)) { Name = "rannochGethServer" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x967)) { Name = "priorityRannoch" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x906)) { Name = "priorityThessia" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x989)) { Name = "priorityHorizonME3" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x9DD)) { Name = "priorityCerberusHead" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0xA70)) { Name = "priorityEarth" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0xAF3)) { Name = "priorityEndingME3" });


        ptr = scanner.Scan(new SigScanTarget(23,
            "0F1F 44 00 00",        // nop dword ptr [rax+rax+00]
            "85 DB",                // test ebx,ebx
            "78 3A",                // js MassEffect3.exe+59A75E
            "3B 1D ?? ?? ?? ??",    // cmp ebx,[MassEffect3.exe+18B41E8]
            "7D 32",                // jnl MassEffect3.exe+599F4E
            "48 63 FB",             // movsxd rdi,ebx
            "48 8B 05 ?? ?? ?? ??"  // mov rax,[MassEffect3.exe+18B4240]  <----
        ));
        if (ptr == IntPtr.Zero) throw new Exception("Could not find address!");
        relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
        vars.watchers.Add(new MemoryWatcher<uint>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x0, 0x40, 0x108)) { Name = "XPOS" });
        vars.watchers.Add(new MemoryWatcher<uint>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x0, 0x40, 0x10C)) { Name = "YPOS" });
        vars.watchers.Add(new MemoryWatcher<uint>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x0, 0x40, 0x110)) { Name = "ZPOS" });
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

    // Mass Effect 2 autosplitting settings
    settings.Add("ME2", true, "Mass Effect 2 - Autosplitting");
    settings.Add("escapeLazarus", true, "Prologue: Awakening", "ME2");
    settings.Add("freedomProgress", true, "Freedom's Progress", "ME2");
    settings.Add("recruitMordin", true, "Dossier: The Professor", "ME2");
    settings.Add("recruitGarrus", true, "Dossier: Archangel", "ME2");
    settings.Add("recruitJack", true, "Dossier: The Convict", "ME2");
    settings.Add("acquireGrunt", true, "Dossier: The Warlord", "ME2");
    settings.Add("horizonCompleted", true, "Horizon", "ME2");
    settings.Add("ME2MissionsBeforeCollectorShip", true, "Missions splitting before unlocking Collector Ship", "ME2");
    settings.Add("collectorShip", true, "Collector ship", "ME2");
    settings.Add("reaperIFF", true, "Reaper IFF", "ME2");
    settings.Add("ME2MissionsBeforeCrewAbduction", true, "Missions splitting before automatic crew abduction event", "ME2");
    settings.Add("crewAbuct", true, "Joker: Crew Abduction", "ME2");
    settings.Add("ME2SuocideMission", true, "Suicide Mission", "ME2");
    settings.Add("ME2Oculus", true, "Oculus", "ME2SuocideMission");
    settings.Add("ME2Valve", true, "Valve", "ME2SuocideMission");
    settings.Add("ME2Bubble", true, "Bubble", "ME2SuocideMission");
    settings.Add("ME2ending", true, "Human Reaper", "ME2SuocideMission");
    settings.Add("DLCcharactersRectuitment", false, "DLC Characters rectuitment", "ME2");
    settings.Add("recruitKasumi", true, "Dossier: The Master Thief", "DLCcharactersRectuitment");
    settings.Add("recruitZaeed", true, "Dossier: The Veteran", "DLCcharactersRectuitment");

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
    settings.Add("priorityEarth", true, "Priority: Earth", "ME3");  // Triggers when you reach the conduit
    settings.Add("priorityEnding", true, "Priority: The Crucible", "ME3");  
}


update
{
  if (vars.isLoading != null) {
    vars.isLoading.Update(game);
  }

  if (vars.trilogy == 1) {
    if (vars.isLoading2 != null) {
      vars.isLoading2.Update(game);
    }
  } else if (vars.trilogy == 2) {
    vars.watchers.UpdateAll(game);

    // Main story progression missions
    current.LazarusCompleted = (vars.watchers["plotPrologue"].Current & (1 << 5)) != 0 && (vars.watchers["plotCR0"].Current & (1 << 1)) == 0 && (vars.watchers["plotCR0"].Old & (1 << 1)) == 0; // Assumes Lazarus completed when the variable for Jack conversation ("TimeHasPassed") flips to 1 before you completed Freedom Progress.
    current.FreedomProgressCompleted = (vars.watchers["plotCR0"].Current & (1 << 1)) != 0;
    current.horizonCompleted = (vars.watchers["plotCR123"].Current & (1 << 0)) != 0;
    current.collectorShipCompleted = (vars.watchers["plotCR123"].Current & (1 << 1)) != 0;
    current.reaperIFFcompleted = (vars.watchers["plotIFF"].Current & (1 << 3)) != 0;
    current.crewAbductMissionComplete = (vars.watchers["crewAbduct"].Current & (1 << 1)) != 0;

    // Missions between Horizon and Collector ship
    // Missions between IFF and Joker
    current.missionTracking = vars.watchers["missionTracking"].Current;

    // Suicide mission
    current.suicideOculusDestroyed = (vars.watchers["suicideOculus"].Current & (1 << 4)) != 0;
    current.suicideValveCompleted = (vars.watchers["suicideValve"].Current & (1 << 5)) != 0;
    current.suicideBubbleCompleted = (vars.watchers["suicideBubble"].Current & (1 << 0)) != 0;
    current.suicideMissonCompleted = (vars.watchers["suicideReaper"].Current & (1 << 3)) != 0 || (vars.watchers["suicideReaper"].Current & (1 << 5)) != 0 || (vars.watchers["suicideReaper"].Current & (1 << 6)) != 0;

    // Recruitment missions Phase 1
    current.MordinRecruited = (vars.watchers["crewAcq1"].Current & (1 << 6)) != 0;
    current.GarrusRecruited = (vars.watchers["crewAcq1"].Current & (1 << 5)) != 0;
    current.JackRecruited = (vars.watchers["crewAcq1"].Current & (1 << 3)) != 0;
    current.GruntTankRecovered = (vars.watchers["crewAcq2"].Current & (1 << 2)) != 0;
    // DLC recruitments
    current.ZaeedRecruited = (vars.watchers["crewAcq5"].Current & (1 << 4)) != 0;
    current.KasumiRecruited = (vars.watchers["crewAcq6"].Current & (1 << 4)) != 0;

  } else if (vars.trilogy == 3) {
    vars.watchers.UpdateAll(game);

    // Story progression
    current.prologueEarthCompleted = (vars.watchers["prologueEarth"].Current & (1 << 1)) != 0;
    current.priorityMarsCompleted = (vars.watchers["prologueEarth"].Current & (1 << 0)) != 0;
    current.priorityCitadelCompleted = (vars.watchers["priorityCitadel"].Current & (1 << 5)) != 0;
    current.priorityPalavenCompleted = (vars.watchers["priorityPalaven"].Current & (1 << 3)) != 0;
    current.prioritySurkeshCompleted = (vars.watchers["prioritySurkesh"].Current & (1 << 7)) != 0;
    current.priorityTurianPlatoonCompleted = (vars.watchers["preTuchanka"].Current & (1 << 2)) != 0;
    current.priorityKroganRachniCompleted = (vars.watchers["preTuchanka"].Current & (1 << 3)) != 0;
    current.priorityTuchankaCompleted = (vars.watchers["priorityTuchanka"].Current & (1 << 4)) != 0;
    current.priorityCerberusCitadelCompleted = (vars.watchers["priorityCitadelCerberus"].Current & (1 << 0)) != 0;
    current.priorityGethDreadCompleted = (vars.watchers["priorityGethDread"].Current & (1 << 5)) != 0;
    current.priorityKorisCompleted = (vars.watchers["rannochKoris"].Current & (1 << 6)) != 0;
    current.priorityGethServerCompleted = (vars.watchers["rannochGethServer"].Current & (1 << 0)) != 0;
    current.priorityRannochCompleted = (vars.watchers["priorityRannoch"].Current & (1 << 6)) != 0;
    current.priorityThessiaCompleted = (vars.watchers["priorityThessia"].Current & (1 << 2)) != 0;
    current.priorityHorizonME3Completed = (vars.watchers["priorityHorizonME3"].Current & (1 << 7)) != 0;
    current.priorityCerberusHQCompleted = (vars.watchers["priorityCerberusHead"].Current & (1 << 2)) != 0;
    current.priorityEarthCompleted = (vars.watchers["priorityEarth"].Current & (1 << 0)) != 0;
    current.endingReached = (vars.watchers["priorityEndingME3"].Current & (1 << 2)) != 0;
  }

}

start
{
  if (vars.trilogy == 1)
  {
    return false;
  } else if (vars.trilogy == 2) {
    return (vars.watchers["XPOS"].Old == 1136428027 && vars.watchers["YPOS"].Old == 3338886377 && vars.watchers["ZPOS"].Old == 1141172634 && (vars.watchers["XPOS"].Changed || vars.watchers["YPOS"].Changed));
  } else if (vars.trilogy == 3) {
    return (vars.watchers["XPOS"].Old == 3343853588 && vars.watchers["YPOS"].Old == 1187251110 && vars.watchers["ZPOS"].Old == 1181715610 && (vars.watchers["XPOS"].Changed || vars.watchers["YPOS"].Changed || vars.watchers["ZPOS"].Changed));
  }
}

isLoading
{
    if (vars.trilogy == 1) {
        return (!vars.isLoading.Current || vars.isLoading2.Current);
    } else {
        return (!vars.isLoading.Current);
    }
}

split
{
  vars.enablesplit = false;

  /////////////////////////////
  // Mass Effect 2 splitting //
  /////////////////////////////
  if (vars.trilogy == 2) {
    // Main story progression
    if (settings["escapeLazarus"] && current.LazarusCompleted && !old.LazarusCompleted) {
      print("Autosplitting: Lazarus completed");
      vars.enablesplit = true;
    } else if (settings["freedomProgress"] && current.FreedomProgressCompleted && !old.FreedomProgressCompleted) {
      print("Autosplitting: Freedom's Progress completed");
      vars.enablesplit = true;
    } else if (settings["horizonCompleted"] && current.horizonCompleted && !old.horizonCompleted) { 
      print("Autosplitting: Horizon completed");
      vars.enablesplit = true;
    } else if (settings["collectorShip"] && current.collectorShipCompleted && !old.collectorShipCompleted) { 
      print("Autosplitting: Collector Ship completed");
      vars.enablesplit = true;
    } else if (settings["reaperIFF"] && current.reaperIFFcompleted && !old.reaperIFFcompleted) { 
      print("Autosplitting: Reaper IFF mission completed");
      vars.enablesplit = true;
    } else if (settings["crewAbuct"] && current.crewAbductMissionComplete && !old.crewAbductMissionComplete) { 
      print("Autosplitting: Joker Crew Abduction mission completed");
      vars.enablesplit = true;
    }

    // Suicide Mission
    if (settings["ME2Oculus"] && current.suicideOculusDestroyed && !old.suicideOculusDestroyed) {
      print("Autosplitting: Suicide Mission - Oculus destroyed");
      vars.enablesplit = true;
    } else if (settings["ME2Valve"] && current.suicideValveCompleted && !old.suicideValveCompleted) {
      print("Autosplitting: Suicide Mission - Valve opened");
      vars.enablesplit = true;
    } else if (settings["ME2Bubble"] && current.suicideBubbleCompleted && !old.suicideBubbleCompleted) {
      print("Autosplitting: Suicide Mission - Biotic bubble section passed");
      vars.enablesplit = true;
    } else if (settings["ME2ending"] && current.suicideMissonCompleted && !old.suicideMissonCompleted) {
      print("Autosplitting: Suicide Mission completed");
      vars.enablesplit = true;
    }

    // Missions before collector ship (5 are required, this script will split after every mission)
    if (settings["ME2MissionsBeforeCollectorShip"] && current.horizonCompleted && !current.collectorShipCompleted) {
      if (current.missionTracking == old.missionTracking + 1) {
        print("Autosplitting: Mission completed");
        vars.enablesplit = true;
      }
    }

    // Missions after IFF acquisition, before crew abduction (up to 3 after IFF). Will split after every mission completed
    if (settings["ME2MissionsBeforeCrewAbduction"] && current.reaperIFFcompleted && !current.crewAbductMissionComplete) {
      if (current.missionTracking == old.missionTracking + 1) {
        print("Autosplitting: Mission completed");
        vars.enablesplit = true;
      }
    }

    // Dossiers (used to split for Phase 1 of the game and for DLC characters)
    if (settings["recruitMordin"] && current.MordinRecruited && !old.MordinRecruited) {
      print("Autosplitting: Mordin recruited");
      vars.enablesplit = true;
    } else if (settings["recruitGarrus"] && current.GarrusRecruited && !old.GarrusRecruited) {
      print("Autosplitting: Garrus recruited");
      vars.enablesplit = true;
    } else if (settings["acquireGrunt"] && current.GruntTankRecovered && !old.GruntTankRecovered) {
      print("Autosplitting: Grunt's tank recovered");
      vars.enablesplit = true;
    } else if (settings["recruitJack"] && current.JackRecruited && !old.JackRecruited) {
      print("Autosplitting: Jack recruited");
      vars.enablesplit = true;
    } else if (settings["recruitZaeed"] && current.ZaeedRecruited && !old.ZaeedRecruited) {
      print("Autosplitting: Zaeed recruited");
      vars.enablesplit = true;
    } else if (settings["recruitKasumi"] && current.KasumiRecruited && !old.KasumiRecruited) {
      print("Autosplitting: Kasumi recruited");
      vars.enablesplit = true;
    }
  }


  /////////////////////////////
  // Mass Effect 3 splitting //
  ///////////////////////////// 
  if (vars.trilogy == 3) {  
      if (settings["prologue"] && current.prologueEarthCompleted && !old.prologueEarthCompleted) {
        print("Autosplitting: Prologue (Earth) completed");
        vars.enablesplit = true;
      } else if (settings["priorityMars"] && current.priorityMarsCompleted && !old.priorityMarsCompleted) {
        print("Autosplitting: Priority Mars completed");
        vars.enablesplit = true;
      } else if (settings["priorityCitadel"] && current.priorityCitadelCompleted && !old.priorityCitadelCompleted) {
        print("Autosplitting: Priority Citadel completed");
        vars.enablesplit = true;
      } else if (settings["priorityPalaven"] && current.priorityPalavenCompleted && !old.priorityPalavenCompleted) {
        print("Autosplitting: Priority Palaven completed");
        vars.enablesplit = true;
      } else if (settings["prioritySurkesh"] && current.prioritySurkeshCompleted && !old.prioritySurkeshCompleted) {
        print("Autosplitting: Priority Sur'Kesh completed");
        vars.enablesplit = true;
      } else if (settings["turianPlatoon"] && current.priorityTurianPlatoonCompleted && !old.priorityTurianPlatoonCompleted) {
        print("Autosplitting: Tuchanka Turian Platoon completed");
        vars.enablesplit = true;
      } else if (settings["koganRachni"] && current.priorityKroganRachniCompleted && !old.priorityKroganRachniCompleted) {
        print("Autosplitting: Krogan Attical Traverse completed");
        vars.enablesplit = true;
      } else if (settings["priorityTuchanka"] && current.priorityTuchankaCompleted && !old.priorityTuchankaCompleted) {
        print("Autosplitting: Priority Tuchanka completed");
        vars.enablesplit = true;
      } else if (settings["priorityBeforeThessia"] && current.priorityCerberusCitadelCompleted && !old.priorityCerberusCitadelCompleted) {
        print("Autosplitting: Citadel Cerberus Attack completed");
        vars.enablesplit = true;
      } else if (settings["priorityGethDreadnought"] && current.priorityGethDreadCompleted && !old.priorityGethDreadCompleted) {
        print("Autosplitting: Priority Geth Dreadnought completed");
        vars.enablesplit = true;
      } else if (settings["admiralKoris"] && current.priorityKorisCompleted && !old.priorityKorisCompleted) {
        print("Autosplitting: Rannoch Admiral Koris completed");
        vars.enablesplit = true;
      } else if (settings["gethServer"] && current.priorityGethServerCompleted && !old.priorityGethServerCompleted) {
        print("Autosplitting: Rannoch Geth Fighter Squadrons completed");
        vars.enablesplit = true;
      } else if (settings["priorityRannoch"] && current.priorityRannochCompleted && !old.priorityRannochCompleted) {
        print("Autosplitting: Priority Rannoch completed");
        vars.enablesplit = true;
      } else if (settings["priorityThessia"] && current.priorityThessiaCompleted && !old.priorityThessiaCompleted) {
        print("Autosplitting: Priority Thessia completed");
        vars.enablesplit = true;
      } else if (settings["priorityHorizon"] && current.priorityHorizonME3Completed && !old.priorityHorizonME3Completed) {
        print("Autosplitting: Priority Horizon completed");
        vars.enablesplit = true;
      } else if (settings["priorityCerberusHQ"] && current.priorityCerberusHQCompleted && !old.priorityCerberusHQCompleted) {
        print("Autosplitting: Priority Cerberus Headquarters completed");
        vars.enablesplit = true;
      } else if (settings["priorityEarth"] && current.priorityEarthCompleted && !old.priorityEarthCompleted) {
        print("Autosplitting: Priority Earth completed");
        vars.enablesplit = true;
      } else if (settings["priorityEnding"] && current.endingReached && !old.endingReached) {
        print("Autosplitting: Game complete");
        vars.enablesplit = true;
      }
  }

  return vars.enablesplit;
}

exit
{
    timer.IsGameTimePaused = true;
}
