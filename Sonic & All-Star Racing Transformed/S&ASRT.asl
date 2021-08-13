// IGT timer autosplitter
// Coding: Jujstme
// contacts: just.tribe@gmail.com

state("ASN_App_PcDx9_Final")
{
	// General purpose variables
	byte runstart: 0x852918;							// Will be 1 when the run starts
	byte runstart2: 0x7C73C0;							// Must be 1 when the run starts. If it's 0, you're in the main screen
	byte modeselect: 0x856890;							// 0 in world tour, 1 in GP mode
	byte requiredlaps: 0x7CE920, 0x0, 0xC1B8, 0x4;		// Usually 3 in all races. Becomes 255 in events where the lap count is irrelevant
	byte racestatus: 0x7CE944;							// 0 idle; 1 stage intro; 4 racing; 5 race ended
	byte racecompleted: 0x7CE930;						// becomes 1 when a race or an event ends, regardless of anything
	byte gpmodetrack: 0x7D6AC8;				// identifier for the track number in GP mode. Starts from 0 and increases each time you complete a race, up to the value of 4
	float igt : 0x7CE980;								// starts at the start of every race and stops at the results screen
	float totalracetime : 0x7CE920, 0x0, 0xC1B8, 0x28;	// updates itself each time you complete a lap (final lap included)

	byte endcredits: 0x9FD48C;							// Becomes 1 at the credits screen
	byte worldtourtrackmoonlightpark: 0x796EB0; 		// Internal ID of the selected track for World Tour (Moonlight Park)
	byte worldtourtracksuperstarshowhdown: 0x796EB4; 	// Internal ID of the selected track for World Tour (Superstar Showdown)

    uint trackID: 0x7C7434, 0x0;						// Hexadecimal ID for the loaded track. It updates when loading a new track, while the old one stays stored in memory
	uint eventType: 0x7C7430, 0x0;						// Hexadecimal ID for the current game mode. It updates when loading a new track.
    
	// Extremely long World Tour Stars variable listing for each event
	// Unfortunately the game doesn't provide a reliable address for the total number of stars
	// in world tour that correctly updates at the end of each event
	
	// Sunshine coast
	byte coastalcruise: 0x7D01F8, 0x7C;
	byte studioscrapes: 0x7D01F8, 0x138;
	byte battlezoneblast: 0x7D01F8, 0x1F4;
	byte downtowndrift: 0x7D01F8, 0x2B0;
	byte monkeymayhem: 0x7D01F8, 0x36C;
	byte starryspeedway: 0x7D01F8, 0x428;
	byte rouletterush: 0x7D01F8, 0x4E4;
	byte canyoncarnage: 0x7D01F8, 0x5A0;

	// Frozen Valley
	byte snowballshakedown: 0x7D01FC, 0x7C;
	byte bananaboost: 0x7D01FC, 0x138;
	byte shinobiscramble: 0x7D01FC, 0x1F4;
	byte seasidescrap: 0x7D01FC, 0x2B0;
	byte tryckytraffic: 0x7D01FC, 0x36C;
	byte studioscurry: 0x7D01FC, 0x428;
	byte graffitigroove: 0x7D01FC, 0x4E4;
	byte shakingskies: 0x7D01FC, 0x5A0;
	byte neonknockout: 0x7D01FC, 0x65C;
	byte pirateplunder: 0x7D01FC, 0x718;
	
	// Schorching Skies
	byte adderassault: 0x7D0200, 0x7C;
	byte dreamydrive: 0x7D0200, 0x138;
	byte sanctuaryspeedway: 0x7D0200, 0x1F4;
	byte keilscarnage: 0x7D0200, 0x2B0;
	byte carriercrisis: 0x7D0200, 0x36C;
	byte sunshineslide: 0x7D0200, 0x428;
	byte roguerings: 0x7D0200, 0x4E4;
	byte seasideskirmish: 0x7D0200, 0x5A0;
	byte shrinetime: 0x7D0200, 0x65C;
	byte hangarhassle: 0x7D0200, 0x718;
	
	// Twilight Engine
	byte bootyboost: 0x7D0204, 0x7C;
	byte racingrangers: 0x7D0204, 0x138;
	byte shinobishowdown: 0x7D0204, 0x1F4;
	byte ruinrun: 0x7D0204, 0x2B0;
	byte monkeybrawl: 0x7D0204, 0x36C;
	byte crumblingchaos: 0x7D0204, 0x428;
	byte hatcherhustle: 0x7D0204, 0x4E4;
	byte deatheggduel: 0x7D0204, 0x5A0;
	byte undertakerovertaker: 0x7D0204, 0x65C;
	byte goldengauntlet: 0x7D0204, 0x718;

	// Moonlight Park
	byte carnivalclash: 0x7D0208, 0x7C;
	byte curiencurves: 0x7D0208, 0x138;
	byte moltenmayhem: 0x7D0208, 0x1F4;
	byte speedingseasons: 0x7D0208, 0x2B0;
	byte burningboost: 0x7D0208, 0x36C;
	byte oceanoutrun: 0x7D0208, 0x428;
	byte billybackslide: 0x7D0208, 0x4E4;
	byte carriercharge: 0x7D0208, 0x5A0;
	byte jetsetjaunt: 0x7D0208, 0x65C;
	byte arcadeannihilation: 0x7D0208, 0x718;
	
	// Superstar Showdown
	byte rapidruins: 0x7D020C, 0x7C;
	byte zombiezoom: 0x7D020C, 0x138;
	byte maracarmadness: 0x7D020C, 0x1F4;
	byte nightmaremeander: 0x7D020C, 0x2B0;
	byte maracamelee: 0x7D020C, 0x36C;
	byte castlechaos: 0x7D020C, 0x428;
	byte volcanovelocity: 0x7D020C, 0x4E4;
	byte rangerrush: 0x7D020C, 0x5A0;
	byte tokyotakeover: 0x7D020C, 0x65C;
	byte fatalfinale: 0x7D020C, 0x718;
}

startup
{
   vars.totaligt = 0;
   vars.progressIGT = 0;
  // refreshRate = 60;
   settings.Add("GPsplit", false, "Only split at the end of each Grand Prix");
   settings.SetToolTip("GPsplit", "If enabled, LiveSplit will only trigger a split at the end of each Grand Prix\n(specifically, at the end of Dragon Canyon, Rogue's Landing, Sanctuary\nFalls, Race of AGES and Egg Hangar).\n\nNOTE: Doing this will DISABLE automatic splitting for all other tracks,\nregardless of the option selected in LiveSplit settings.\n\nThis option has no effect in World Tour or Single Race.");
   settings.Add("RaceSplitting", true, "Race splitting (GP mode and Single Races)");
   settings.Add("DragonCup", true, "Dragon Cup", "RaceSplitting");
   settings.Add("RogueCup", true, "Rogue Cup", "RaceSplitting");
   settings.Add("EmeraldCup", true, "Emerald Cup", "RaceSplitting");
   settings.Add("ArcadeCup", true, "Arcade Cup", "RaceSplitting");
   settings.Add("ClassicCup", true, "Classic Cup", "RaceSplitting");
   settings.Add("OutrunCup", true, "Outrun Bay", "RaceSplitting");
   settings.Add("OceanView", true, "Ocean View", "DragonCup");
   settings.Add("SambaStudios", true, "Samba Studios", "DragonCup");
   settings.Add("CarrierZone", true, "Carrier Zone", "DragonCup");
   settings.Add("DragonCanyon", true, "Dragon Canyon", "DragonCup");
   settings.Add("TempleTrouble", true, "Temple Trouble", "RogueCup");
   settings.Add("GalacticParade", true, "Galactic Parade", "RogueCup");
   settings.Add("SeasonalShrines", true, "Seasonal Shrines", "RogueCup");
   settings.Add("RoguesLanding", true, "Rogue's Landing", "RogueCup");
   settings.Add("DreamValley", true, "Dream Valley", "EmeraldCup");
   settings.Add("ChillyCastle", true, "Chilly Castle", "EmeraldCup");
   settings.Add("GraffitiCity", true, "Graffiti City", "EmeraldCup");
   settings.Add("SanctuaryFalls", true, "Sanctuary Falls", "EmeraldCup");
   settings.Add("GraveyardGig", true, "Graveyard Gig", "ArcadeCup");
   settings.Add("AddersLair", true, "Adder's Lair", "ArcadeCup");
   settings.Add("BurningDepths", true, "Burning Depths", "ArcadeCup");
   settings.Add("RaceOfAges", true, "Race of AGES", "ArcadeCup");
   settings.Add("SunshineTour", true, "Sunshine Tour", "ClassicCup");
   settings.Add("ShibuyaDowntown", true, "Shibuya Downtown", "ClassicCup");
   settings.Add("RouletteRoad", true, "Roulette Road", "ClassicCup");
   settings.Add("EggHangar", true, "Egg Hangar", "ClassicCup");
   settings.Add("OutrunBay", true, "Outrun Bay", "OutrunCup");
   
  // Check if you're using RTA timing in LiveSplit and will eventually offer you to switch to GameTime
  if (timer.CurrentTimingMethod == TimingMethod.RealTime) {
    var timingMessage = MessageBox.Show (
    "This game uses Time without Loads (Game Time) as the main timing method for All Cups speedrun categories on speedrun.com.\n"+
    "LiveSplit is currently set to show Real Time (RTA).\n\n"+
    "Would you like to set the timing method to Game Time?",
    "Sonic & All-Star Racing Transformed | LiveSplit",
    MessageBoxButtons.YesNo,MessageBoxIcon.Question);
    if (timingMessage == DialogResult.Yes) {
      timer.CurrentTimingMethod = TimingMethod.GameTime;
      MessageBox.Show("Timing method has been set to GameTime!", "Sonic & All-Star Racing Transformed | LiveSplit", MessageBoxButtons.OK, MessageBoxIcon.Information);
    } else if (timingMessage == DialogResult.No) {
      timer.CurrentTimingMethod = TimingMethod.RealTime;
      MessageBox.Show("Timing method will stay set to Real Time (RTA).", "Sonic & All-Star Racing Transformed | LiveSplit", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }
  }
}

start
{
   // Reset the IGT variables if you reset a run
   vars.totaligt = 0;
   vars.progressIGT = 0;
   
	if (current.modeselect == 0)
	{
		if (current.coastalcruise + current.canyoncarnage == 0) return (current.runstart == 1 && current.runstart2 == 1 && old.runstart == 0);
	}
	else if (current.modeselect == 1 || current.modeselect == 3)
	{
		return (current.runstart == 1 && current.runstart2 == 1 && old.runstart == 0);
	}
}


update
{
	// During a race, the IGT is calculated by the game (not by LiveSplit) and is added to the total
	if (current.racecompleted == 0)	{
		
		// If you restart an event or a race, the IGT of the failed race is still considered and added
		if (old.igt != 0 && current.igt == 0 && old.racestatus == 4) {
			vars.totaligt = old.igt + vars.totaligt;
			vars.progressIGT = vars.totaligt;
		}
		else
		{
			vars.progressIGT = current.igt + vars.totaligt;
		}
	}

	// How to behave the moment you complete a race:
	if(current.racecompleted == 1 && old.racecompleted == 0)
	{
		// IF YOU ARE IN WORLD TOUR AND YOU ARE DOING A SPECIAL CHALLENGE (everything that is not a race)
		// THE GAME DOESN'T STORE totalracetime
		// In order to cope with that, we need to grab the IGT directly. It's less accurate, but works anyway
		if ((current.modeselect == 0 && current.requiredlaps == 255) || current.eventType == 0xE64B5DD8) {
			vars.totaligt = current.igt + vars.totaligt;
		}
		else
		{
			// If you're not in one of the above special conditions, the time can be calculated normally
			vars.totaligt = current.totalracetime + vars.totaligt;
		}
		vars.progressIGT = vars.totaligt;
	}
}

gameTime
{
	return TimeSpan.FromSeconds((double)vars.progressIGT);
}

split
{
	if (current.modeselect == 0) {
		current.totalstars = current.coastalcruise + current.studioscrapes + current.battlezoneblast + current.downtowndrift +
							current.monkeymayhem + current.starryspeedway + current.rouletterush + current.canyoncarnage +
							current.snowballshakedown + current.bananaboost + current.shinobiscramble + current.seasidescrap +
							current.tryckytraffic + current.studioscurry + current.graffitigroove + current.shakingskies +
							current.neonknockout + current.pirateplunder + current.adderassault + current.dreamydrive +
							current.sanctuaryspeedway + current.keilscarnage + current.carriercrisis + current.sunshineslide +
							current.roguerings + current.seasideskirmish + current.shrinetime + current.hangarhassle +
							current.bootyboost + current.racingrangers + current.shinobishowdown + current.ruinrun +
							current.monkeybrawl + current.crumblingchaos + current.hatcherhustle + current.deatheggduel +
							current.undertakerovertaker + current.goldengauntlet + current.carnivalclash + current.curiencurves +
							current.moltenmayhem + current.speedingseasons + current.burningboost + current.oceanoutrun +
							current.billybackslide + current.carriercharge + current.jetsetjaunt + current.arcadeannihilation +
							current.rapidruins + current.zombiezoom + current.maracarmadness + current.nightmaremeander +
							current.maracamelee + current.castlechaos + current.volcanovelocity + current.rangerrush +
							current.tokyotakeover + current.fatalfinale;
		if ((current.worldtourtracksuperstarshowhdown == 9 && old.fatalfinale == 0) || (current.worldtourtrackmoonlightpark == 9 && old.arcadeannihilation == 0)) {
			return(false);
		}
		else {
			return((current.totalstars > old.totalstars) || (current.endcredits == 1 && old.endcredits == 0));
		}
	}
	else if (current.modeselect == 1 || current.modeselect == 3)
	{
		if (settings["GPsplit"] && current.modeselect == 1) {
			return (current.gpmodetrack == 3 && current.racecompleted == 1 && old.racecompleted == 0);
		}
		else
		{
			if (current.racecompleted == 1 && old.racecompleted == 0) {
			  if (current.trackID == 0xD4257EBD) {
			    return (settings["OceanView"]);
			  } else if (current.trackID == 0x32D305A8) {
			    return (settings["SambaStudios"]);
			  } else if (current.trackID == 0xC72B3B98) {
			    return (settings["CarrierZone"]);
			  } else if (current.trackID == 0x03EB7FFF) {
			    return (settings["DragonCanyon"]);
			  } else if (current.trackID == 0xE3121777) {
			    return (settings["TempleTrouble"]);
			  } else if (current.trackID == 0x4E015AB6) {
			    return (settings["GalacticParade"]);
			  } else if (current.trackID == 0x503C1CBC) {
			    return (settings["SeasonalShrines"]);
			  } else if (current.trackID == 0x7534B7CA) {
			    return (settings["RoguesLanding"]);
			  } else if (current.trackID == 0x38A394ED) {
			    return (settings["DreamValley"]);
			  } else if (current.trackID == 0xC5C9DEA1) {
			    return (settings["ChillyCastle"]);
			  } else if (current.trackID == 0xD936550C) {
			    return (settings["GraffitiCity"]);
			  } else if (current.trackID == 0x4A0FF7AE) {
			    return (settings["SanctuaryFalls"]);
			  } else if (current.trackID == 0xCD8017BA) {
			    return (settings["GraveyardGig"]);
			  } else if (current.trackID == 0xDC93F18B) {
			    return (settings["AddersLair"]);
			  } else if (current.trackID == 0x2DB91FC2) {
			    return (settings["BurningDepths"]);
			  } else if (current.trackID == 0x94610644) {
			    return (settings["RaceOfAges"]);
			  } else if (current.trackID == 0xE6CD97F0) {
			    return (settings["SunshineTour"]);
			  } else if (current.trackID == 0xE87FDF22) {
			    return (settings["ShibuyaDowntown"]);
			  } else if (current.trackID == 0x17463C8D) {
			    return (settings["RouletteRoad"]);
			  } else if (current.trackID == 0xFEBC639E) {
			    return (settings["EggHangar"]);
			  } else if (current.trackID == 0x1EF56CE1) {
			    return (settings["OutrunBay"]);
			  }
			}
		}
	}
}

isLoading
{
	return true;
}
