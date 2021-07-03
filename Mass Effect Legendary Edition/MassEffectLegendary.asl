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
}

isLoading
{
    if (vars.trilogy == 1) {
        return (!vars.isLoading.Current || vars.isLoading2.Current);
    } else {
        return (!vars.isLoading.Current);
    }
}

exit
{
    timer.IsGameTimePaused = true;
}
