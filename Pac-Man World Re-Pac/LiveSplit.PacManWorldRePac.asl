// Load Time remover for Pac-Man World Re-Pac
// Coding: Jujstme
// contacts: just.tribe@gmail.com
// Version: 1.0.0 (Aug 27th, 2022)

state("PAC-MAN WORLD Re-PAC") {}

startup
{
	vars.Unity = Assembly.Load(File.ReadAllBytes(@"Components\UnityASL.bin")).CreateInstance("UnityASL.Unity");
	vars.Unity.LoadSceneManager = true;
}

init
{
	vars.Unity.TryOnLoad = (Func<dynamic, bool>)(helper =>
	{
		var sm = helper.GetClass("Assembly-CSharp", "SceneManager");
		var smSt = helper.GetParent(sm);
		vars.Unity.Make<bool>(smSt.Static, smSt["s_sInstance"], sm["m_bProcessing"]).Name = "isLoading";

		var gsm = helper.GetClass("Assembly-CSharp", "GameStateManager");
		var gsmSt = helper.GetParent(gsm);
		vars.Unity.Make<long>(gsmSt.Static, gsmSt["s_sInstance"], gsm["loadScr"]).Name = "isLoading2";

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

isLoading
{
	return vars.Unity["isLoading"].Current || vars.Unity["isLoading2"].Current != 0;
}

exit
{
	vars.Unity.Reset();
}

shutdown
{
	vars.Unity.Reset();
}
