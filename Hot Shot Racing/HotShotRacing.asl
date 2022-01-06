// IGT timer autosplitter for Hot Shot Racing
// Coding: Jujstme
// Version: 1.3
// In case of bugs, please contact me at just.tribe@gmail.com

state("HotshotRacing") {}

startup
{
    string[,] Settings =
    {
        { null, "StartTime", "Start the timer on the \"3\" at the countdown", "If enabled, LiveSplit will start the timer when the \"3\" appears during the countdown on the first race.\nIf disabled, LiveSplit will start the timer at the start of the first race.\n\nDefault: disabled", "false"},

        { null, "autosplitting", "Autosplitting", null, "true" },

        { "autosplitting", "theTour", "GP 1 - The Tour", null, "true" },
            { "theTour", "theMarina", "The Marina", null, "true" },
            { "theTour", "area41", "Area 41", null, "true" },
            { "theTour", "templeDrive", "Temple Drive", null, "true" },
            { "theTour", "castleFunfair", "Castle Funfair", null, "true" },

        { "autosplitting", "proCircuit", "GP 2 - Pro Circuit", null, "true" },
            { "proCircuit", "boneyard", "Boneyard", null, "true" },
            { "proCircuit", "fossilCave", "Fossil Cave", null, "true" },
            { "proCircuit", "oceanWorld", "Ocean World", null, "true" },
            { "proCircuit", "royalRoadway", "Royal Roadway", null, "true" },

        { "autosplitting", "racingElite", "GP 3 - Racing Elite", null, "true" },
            { "racingElite", "dinoDash", "Dino Dash", null, "true" },
            { "racingElite", "heatedHighway", "Heated Highway", null, "true" },
            { "racingElite", "alpineTown", "Alpine Town", null, "true" },
            { "racingElite", "casinoRun", "Casino Run", null, "true" },

        { "autosplitting", "hotshot", "GP 4 - Hotshot!", null, "true" },
            { "hotshot", "skiParadise", "Ski Paradise", null, "true" },
            { "hotshot", "templeRuins", "Temple Ruins", null, "true" },
            { "hotshot", "downTown", "Downtown", null, "true" },
            { "hotshot", "seaView", "Sea View", null, "true" },

        { "autosplitting", "bosslevel", "GP 5 - Boss Level", null, "true" },
            { "bosslevel", "8BallHighway", "8 Ball Highway", null, "true" },
            { "bosslevel", "surfCity", "Surf City", null, "true" },
            { "bosslevel", "cargoChaos", "Cargo Chaos", null, "true" },
            { "bosslevel", "frozenFreeway", "Frozen Freeway", null, "true" }
    };
    
    for (int i = 0; i < Settings.GetLength(0); i++)
    {
        settings.Add(Settings[i, 1], bool.Parse(Settings[i, 4]), Settings[i, 2], Settings[i, 0]);
        if (!string.IsNullOrEmpty(Settings[i, 3])) settings.SetToolTip(Settings[i, 1], Settings[i, 3]);
    }
    
    vars.totaligt = 0;
    vars.progressIGT = 0;


    vars.Tracks = new Dictionary<string, uint>
    {
        { "theMarina",     0x10C973C7u },
        { "oceanWorld",    0xB16F97F1u },
        { "heatedHighway", 0xAA403D91u },
        { "seaView",       0x2C2F4FBAu },
        { "surfCity",      0x5F26E021u },
        { "downTown",      0x497EF89Du },
        { "area41",        0x628652E2u },
        { "boneyard",      0xBE412089u },
        { "casinoRun",     0xB4A4C188u },
        { "8BallHighway",  0x467A9398u },
        { "templeDrive",   0xC8C3824Du },
        { "dinoDash",      0x964E8450u },
        { "royalRoadway",  0x567D2F85u },
        { "templeRuins",   0xC515DB63u },
        { "cargoChaos",    0x814E55BEu },
        { "castleFunfair", 0xADFD1964u },
        { "fossilCave",    0xE343A128u },
        { "skiParadise",   0x45906918u },
        { "alpineTown",    0x35E767E2u },
        { "frozenFreeway", 0x71D4095Au }
    };
}

init
{
    vars.watchers = new MemoryWatcherList();
    var scanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);
    IntPtr ptr;

    ptr = scanner.Scan(new SigScanTarget(3,
        "48 8B 05 ????????",    // mov rax,[HotshotRacing.exe+1317D18]
        "48 8B 48 20",          // mov rcx,[rax+20]
        "8B 51 38")             // mov edx,[rcx+38]
        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
        if (ptr == IntPtr.Zero) throw new Exception();
    vars.watchers.Add(new MemoryWatcher<float>(new DeepPointer(ptr, 0x2A8)) { Name = "runstart", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });
    
    ptr = scanner.Scan(new SigScanTarget(2,
        "8B 05 ????????",       // mov eax,[HotshotRacing.exe+1317CAC]
        "85 C0",                // test eax,eax
        "7E 2B")                // jle HotshotRacing.exe+783F2
        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
        if (ptr == IntPtr.Zero) throw new Exception();
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr)) { Name = "racestatus" }); // 0 idle; 1 stage intro: 3 countdown; 4 racing; 5 results screen

    ptr = scanner.Scan(new SigScanTarget(4,
        "41 89 B4 CE ????????") // mov [r14+rcx*8+01317ED4],esi
        { OnFound = (p, s, addr) => modules.First().BaseAddress + 0x38 + p.ReadValue<int>(addr) });
        if (ptr == IntPtr.Zero) throw new Exception();
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr)) { Name = "racecompleted" }); // becomes 1 when completing a race, becomes 3 in case of TimeOut
    
    ptr = scanner.Scan(new SigScanTarget(3,
        "48 8B 05 ????????",    // mov rax,[HotshotRacing.exe+1317CD0]
        "F3 0F10 40 04",        // movss xmm0,[rax+04]
        "C3")                   // ret
        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
        if (ptr == IntPtr.Zero) throw new Exception();
    vars.watchers.Add(new MemoryWatcher<float>(new DeepPointer(ptr, 0x4)) { Name = "igt", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull }); // starts at the start of every race and stops at the results screen

    ptr = scanner.Scan(new SigScanTarget(5,
        "8B F7",                // mov esi,edi
        "48 83 3D ???????? 00", // cmp qword ptr [HotshotRacing.exe+1317C80],00
        "75 41")                // jne HotshotRacing.exe+D96A1
        { OnFound = (p, s, addr) => addr + 0x5 + p.ReadValue<int>(addr) });
        if (ptr == IntPtr.Zero) throw new Exception();
    vars.watchers.Add(new MemoryWatcher<float>(new DeepPointer(ptr, 0x0, 0xE8, 0x34)) { Name = "totalracetime", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull }); // updates itself each time you complete a lap (final lap included)
    
    ptr = scanner.Scan(new SigScanTarget(3,
        "44 39 2D ????????",    // cmp [HotshotRacing.exe+13191C8],r13d
        "76 6C")                // jna HotshotRacing.exe+DA82C
        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
        if (ptr == IntPtr.Zero) throw new Exception();
    vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr)) { Name = "trackorder" }); // Becomes 4 at the end of a GP

    ptr = scanner.Scan(new SigScanTarget(3,
        "48 8B 0D ????????",    // mov rcx,[HotshotRacing.exe+F83C98]
        "49 89 73 10")          // mov [r11+10],rsi
        { OnFound = (p, s, addr) => addr + 0x4 + p.ReadValue<int>(addr) });
        if (ptr == IntPtr.Zero) throw new Exception();
    vars.watchers.Add(new MemoryWatcher<uint>(new DeepPointer(ptr, 0x0)) { Name = "trackID", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });
} 

start
{
    // Reset the variables if you reset a run
    vars.totaligt = 0;
    vars.progressIGT = 0;

    if (settings["StartTime"])
    {
        return(vars.watchers["runstart"].Current >= 2 && vars.watchers["igt"].Current == 0 && vars.watchers["racestatus"].Current == 3 && vars.watchers["trackorder"].Current == 0); 
    }
    else
    {
        return(vars.watchers["igt"].Current != 0 && vars.watchers["igt"].Old == 0 && vars.watchers["trackorder"].Current == 0);
    }
}


update
{
    vars.watchers.UpdateAll(game);

    // During a race, the IGT is calculated by the game and is added to the total
    if (vars.watchers["racecompleted"].Current == 0)
    {
      // If you restart an event or a race, the IGT of the failed race is still considered and added
      if (vars.watchers["igt"].Old != 0 && vars.watchers["igt"].Current == 0 && vars.watchers["racestatus"].Old == 4)
      {
        vars.totaligt = vars.watchers["igt"].Old + vars.totaligt;
        vars.progressIGT = vars.totaligt;
      }
      else
      {
        vars.progressIGT = vars.watchers["igt"].Current + vars.totaligt;
      }
    }

    // How to behave the moment you complete a race:
    if (vars.watchers["racecompleted"].Current == 1 && vars.watchers["racecompleted"].Old == 0)
    {
      vars.totaligt = (Math.Truncate(1000 * (vars.watchers["totalracetime"].Current + vars.totaligt)) / 1000);
      vars.progressIGT = vars.totaligt;
    }
}

gameTime
{
    return TimeSpan.FromSeconds(vars.progressIGT);
}

split
{
    if (vars.watchers["racecompleted"].Current == 1 && vars.watchers["racecompleted"].Old == 0)
    {
        foreach (var entry in vars.Tracks)
        {
            if (vars.watchers["trackID"].Current == entry.Value)
                return settings[entry.Key];
        }
    }
}

isLoading
{
    return true;
}
