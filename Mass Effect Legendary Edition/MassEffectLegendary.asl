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
    }
	
    if (vars.trilogy == 3) {
      vars.watchers.UpdateAll(game);
    }

}

start
{
  if (vars.trilogy == 1 || vars.trilogy == 2)
  {
    return false;
  } else if (vars.trilogy == 3) {
    if (vars.watchers["XPOS"].Old == 3343853588 && vars.watchers["YPOS"].Old == 1187251110 && vars.watchers["ZPOS"].Old == 1181715610 && (vars.watchers["XPOS"].Changed || vars.watchers["YPOS"].Changed || vars.watchers["ZPOS"].Changed)) {
      return true;
    }
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
