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
		var gsm = helper.GetClass("Assembly-CSharp", "GameStateManager");
		var gsmSt = helper.GetParent(gsm); // get StageLoader's Singleton

		vars.Unity.Make<long>(gsmSt.Static, gsmSt["s_sInstance"], gsm["loadScr"]).Name = "isLoading";
		return true;
	});

	vars.Unity.Load(game);
}

update
{
	if (!vars.Unity.Loaded)
		return false;

	vars.Unity.Update();

	print(vars.Unity["isLoading"].Current.ToString());
}

isLoading
{
	return vars.Unity["isLoading"].Current != 0;
}

exit
{
	vars.Unity.Reset();
}

shutdown
{
	vars.Unity.Reset();
}