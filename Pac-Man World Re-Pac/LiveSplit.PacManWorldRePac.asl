// Autosplitter and load Time remover for Pac-Man World Re-Pac
// Coding: Jujstme
// contacts: just.tribe@gmail.com
// Version: 1.0.2 (Aug 27th, 2022)

state("PAC-MAN WORLD Re-PAC") {}

startup
{
    vars.Unity = Activator.CreateInstance(Assembly.Load(File.ReadAllBytes(@"Components\LiveSplit.ASLHelper.bin")).GetType("ASLHelper.Unity"), timer, this);
    vars.Unity.LoadSceneManager = true;
    vars.Unity.GameName = "Pac-Man World Re-Pac";
    vars.Unity.AlertLoadless(vars.Unity.GameName);

    dynamic[,] Settings =
    {
        { 101, "Buccaneer Beach" },
        { 102, "Corsair's Cove" },
        { 103, "Crazy Cannonade" },
        { 104, "HMB Windbag" },
        { 201, "Crisis Cavern" },
        { 202, "Manic Mines" },
        { 203, "Anubis Rex" },
        { 301, "Space Race" },
        { 302, "Far Out" },
        { 303, "Gimme Space" },
        { 304, "King Galaxian" },
        { 401, "Clowing Around" },
        { 402, "Barrel Blast" },
        { 403, "Spin Dizzy" },
        { 404, "Clown Prix" },
        { 501, "Perilous Pipes" },
        { 502, "Under Pressure" },
        { 503, "Down the Tubes" },
        { 504, "Krome Keeper" },
        { 601, "Ghostly Garden" },
        { 602, "Creepy Catacombs" },
        { 603, "Grave Danger" },
        { 604, "Toc-Man's Lair"},
    };
    for (int i = 0; i < Settings.GetLength(0); i++) settings.Add(Settings[i, 0].ToString(), true, Settings[i, 1]);
}

init
{
    vars.Unity.TryOnLoad = (Func<dynamic, bool>)(mono =>
    {
        var sm = mono.GetClass("SceneManager", 1);
        vars.Unity["isLoading"] = sm.Make<bool>("s_sInstance", "m_bProcessing");
        vars.Unity["LevelID"] = sm.Make<int>("s_sInstance", "m_eCurrentScene");
        vars.Unity["OldLevelID"] = sm.Make<int>("s_sInstance", "m_ePrevScene");
        vars.Unity["isLoading2"] = mono.GetClass("GameStateManager", 1).Make<long>("s_sInstance", "loadScr");
        vars.Unity["TocmanQTE"] = mono.GetClass("BossTocman", 1).Make<bool>("s_sInstance", "m_qteSuccess");
        return true;
    });

    vars.Unity.Load();
}

update
{
    if (!vars.Unity.Loaded || !vars.Unity.Update()) return false;
}

split
{
    if (vars.Unity["LevelID"].Changed && (vars.Unity["OldLevelID"].Current == 3 || vars.Unity["OldLevelID"].Current > 2000) && vars.Unity["OldLevelID"].Old > 100 && vars.Unity["OldLevelID"].Old < 604)
    {
        return settings[vars.Unity["OldLevelID"].Old.ToString()];
    } else if (vars.Unity["LevelID"].Current == 604 && !vars.Unity["LevelID"].Changed)
    {
        return settings[vars.Unity["OldLevelID"].Old.ToString()] && vars.Unity["TocmanQTE"].Current && !vars.Unity["TocmanQTE"].Old;
    }
}

start
{
	return vars.Unity["LevelID"].Current == 4 && vars.Unity["isLoading"].Current && !vars.Unity["isLoading"].Old;
}

reset
{
    return vars.Unity["LevelID"].Current == 4 && vars.Unity["LevelID"].Changed;
}

isLoading
{
    return vars.Unity["isLoading"].Current || vars.Unity["isLoading2"].Current != 0;
}

onStart
{
    timer.IsGameTimePaused = true;
}

exit
{
    vars.Unity.Dispose();
}

shutdown
{
    vars.Unity.Dispose();
}
