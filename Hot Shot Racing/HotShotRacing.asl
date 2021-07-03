// IGT timer autosplitter for Hot Shot Racing
// Coding: Jujstme
// Version: 1.2
// In case of bugs, please contact me at just.tribe@gmail.com

state("HotshotRacing") {}

init
{
    var page = modules.First();
    var scanner = new SignatureScanner(game, page.BaseAddress, page.ModuleMemorySize);

    IntPtr ptr = scanner.Scan(new SigScanTarget(3,
        "48 8B 0D ????????", // mov rcx,[HotshotRacing.exe+1317D18]  <----
        "48 85 C9",          // test rcx,rcx
        "74 08",             // je HotshotRacing.exe+E7343
        "0F28 CE",           // movaps xmm1,xmm6
        "E8 ????????",       // call HotshotRacing.exe+E76E0
        "48 89 74 24 50"     // mov [rsp+50],rsi
    ));
    if (ptr == IntPtr.Zero) {
      throw new Exception("Could not find address!");
    }
    int relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
    vars.runstart = new MemoryWatcher<float>(new DeepPointer(
      relativePosition + game.ReadValue<int>(ptr), 0x2A8
    ));
	
    ptr = scanner.Scan(new SigScanTarget(10,
        "74 06",            // je HotshotRacing.exe+E7548
        "83 E3 F7",         // and ebx,-09
        "89 5F 10",         // mov [rdi+10],ebx
        "8B 0D ????????"    // mov ecx,[HotshotRacing.exe+1317CAC]  <----
    ));
    if (ptr == IntPtr.Zero) {
      throw new Exception("Could not find address!");
    }
    relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
    vars.racestatus = new MemoryWatcher<byte>(new DeepPointer(
      relativePosition + game.ReadValue<int>(ptr)
    ));

    ptr = scanner.Scan(new SigScanTarget(2,
        "89 1D ????????",     // mov [HotshotRacing.exe+1317F0C],ebx  <----
        "48 8B 0D ????????",  // mov rcx,[HotshotRacing.exe+1317D00]
        "48 8B 01"            // mov rax,[rcx]
    ));
    if (ptr == IntPtr.Zero) {
      throw new Exception("Could not find address!");
    }
    relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
    vars.racecompleted = new MemoryWatcher<byte>(new DeepPointer(
      relativePosition + game.ReadValue<int>(ptr)
    ));

    ptr = scanner.Scan(new SigScanTarget(3,
        "48 8B 05 ????????",    // mov rax,[HotshotRacing.exe+1317CD0]  <----
        "F3 0F10 40 04",        // movss xmm0,[rax+04]
        "C3"                    // ret
    ));
    if (ptr == IntPtr.Zero) {
      throw new Exception("Could not find address!");
    }
    relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
    vars.igt = new MemoryWatcher<float>(new DeepPointer(
      relativePosition + game.ReadValue<int>(ptr), 0x4
    ));

    ptr = scanner.Scan(new SigScanTarget(5,
        "8B F7",                  // mov mov esi,edi
        "48 83 3D ???????? 00",   // cmp qword ptr [HotshotRacing.exe+1317C80],00  <----
        "75 41"                   // jne HotshotRacing.exe+D96A1
    ));
    if (ptr == IntPtr.Zero) {
      throw new Exception("Could not find address!");
    }
    relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 5;
    vars.totalracetime = new MemoryWatcher<float>(new DeepPointer(
      relativePosition + game.ReadValue<int>(ptr), 0x0, 0xE8, 0x34
    ));

    ptr = scanner.Scan(new SigScanTarget(2,
        "8B 15 ????????",     // mov edx,[HotshotRacing.exe+13191C8]  <----
        "48 8B CB",           // mov rcx,rbx
        "83 3D ???????? 02"   // cmp dword ptr [HotshotRacing.exe+130D604],02
    ));
    if (ptr == IntPtr.Zero) {
      throw new Exception("Could not find address!");
    }
    relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
    vars.trackorder = new MemoryWatcher<byte>(new DeepPointer(
      relativePosition + game.ReadValue<int>(ptr)
    ));
  
}

startup
{
  vars.totaligt = 0;
  vars.progressIGT = 0;

  settings.Add("StartTime", false, "Start the timer on the \"3\" at the countdown");
  settings.SetToolTip("StartTime", "If enabled, LiveSplit will start the timer when the \"3\" appears during the countdown on the first race.\nIf disabled, LiveSplit will start the timer at the start of the first race.\n\nDefault: disabled");
  settings.Add("GPsplit", false, "Split only at the final race of each Grand Prix");
  settings.SetToolTip("GPsplit", "If enabled, LiveSplit will trigger a split only upon completion of a Grand Prix.\nIf disabled, LiveSplit will trigger a split at the completion of each race.\n\nDefault: disabled");
}

start
{
  // Reset the variables if you reset a run
  vars.totaligt = 0;
  vars.progressIGT = 0;
    
  if (settings["StartTime"]) {
    return (vars.runstart.Current >= 2 && vars.igt.Current == 0 && vars.racestatus.Current == 3 && vars.trackorder.Current == 0); 
  } else {
    return (vars.igt.Old == 0 && vars.igt.Current != 0 && vars.trackorder.Current == 0);
  }
}


update
{
    if (vars.runstart != null) {
	  vars.runstart.Update(game);
	  vars.racestatus.Update(game);
	  vars.racecompleted.Update(game);
	  vars.igt.Update(game);
	  vars.totalracetime.Update(game);
	  vars.trackorder.Update(game);
	}

    // During a race, the IGT is calculated by the game and is added to the total
    if (vars.racecompleted.Current == 0)  {
			
      // If you restart an event or a race, the IGT of the failed race is still considered and added
      if (vars.igt.Old != 0 && vars.igt.Current == 0 && vars.racestatus.Old == 4) {
        vars.totaligt = vars.igt.Old + vars.totaligt;
        vars.progressIGT = vars.totaligt;
      }
      else
      {
        vars.progressIGT = vars.igt.Current + vars.totaligt;
      }
    }

    // How to behave the moment you complete a race:
    if (vars.racecompleted.Current == 1 && vars.racecompleted.Current.Old == 0)
    {
      vars.totaligt = (Math.Truncate(1000 * (vars.totalracetime.Current + vars.totaligt)) / 1000);
      vars.progressIGT = vars.totaligt;
    }
}

gameTime
{
  return TimeSpan.FromSeconds((double)vars.progressIGT);
}

split
{
  // Split automatically once you reach the finish line at the end of each track
  if (settings["GPsplit"]) {
    return (vars.trackorder.Current == 4 && vars.racecompleted.Current == 1 && vars.racecompleted.Old == 0);
  }
  else
  {
    return (vars.racecompleted.Current == 1 && vars.racecompleted.Old == 0);
  }
}

isLoading
{
  return true;
}
