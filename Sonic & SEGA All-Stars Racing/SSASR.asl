// Autosplitter by Sora, R3FR4G, Jellyfisher and Jujstme
// Made only thanks to the contributions from above.
// Thanks to all guys who helped in writing this
// Coding: Jujstme
// contacts: just.tribe@gmail.com

state("Sonic & SEGA All-Stars Racing")
{
  byte runStart: 0x82A044;              // Self-explanatory. Becomes 1 and stays 1 while ingame
  byte raceType: 0x8E7068, 0xAD0;       // 0 = Grand Prix, 3 = Mission; It's the main menu option used to choose the game mode; Actually used only for splitting correctly
  byte missionEventGP: 0x9124F0, 0x14;	// Becomes 3 in cups in mission mode; Becomes 4 for all-cups runs. Used by the game to determine how many events are in each GP. It's an invalid pointer in any other mode. Used to distinguish between GP mode and single race
  byte cuphandler: 0x9124F4;            // Internal counter used by the game to determine which race of the cup you're playing into (0: first track; 1: second track; etc)
  byte ranking: 0x8F7A68, 0x4;          // Ranking system used in mission mode. (0 = AAA; 1 = AA, 2 = A, 3 = B, 4 = C, 5 = D, 6 = E. The game considers a mission cleared successfully only when you get at least an A rank
  byte runSplit: 0x8F7A6C;              // Self-explanatory. Becomes 1 or 2 at the end of every track or mission
  uint globalFrameCount: 0x8DCBF4;      // One of the variables used for calculating the IGT. This one starts when track finishes loading and stops / resets to 0 when the track unloads
  uint globalFrameCountAtGo: 0x8F7A80;	// The REAL IGT. It's a 50hz-based timer (50 = 1 second). Not really accurate but can be used in mission mode as there's no other way to reliably calculate the IGT
  byte currentLap: 0x8F7A68, 0x74;      // Reports which lap you're currently into. Lap 0 = start; Lap 4 = finish line crossed
  byte requiredLaps: 0x8F7A68, 0x84;    // Self explanatory. It's the number of laps required to complete a track. Usually 4 in single race. Mission mode uses 2 or 100, depending on the mission type. Almost all single races in mission mode use 3 (2 laps).
  uint lap0: 0x8F7A68, 0x6C, 0x0;       // Internal timer for lap 0 (before you cross the start line). Not super accurate but can be used for calculating the IGT in the middle of a race
  uint lap1: 0x8F7A68, 0x6C, 0x4;       // Internal timer for lap 1. Same as above
  uint lap2: 0x8F7A68, 0x6C, 0x8;       // Internal timer for lap 2. Same as above
  uint lap3: 0x8F7A68, 0x6C, 0xC;       // Internal timer for lap 3. Same as above
  uint totalLap: 0x8F7A68, 0x68;        // Reports the accurate timer for the race up to the previous lap. It's used to determine the time at the end of the race with 100% accuracy. For some reason the game multiplies the time by 204800 before saving it here, so remmeber to divide it by that same number to get the total time (in seconds)
}

init
{
//  // Little snippet that checks the version of the game for compatibility purpose
//  // and disables the autosplitter in case you loaded an incompatible version of the game
//  if (modules.First().ModuleMemorySize == 0xB4E000 || modules.First().ModuleMemorySize == 0x17DD000) {
    version = "steam/retail";
//  } else {
//    version = "unsupported";
//    MessageBox.Show("This game version is currently not supported.", "LiveSplit Auto Splitter - Unsupported Game Version");
//  }
}

startup
{
  vars.totaligt = 0;
  vars.racetime = 0; 
  vars.starttimeknockout = 0;
  // refreshRate = 60; // Used only during testing. No reason to force it.
  settings.Add("AAArankSplit", false, "All missions: split only at AAA rank");
  settings.SetToolTip("AAArankSplit", "If enabled, LiveSplit will trigger a split for All Mission categories only when you get a AAA rank.\nIf disabled, LiveSplit will trigger a split when you complete a mission successfully, regardless of the rank.\nYou need to enable this options if you wish to run the \"AAA\" subcategory of All Missions run.\n\nDefault: disabled");
  settings.Add("GPsplit", false, "All Cups: split only at the final race of each cup");
  settings.SetToolTip("GPsplit", "If enabled, LiveSplit will trigger a split for All Cups runs when you complete a cup.\nIf disabled, LiveSplit will trigger a split at the completion of each race.\n\nDefault: disabled");

  // Check if you're using RTA timing in LiveSplit and will eventually offer you to switch to GameTime
  if (timer.CurrentTimingMethod == TimingMethod.RealTime) {
    var timingMessage = MessageBox.Show (
    "This game uses Time without Loads (Game Time) as the main timing method.\n"+
    "LiveSplit is currently set to show Real Time (RTA).\n"+
    "Would you like to set the timing method to Game Time?",
    "Sonic & SEGA All-Stars Racing | LiveSplit",
    MessageBoxButtons.YesNo,MessageBoxIcon.Question);
    if (timingMessage == DialogResult.Yes) {
      timer.CurrentTimingMethod = TimingMethod.GameTime;
    }
  }
}

start
{
  // Reset the IGT variables if you reset a run
  vars.totaligt = 0;
  vars.racetime = 0;
  vars.starttimeknockout = 0;
   
  // The run starts when conferming selection of the first event in mission mode or in GP mode
  return (current.runStart == 1 && old.runStart == 0);
}

update
{
  // If the game version is unsupported, disable the autosplitter completely
  if (version == "unsupported") {
    return false;
  } else {
    // If you restart an event or a race, the IGT of the failed race is still considered and added
    // This script is also used to add the time of any completed event or race to the total time
    if (current.globalFrameCount < old.globalFrameCount) {
      vars.totaligt = vars.totaligt + vars.racetime;
      vars.racetime = 0;
    }

    // During a race or an event, the IGT is calculated by the game and then added to the total
    if (current.runSplit == 0) {
      // In normal races, the required number of laps is 3 or 4 (3 in most races in mission mode, 4 in races and cups)
      // In all other missions, lap count is always 2
      // We can conveniently use this as a criterion to discriminate between races and missions
      if (current.requiredLaps == 3) {          // Most races in mission mode have 2 laps (requiredLaps is 3)
        if (current.currentLap == 0) {
          vars.racetime = current.lap0;
        } else if (current.currentLap == 1) {
          vars.racetime = current.totalLap + current.lap1;
        } else if (current.currentLap == 2) {
          vars.racetime = current.totalLap + current.lap2;
        }
        vars.racetime = Math.Truncate((1000 * ((double)vars.racetime/204800))) / 1000;
      } else if (current.requiredLaps == 4) {   // All races in GP mode have 3 laps (requiredLaps is 4)
        if (current.currentLap == 0) {
          vars.racetime = current.lap0;
        } else if (current.currentLap == 1) {
          vars.racetime = current.totalLap + current.lap1;
        } else if (current.currentLap == 2) {
          vars.racetime = current.totalLap + current.lap2;
        } else if (current.currentLap == 3) {
          vars.racetime = current.totalLap + current.lap3;
        }
        vars.racetime = Math.Truncate((1000 * ((double)vars.racetime/204800))) / 1000;
      } else {                                  // All events which do not have a requiredLaps of 3 or 4 are missions
        // General behaviour for Mission mode
        // The script will use the internal frame counter to determine the time
        // By subtracting the frame counter to the value determined at the start of the race
        // Might be not 100% accurate but the difference doesn't matter for an All mission speedrun
	// Anyway, the game itself isn't precise with timing in missions
	// First, we detemine at which frame the event/mission starts...
        if (current.globalFrameCountAtGo != 0 && old.globalFrameCountAtGo == 0 && old.lap0 == 0) {
          vars.starttimeknockout = old.globalFrameCount;
        }
	// ...and then we calculate the frame difference to get the time  
        vars.racetime = (double)(current.globalFrameCount - vars.starttimeknockout) / 50;
        // But if the event hasn't started yet, we force racetime to be zero
	if (old.globalFrameCountAtGo == 0 && current.globalFrameCountAtGo == 0) vars.racetime = 0;
      }
    } else { 
      // This part refers to behaviour the game has to take when completing a race or an event
      // In normal races and cups, the game truncates the time to the third decimal. We're going to do the same for consistency purposes
      if (old.runSplit == 0) {
        if (current.requiredLaps == 3 || current.requiredLaps == 4) {
          vars.totaligt = vars.totaligt + Math.Truncate((1000 * ((double)current.totalLap/204800))) / 1000;
        } else {
          vars.totaligt = vars.totaligt + (double)(current.globalFrameCount - vars.starttimeknockout) / 50;
          vars.starttimeknockout = 0;
        }
        vars.racetime = 0;  // As the race time has been added to totaligt, we force racetime to be zero
      }
    }
  }		
}

split
{
  if (current.raceType == 0) {
    // In GP mode, split whenever you cross the finish line, regardless of anything
    if (settings["GPsplit"]) {
      return ((current.runSplit == 1 || current.runSplit == 2) && old.runSplit == 0 && old.cuphandler == 3);
    } else {
      return ((current.runSplit == 1 || current.runSplit == 2) && old.runSplit == 0);
    }
  } else if (current.raceType == 3) {
    // In mission mode, split when you complete an event successfully
    if ((current.runSplit == 1 || current.runSplit == 2) && old.runSplit == 0) {
      if (current.missionEventGP == 3) {
        if (settings["AAArankSplit"]) {
          return (old.cuphandler == 2 && current.ranking == 0);
        } else {
          return (old.cuphandler == 2 && current.ranking <= 2);
        }
      } else {
        if (settings["AAArankSplit"]) {
          return (current.ranking == 0);
        } else {
          return (current.ranking <= 2);
        }
      }
    }
  }
}

gameTime
{
  return TimeSpan.FromSeconds(vars.totaligt + vars.racetime);	
}

isLoading
{
  return true;
}
