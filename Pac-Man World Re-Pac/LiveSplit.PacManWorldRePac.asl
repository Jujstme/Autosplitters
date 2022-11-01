// Autosplitter and load Time remover for Pac-Man World Re-Pac
// Coding: Jujstme
// contacts: just.tribe@gmail.com
// Version: 1.0.5 (Nov 1st, 2022)

state("PAC-MAN WORLD Re-PAC") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    //vars.Helper.LoadSceneManager = true;
    vars.Helper.GameName = "Pac-Man World Re-Pac";
    vars.Helper.AlertLoadless();

    dynamic[,] Settings =
    {
        { 101, "Buccaneer Beach" },
        { 102, "Corsair's Cove" },
        { 103, "Crazy Cannonade" },
        { 104, "HMS Windbag" },
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
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var sm = mono.GetClass("SceneManager", 1);
        vars.Helper["isLoading"] = sm.Make<bool>("s_sInstance", "m_bProcessing");
        vars.Helper["isLoading"] = sm.Make<bool>("s_sInstance", "m_bProcessing");
        vars.Helper["LevelID"] = sm.Make<int>("s_sInstance", "m_eCurrentScene");
        vars.Helper["isLoading2"] = mono.GetClass("GameStateManager", 1).Make<long>("s_sInstance", "loadScr");
        vars.Helper["TocmanQTE"] = mono.GetClass("BossTocman", 1).Make<bool>("s_sInstance", "m_qteSuccess");
        return true;
    });

    vars.LastLevelID = 0;
}

update
{
    if (vars.Helper["LevelID"].Current > 100 && vars.Helper["LevelID"].Current <= 604)
        vars.LastLevelID = vars.Helper["LevelID"].Current;
}

split
{
    if (vars.Helper["LevelID"].Changed && vars.Helper["LevelID"].Current == 1 && (vars.Helper["LevelID"].Old == 3 || vars.Helper["LevelID"].Old > 1000))
    {
        return settings[vars.LastLevelID.ToString()];
    }
    else if (vars.Helper["LevelID"].Current == 604 && !vars.Helper["LevelID"].Changed)
    {
        return settings[vars.Helper["LevelID"].Old.ToString()] && vars.Helper["TocmanQTE"].Current && !vars.Helper["TocmanQTE"].Old;
    }
}

start
{
    return vars.Helper["LevelID"].Current == 4 && vars.Helper["isLoading"].Current && !vars.Helper["isLoading"].Old;
}

reset
{
    return vars.Helper["LevelID"].Current == 4 && vars.Helper["LevelID"].Old == 1;
}

isLoading
{
    return vars.Helper["isLoading"].Current || vars.Helper["isLoading2"].Current != 0;
}

onStart
{
    timer.IsGameTimePaused = true;
}

shutdown
{
    vars.Helper.Dispose();
}
