// Wolfenstein (2009)
// Load remover
// Coding: Jujstme
// Version 1.0.0

state("Wolf2"){}

init
{
    var ptr = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize).Scan(new SigScanTarget(5, "89 5E 50 8B 0D") { OnFound = (p, s, addr) => (IntPtr)p.ReadValue<int>(addr) });
    if (ptr == IntPtr.Zero) throw new Exception("Sigscan failed!");
    vars.isLoading = new MemoryWatcher<bool>(new DeepPointer(ptr, 0x145));
}

update
{
    vars.isLoading.Update(game);
}

isLoading
{
    return vars.isLoading.Current;
}