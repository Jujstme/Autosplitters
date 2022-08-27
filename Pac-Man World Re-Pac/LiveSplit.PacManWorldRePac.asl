// Autosplitter and load Time remover for Pac-Man World Re-Pac
// Coding: Jujstme
// contacts: just.tribe@gmail.com
// Version: 1.0.1 (Aug 27th, 2022)

state("PAC-MAN WORLD Re-PAC") {}

startup
{
    vars.Unity = Assembly.Load(File.ReadAllBytes(@"Components\UnityASL.bin")).CreateInstance("UnityASL.Unity");
    vars.Unity.LoadSceneManager = true;

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
    vars.Unity.TryOnLoad = (Func<dynamic, bool>)(helper =>
    {
        var sm = helper.GetClass("Assembly-CSharp", "SceneManager");
        var smSt = helper.GetParent(sm);
        vars.Unity.Make<bool>(smSt.Static, smSt["s_sInstance"], sm["m_bProcessing"]).Name = "isLoading";
        vars.Unity.Make<int>(smSt.Static, smSt["s_sInstance"], sm["m_eCurrentScene"]).Name = "LevelID";
        vars.Unity.Make<int>(smSt.Static, smSt["s_sInstance"], sm["m_ePrevScene"]).Name = "OldLevelID";

        var gsm = helper.GetClass("Assembly-CSharp", "GameStateManager");
        var gsmSt = helper.GetParent(gsm);
        vars.Unity.Make<long>(gsmSt.Static, gsmSt["s_sInstance"], gsm["loadScr"]).Name = "isLoading2";

        var tocman = helper.GetClass("Assembly-CSharp", "BossTocman");
        var tocmanSt = helper.GetParent(tocman);
        vars.Unity.Make<bool>(tocmanSt.Static, tocmanSt["s_sInstance"], tocman["m_qteSuccess"]).Name = "TocmanQTE";

        return true;
    });

    vars.Unity.Load(game);
}

update
{
    if (!vars.Unity.Loaded)
        return false;

    vars.Unity.Update();
}

split
{
    if (vars.Unity["LevelID"].Changed && (vars.Unity["OldLevelID"].Current == 3 || vars.Unity["OldLevelID"].Current > 2000) && vars.Unity["OldLevelID"].Old > 100 && vars.Unity["OldLevelID"].Old < 604)
    {
        return settings[vars.Unity["OldLevelID"].Old.ToString()];
    } else if (vars.Unity["OldLevelID"].Current == 604 && !vars.Unity["OldLevelID"].Changed)
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
    vars.Unity.Reset();
}

shutdown
{
    vars.Unity.Reset();
}
