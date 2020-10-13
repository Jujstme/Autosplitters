// IGT timer autosplitter for Roll Away (USA version)
// Coding: Jujstme
// Version: 1.0
// In case of bugs, please contact me at just.tribe@gmail.com

state("retroarch", "64bit mednafen_psx_hw_libretro.dll")
{ 
  int levelIGT: "mednafen_psx_hw_libretro.dll", 0x5ACC60, 0xA5584;
  byte levelNo: "mednafen_psx_hw_libretro.dll", 0x5ACC60, 0xA3408;
  byte worldNo: "mednafen_psx_hw_libretro.dll", 0x5ACC60, 0xA340C;
  bool demomode: "mednafen_psx_hw_libretro.dll", 0x5ACC60, 0xA342C;
}

state("retroarch", "64bit mednafen_psx_libretro.dll")
{ 
  int levelIGT: "mednafen_psx_libretro.dll", 0x407500, 0xA5584;
  byte levelNo: "mednafen_psx_libretro.dll", 0x407500, 0xA3408;
  byte worldNo: "mednafen_psx_libretro.dll", 0x407500, 0xA340C;
  bool demomode: "mednafen_psx_libretro.dll", 0x407500, 0xA342C;
} 

state("retroarch", "64bit pcsx_rearmed_libretro.dll")
{
  int levelIGT: "pcsx_rearmed_libretro.dll", 0xD2028, 0xA5584;
  byte levelNo: "pcsx_rearmed_libretro.dll", 0xD2028, 0xA3408;
  byte worldNo: "pcsx_rearmed_libretro.dll", 0xD2028, 0xA340C;
  bool demomode: "pcsx_rearmed_libretro.dll", 0xD2028, 0xA342C;
} 

state("ePSXe", "v2.0.5")
{ 
  int levelIGT: 0xB275A4;
  byte levelNo: 0xB25428;
  byte worldNo: 0xB2542C;
  bool demomode: 0xB2544C;
} 

state("ePSXe", "v2.0.2-1")
{ 
  int levelIGT: 0x8CA6C4;
  byte levelNo: 0x8C8548;
  byte worldNo: 0x8C854C;
  bool demomode: 0x8C856C;
} 

state("ePSXe", "v2.0.0")
{ 
  int levelIGT: 0x8BF5A4;
  byte levelNo: 0x8BD428;
  byte worldNo: 0x8BD42C;
  bool demomode: 0x8BD44C;
} 

state("ePSXe", "v1.9.25")
{ 
  int levelIGT: 0x730C24;
  byte levelNo: 0x72EAA8;
  byte worldNo: 0x72EAAC;
  bool demomode: 0x72EACC;
} 

init
{
	version = "unknown";

	if (game.ProcessName.ToLower() == "retroarch") {
		
		if ( game.Is64Bit() ) {
			vars.gameversion = "64bit";
		} else {
			vars.gameversion = "32bit";
		}
		ProcessModuleWow64Safe libretromodule = modules.Where(m => m.ModuleName == "mednafen_psx_hw_libretro.dll" || m.ModuleName == "mednafen_psx_libretro.dll" || m.ModuleName == "pcsx_rearmed_libretro.dll").First();
		version = vars.gameversion + " " + libretromodule.ModuleName;
	} else if (game.ProcessName.ToLower() == "epsxe") {
		switch (modules.First().ModuleMemorySize) {
			case 0x1553000:
				version = "v2.0.2-1";
				break;
			case 0x182A000:
				version = "v2.0.5";
				break;
			case 0x1359000:
				version = "v2.0.0";
				break;
			case 0xA08000:
				version = "v1.9.25";
				break;
		}
	}
}

startup
{
   // refreshRate = 60;
   vars.progressIGT = 0;
   vars.totalIGT = 0;
 
   settings.Add("levelsplit", false, "Split at the end of each level");
   settings.SetToolTip("levelsplit", "If enabled, LiveSplit will trigger a split at the end of every level (150 splits).\nIf disabled, LiveSplit will trigger a split only at the end of each world (10 splits).\n\nDefault: disabled");

}

start
{
   vars.progressIGT = 0;
   vars.totalIGT = 0;
   return(current.levelIGT != 0 && old.levelIGT == 0 && !current.demomode);
}

update
{
  if (current.levelIGT == 0 && old.levelIGT != 0) {
	vars.totalIGT += vars.progressIGT;
  }
  vars.progressIGT = current.levelIGT/60;
}

gameTime
{
  return TimeSpan.FromSeconds(vars.progressIGT + vars.totalIGT);
}

split
{
	if (settings["levelsplit"]) {
		return ((current.levelNo != old.levelNo) && current.levelNo < 15 && !(current.levelNo == 0 && current.worldNo == 0));
	} else {
		return (current.worldNo > old.worldNo);	
	}
}

isLoading
{
  return true;
}
