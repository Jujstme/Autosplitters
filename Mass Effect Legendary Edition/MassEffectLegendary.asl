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
	
      // Largely untested target for signature scan on Mass Effect 3.
      // This might break functionality in case the game gets updated
      // as it might require the script to be updated as well.
      // Tested working on ME3 exe version 2.0.0.48602
      case 3 :
        ptr = scanner.Scan(new SigScanTarget(12,
	    "66 0F1F 84 00 00000000",    // word ptr [rax+rax+00000000]
            "48 8B 05 ????????",         // mov rax,[MassEffect3.exe+18B41B0]  <----
            "48 8B 1C 06",               // mov rbx,[rsi+rax]
            "48 8B 03"                   // mov rax,[rbx]
    	));
        if (ptr == IntPtr.Zero) {
          throw new Exception("Could not find address!");
        }
        relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
        vars.isLoading = new MemoryWatcher<bool>(new DeepPointer(
          relativePosition + game.ReadValue<int>(ptr), 0x0, 0xA0
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
