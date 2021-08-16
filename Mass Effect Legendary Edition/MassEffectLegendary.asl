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
    if (ptr == IntPtr.Zero) {
      throw new Exception("Could not find address!");
    }
    int relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
    vars.isLoading = new MemoryWatcher<bool>(new DeepPointer(
      relativePosition + game.ReadValue<int>(ptr)
    ));

    // For Mass Effect 1  an additional variable is used for loading messages
    if (vars.trilogy == 1) {
        ptr = scanner.Scan(new SigScanTarget(2,
            "83 3D ???????? 00",  // cmp dword ptr [MassEffect1.exe+17775B8],00  <----
            "74 20",              // je MassEffect1.exe+2596F1
            "48 8B 03"            // mov rax,[rbx]
        ));
        if (ptr == IntPtr.Zero) {
          throw new Exception("Could not find address!");
        }
        relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 5;
        // This value is 1 in load messages, otherwise it's 0
        vars.isLoading2 = new MemoryWatcher<bool>(new DeepPointer(
          relativePosition + game.ReadValue<int>(ptr)
        ));
    }


    // Mass Effect 2 plot bools for automatic splitting
    if (vars.trilogy == 2) {
        ptr = scanner.Scan(new SigScanTarget(8,
            "48 85 C0",          // test rax,rax
            "74 42",             // je MassEffect2.exe+6DAA15
            "4C 8B 05 ????????"  // mov r8,[MassEffect2.exe+1B675B0]  <----
        ));
        if (ptr == IntPtr.Zero) {
          throw new Exception("Could not find address!");
        }
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
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x278)) { Name = "crewAcq1" }); // For Mordin, Jack, Garrus, Tali
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x4D)) { Name = "crewAcq2" }); // For Grunt
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x279)) { Name = "crewAcq3" }); // For Thane
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x47)) { Name = "crewAcq4" }); // For Samara
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x32)) { Name = "crewAcq5" }); // For Zaeed
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0xB9)) { Name = "crewAcq6" }); // For Kasumi

        // Data for loyalty missions and loyalty status for each squadmate
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x16)) { Name = "loyaltyStatus1" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x17)) { Name = "loyaltyStatus2" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0x18)) { Name = "loyaltyStatus3" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0xBB)) { Name = "loyaltyMissions1" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x16C, 0xA34, 0x60, 0xBC)) { Name = "loyaltyMissions2" });

        ptr = scanner.Scan(new SigScanTarget(3,
            "48 8B 0D ????????",    // mov rcx,[MassEffect2.exe+1760010]
            "48 8B 0C F9",          // mov rcx,[rcx+rdi*8]
            "E8 FFC0E6FF"           // call MassEffect2.exe+404600
        ));
        if (ptr == IntPtr.Zero) {
          throw new Exception("Could not find address!");
        }
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
        if (ptr == IntPtr.Zero) {
          throw new Exception("Could not find address!");
        }
        relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;	
        vars.watchers = new MemoryWatcherList();
		
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x9ED)) { Name = "plotData1" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0xA09)) { Name = "plotData2" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0xA0A)) { Name = "plotData3" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x8A2)) { Name = "plotData4" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0xAF4)) { Name = "plotData5" });
     // vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0xAF5)) { Name = "plotData6" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x940)) { Name = "plotData7" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x8FA)) { Name = "plotData8" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x983)) { Name = "plotData9" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x8A9)) { Name = "plotData10" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0xAF8)) { Name = "plotData11" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x967)) { Name = "plotData12" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0xAF9)) { Name = "plotData13" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0xAFE)) { Name = "plotData14" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0x9DD)) { Name = "plotData15" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0xA70)) { Name = "plotData16" });
        vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(relativePosition + game.ReadValue<int>(ptr), 0x13C, 0xF0, 0xAF3)) { Name = "plotData17" });


        ptr = scanner.Scan(new SigScanTarget(23,
            "0F1F 44 00 00",        // nop dword ptr [rax+rax+00]
            "85 DB",                // test ebx,ebx
            "78 3A",                // js MassEffect3.exe+59A75E
            "3B 1D ?? ?? ?? ??",    // cmp ebx,[MassEffect3.exe+18B41E8]
            "7D 32",                // jnl MassEffect3.exe+599F4E
            "48 63 FB",             // movsxd rdi,ebx
            "48 8B 05 ?? ?? ?? ??"  // mov rax,[MassEffect3.exe+18B4240]  <----
        ));
        if (ptr == IntPtr.Zero) {
          throw new Exception("Could not find address!");
        }
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
//  settings.Add("ME2OptionalDossiers", true, "Optional Dossiers", "ME2");
//  settings.Add("recruitThane", true, "Dossier: The Assassin", "ME2OptionalDossiers");
//  settings.Add("recruitSamara", true, "Dossier: The Justicar", "ME2OptionalDossiers");
//  settings.Add("recruitTali", true, "Dossier: Tali", "ME2OptionalDossiers");
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
//  settings.Add("ME2LoyaltyMissions", true, "Loyalty Missions", "ME2");
//  settings.Add("loyaltyMiranda", true, "Miranda", "ME2LoyaltyMissions");
//  settings.Add("loyaltyJacob", true, "Jacob", "ME2LoyaltyMissions");
//  settings.Add("loyaltyJack", true, "Jack", "ME2LoyaltyMissions");
//  settings.Add("loyaltyLegion", true, "Legion", "ME2LoyaltyMissions");
//  settings.Add("loyaltyKasumi", true, "Kasumi", "ME2LoyaltyMissions");
//  settings.Add("loyaltyGarrus", true, "Garrus", "ME2LoyaltyMissions");
//  settings.Add("loyaltyThane", true, "Thane", "ME2LoyaltyMissions");
//  settings.Add("loyaltyTali", true, "Tali", "ME2LoyaltyMissions");
//  settings.Add("loyaltyMordin", true, "Mordin", "ME2LoyaltyMissions");
//  settings.Add("loyaltyGrunt", true, "Grunt", "ME2LoyaltyMissions");
//  settings.Add("loyaltySamara", true, "Samara", "ME2LoyaltyMissions");
//  settings.Add("loyaltyZaeed", true, "Zaeed", "ME2LoyaltyMissions");

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
    // Recruitment missions Phase 2
    current.TaliRecruited = (vars.watchers["crewAcq1"].Current & (1 << 7)) != 0;
    current.ThaneRecruited = (vars.watchers["crewAcq3"].Current & (1 << 1)) != 0;
    current.SamaraRecruited = (vars.watchers["crewAcq4"].Current & (1 << 4)) != 0;
    // DLC recruitments
    current.ZaeedRecruited = (vars.watchers["crewAcq5"].Current & (1 << 4)) != 0;
    current.KasumiRecruited = (vars.watchers["crewAcq6"].Current & (1 << 4)) != 0;

    // Loyalty missions
    current.MirandaLoyaltyMissionCompleted = (vars.watchers["loyaltyMissions1"].Current & (1 << 0)) != 0;
    current.JacobLoyaltyMissionCompleted = (vars.watchers["loyaltyMissions1"].Current & (1 << 1)) != 0;
    current.JackLoyaltyMissionCompleted = (vars.watchers["loyaltyMissions1"].Current & (1 << 2)) != 0;
    current.LegionLoyaltyMissionCompleted = (vars.watchers["loyaltyMissions1"].Current & (1 << 3)) != 0;
    current.KasumiLoyaltyMissionCompleted = (vars.watchers["loyaltyMissions1"].Current & (1 << 4)) != 0;
    current.GarrusLoyaltyMissionCompleted = (vars.watchers["loyaltyMissions1"].Current & (1 << 5)) != 0;
    current.ThaneLoyaltyMissionCompleted = (vars.watchers["loyaltyMissions1"].Current & (1 << 6)) != 0;
    current.TaliLoyaltyMissionCompleted = (vars.watchers["loyaltyMissions1"].Current & (1 << 7)) != 0;
    current.MordinLoyaltyMissionCompleted = (vars.watchers["loyaltyMissions2"].Current & (1 << 0)) != 0;
    current.GruntLoyaltyMissionCompleted = (vars.watchers["loyaltyMissions2"].Current & (1 << 1)) != 0;
    current.SamaraLoyaltyMissionCompleted = (vars.watchers["loyaltyMissions2"].Current & (1 << 2)) != 0;
    current.ZaeedLoyaltyMissionCompleted = (vars.watchers["loyaltyMissions2"].Current & (1 << 3)) != 0;

    // Loyalty status
    current.MirandaIsLoyal = (vars.watchers["loyaltyStatus1"].Current & (1 << 1)) != 0;
    current.JacobIsLoyal = (vars.watchers["loyaltyStatus1"].Current & (1 << 2)) != 0;
    current.JackIsLoyal = (vars.watchers["loyaltyStatus1"].Current & (1 << 3)) != 0;
    current.LegionIsLoyal = (vars.watchers["loyaltyStatus1"].Current & (1 << 4)) != 0;
    current.KasumiIsLoyal = (vars.watchers["loyaltyStatus1"].Current & (1 << 6)) != 0;
    current.GarrusIsLoyal = (vars.watchers["loyaltyStatus1"].Current & (1 << 7)) != 0;
    current.ThaneIsLoyal = (vars.watchers["loyaltyStatus2"].Current & (1 << 1)) != 0;
    current.TaliIsLoyal = (vars.watchers["loyaltyStatus2"].Current & (1 << 2)) != 0;
    current.MordinIsLoyal = (vars.watchers["loyaltyStatus2"].Current & (1 << 4)) != 0;
    current.GruntIsLoyal = (vars.watchers["loyaltyStatus2"].Current & (1 << 5)) != 0;
    current.SamaraIsLoyal = (vars.watchers["loyaltyStatus2"].Current & (1 << 7)) != 0;
    current.ZaeedIsLoyal = (vars.watchers["loyaltyStatus3"].Current & (1 << 0)) != 0;
  } else if (vars.trilogy == 3) {
    vars.watchers.UpdateAll(game);
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

    // 5 missions before collector ship
    if (settings["ME2MissionsBeforeCollectorShip"] && current.horizonCompleted && !current.collectorShipCompleted) {
      if (current.missionTracking == old.missionTracking + 1) {
        print("Autosplitting: Mission completed");
        vars.enablesplit = true;
      }
    }

    // Up to 3 after IFF before Joker
    if (settings["ME2MissionsBeforeCrewAbduction"] && current.reaperIFFcompleted && !current.crewAbductMissionComplete) {
      if (current.missionTracking == old.missionTracking + 1) {
        print("Autosplitting: Mission completed");
        vars.enablesplit = true;
      }
    }

    // Dossiers
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
    // Commented out unnecessary recruitment missions.
    // Left them here in case of future needs.
//  else if (settings["recruitTali"] && current.TaliRecruited && !old.TaliRecruited) {
//    print("Autosplitting: Tali recruited");
//    vars.enablesplit = true;
//  } else if (settings["recruitSamara"] && current.SamaraRecruited && !old.SamaraRecruited) {
//    print("Autosplitting: Samara recruited");
//    vars.enablesplit = true;
//  } else if (settings["recruitThane"] && current.ThaneRecruited && !old.ThaneRecruited) {
//    print("Autosplitting: Thane recruited");
//    vars.enablesplit = true;
//  }

    // Split after each loyalty mission, provided you completed it successfully AND secured your ally's loyalty
    // That means, for example, that completing Tali's mission but having her exiled will not secure her loyalty, so the script will not split.
    // This DOES NOT take into account the possibility of losing an ally's loyalty later on during confrontations.
//    if (settings["loyaltyMiranda"] && current.MirandaIsLoyal && current.MirandaLoyaltyMissionCompleted && !old.MirandaLoyaltyMissionCompleted) {
//      print("Autosplitting: Miranda Loyalty mission completed");
//      vars.enablesplit = true;
//    } else if (settings["loyaltyJacob"] && current.JacobIsLoyal && current.JacobLoyaltyMissionCompleted && !old.JacobLoyaltyMissionCompleted) {
//      print("Autosplitting: Jacob Loyalty mission completed");
//      vars.enablesplit = true;
//    } else if (settings["loyaltyJack"] && current.JackIsLoyal && current.JackLoyaltyMissionCompleted && !old.JackLoyaltyMissionCompleted) {
//      print("Autosplitting: Jack Loyalty mission completed");
//      vars.enablesplit = true;
//    } else if (settings["loyaltyLegion"] && current.LegionIsLoyal && current.LegionLoyaltyMissionCompleted && !old.LegionLoyaltyMissionCompleted) {
//      print("Autosplitting: Legion Loyalty mission completed");
//      vars.enablesplit = true;
//    } else if (settings["loyaltyKasumi"] && current.KasumiIsLoyal && current.KasumiLoyaltyMissionCompleted && !old.KasumiLoyaltyMissionCompleted) {
//      print("Autosplitting: Kasumi Loyalty mission completed");
//      vars.enablesplit = true;
//    } else if (settings["loyaltyGarrus"] && current.GarrusIsLoyal && current.GarrusLoyaltyMissionCompleted && !old.GarrusLoyaltyMissionCompleted) {
//      print("Autosplitting: Garrus Loyalty mission completed");
//      vars.enablesplit = true;
//    } else if (settings["loyaltyThane"] && current.ThaneIsLoyal && current.ThaneLoyaltyMissionCompleted && !old.ThaneLoyaltyMissionCompleted) {
//      print("Autosplitting: Thane Loyalty mission completed");
//      vars.enablesplit = true;
//    } else if (settings["loyaltyTali"] && current.TaliIsLoyal && current.TaliLoyaltyMissionCompleted && !old.TaliLoyaltyMissionCompleted) {
//      print("Autosplitting: Tali Loyalty mission completed");
//      vars.enablesplit = true;
//    } else if (settings["loyaltyMordin"] && current.MordinIsLoyal && current.MordinLoyaltyMissionCompleted && !old.MordinLoyaltyMissionCompleted) {
//      print("Autosplitting: Mordin Loyalty mission completed");
//      vars.enablesplit = true;
//    } else if (settings["loyaltyGrunt"] && current.GruntIsLoyal && current.GruntLoyaltyMissionCompleted && !old.GruntLoyaltyMissionCompleted) {
//      print("Autosplitting: Grunt Loyalty mission completed");
//      vars.enablesplit = true;
//    } else if (settings["loyaltySamara"] && current.SamaraIsLoyal && current.SamaraLoyaltyMissionCompleted && !old.SamaraLoyaltyMissionCompleted) {
//      print("Autosplitting: Samara / Morinth Loyalty mission completed");
//      vars.enablesplit = true;
//    } else if (settings["loyaltyZaeed"] && current.ZaeedIsLoyal && current.ZaeedLoyaltyMissionCompleted && !old.ZaeedLoyaltyMissionCompleted) {
//      print("Autosplitting: Zaeed Loyalty mission completed");
//      vars.enablesplit = true;
//    }
  }
    
  if (vars.trilogy == 3) {  
    if (settings["prologue"] && (vars.watchers["plotData1"].Current & (1 << 1)) != 0  && (vars.watchers["plotData1"].Old & (1 << 1)) == 0) vars.enablesplit = true;
    if (settings["priorityMars"] && (vars.watchers["plotData2"].Current & (1 << 0)) != 0  && (vars.watchers["plotData2"].Old & (1 << 0)) == 0) vars.enablesplit = true;
    if (settings["priorityCitadel"] && (vars.watchers["plotData3"].Current & (1 << 1)) != 0  && (vars.watchers["plotData3"].Old & (1 << 1)) == 0) vars.enablesplit = true;
    if (settings["priorityPalaven"] && (vars.watchers["plotData4"].Current & (1 << 7)) != 0  && (vars.watchers["plotData4"].Old & (1 << 7)) == 0) vars.enablesplit = true;  
    if (settings["prioritySurkesh"] && (vars.watchers["plotData5"].Current & (1 << 4)) != 0  && (vars.watchers["plotData5"].Old & (1 << 4)) == 0) vars.enablesplit = true;
    if (settings["turianPlatoon"] && (vars.watchers["plotData7"].Current & (1 << 2)) != 0  && (vars.watchers["plotData7"].Old & (1 << 2)) == 0) vars.enablesplit = true;
    if (settings["koganRachni"] && (vars.watchers["plotData7"].Current & (1 << 3)) != 0  && (vars.watchers["plotData7"].Old & (1 << 3)) == 0) vars.enablesplit = true;
    if (settings["priorityTuchanka"] && (vars.watchers["plotData8"].Current & (1 << 4)) != 0  && (vars.watchers["plotData8"].Old & (1 << 4)) == 0) vars.enablesplit = true;
    if (settings["priorityBeforeThessia"] && (vars.watchers["plotData9"].Current & (1 << 0)) != 0  && (vars.watchers["plotData9"].Old & (1 << 0)) == 0) vars.enablesplit = true;
    if (settings["priorityGethDreadnought"] && (vars.watchers["plotData10"].Current & (1 << 5)) != 0  && (vars.watchers["plotData10"].Old & (1 << 5)) == 0) vars.enablesplit = true;
    if (settings["admiralKoris"] && (vars.watchers["plotData11"].Current & (1 << 6)) != 0  && (vars.watchers["plotData11"].Old & (1 << 6)) == 0) vars.enablesplit = true;
    if (settings["gethServer"] && (vars.watchers["plotData11"].Current & (1 << 5)) != 0  && (vars.watchers["plotData11"].Old & (1 << 5)) == 0) vars.enablesplit = true;
    if (settings["priorityRannoch"] && (vars.watchers["plotData12"].Current & (1 << 6)) != 0  && (vars.watchers["plotData12"].Old & (1 << 6)) == 0) vars.enablesplit = true;
    if (settings["priorityThessia"] && (vars.watchers["plotData13"].Current & (1 << 6)) != 0  && (vars.watchers["plotData13"].Old & (1 << 6)) == 0) vars.enablesplit = true;
    if (settings["priorityHorizon"] && (vars.watchers["plotData14"].Current & (1 << 6)) != 0  && (vars.watchers["plotData14"].Old & (1 << 6)) == 0) vars.enablesplit = true;
    if (settings["priorityCerberusHQ"] && (vars.watchers["plotData15"].Current & (1 << 2)) != 0  && (vars.watchers["plotData15"].Old & (1 << 2)) == 0) vars.enablesplit = true;
    if (settings["priorityEarth"] && (vars.watchers["plotData16"].Current & (1 << 0)) != 0  && (vars.watchers["plotData16"].Old & (1 << 0)) == 0) vars.enablesplit = true;
    if (settings["priorityEnding"] && (vars.watchers["plotData17"].Current & (1 << 2)) != 0  && (vars.watchers["plotData17"].Old & (1 << 2)) == 0) vars.enablesplit = true;
  }

  return vars.enablesplit;
}

exit
{
    timer.IsGameTimePaused = true;
}
