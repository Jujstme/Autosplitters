state("MassEffect1") {}
state("MassEffect2") {}
state("MassEffect3") {}

init
{
    refreshRate = 60;
    int trilogy = 0;

    if (game.Is64Bit())
    {
      switch (memory.ProcessName)
	  {
	    case "MassEffect1" :
	      version = "Mass Effect 1 LE";
		  trilogy = 1;
	  	  break;
		case "MassEffect2" :
		  version = "Mass Effect 2 LE";
		  trilogy = 2;
		  break;
		case "MassEffect3" :
		  version = "Mass Effect 3 LE";
		  trilogy = 3;
		  break;
	  }
    }
	
    var page = modules.First();
    var scanner = new SignatureScanner(game, page.BaseAddress, page.ModuleMemorySize);
    IntPtr ptr = IntPtr.Zero;
    int relativePosition = 0;
	
    switch (trilogy)
    {
      // Signature scanning for Mass Effect 1
      case 1 :
        ptr = scanner.Scan(new SigScanTarget(11,
            "85 C9",             // test ecx,ecx
            "74 0B",             // je MassEffect1.exe+326F85
            "3B D0",             // cmp edx,eax
            "0F 4F C2",          // cmovg eax,edx
            "89 05 ????????",    // mov [MassEffect1.exe+178D1C],eax  <----
            "C3"                 // ret
        ));
        if (ptr == IntPtr.Zero) {
          throw new Exception("Could not find address!");
        }
        relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
        vars.isLoading = new MemoryWatcher<bool>(new DeepPointer(
          relativePosition + game.ReadValue<int>(ptr)
        ));
        break;
	
      // Signature scanning for Mass Effect 2 (same function os ME1)
      case 2 :
        ptr = scanner.Scan(new SigScanTarget(11,
            "85 C9",             // test ecx,ecx
            "74 0B",             // je MassEffect2.exe+481E55
            "3B D0",             // cmp edx,eax
            "0F 4F C2",          // cmovg eax,edx
            "89 05 ????????",    // mov [MassEffect2.exe+175E9C4],eax  <----
            "C3"                 // ret
    	));
        if (ptr == IntPtr.Zero) {
          throw new Exception("Could not find address!");
        }
        relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
        vars.isLoading = new MemoryWatcher<bool>(new DeepPointer(
          relativePosition + game.ReadValue<int>(ptr)
        ));
        break;
	
      // I couldn't find a target for signature scan on Mass Effect 3.
      // For now I am pointing to the address directly.
      // This might break functionality in case the game gets updated
      // as it will require the script to be updated as well.
      // Tested working on ME3 exe version 2.0.0.48602
      case 3 :
        vars.isLoading = new MemoryWatcher<bool>(new DeepPointer(
          page.BaseAddress + 0x179AF10
        ));
        break;
    }
}

update
{
    if (vars.isLoading != null) {
      vars.isLoading.Update(game);
    }
}

isLoading
{
    return (vars.isLoading.Current);
}
