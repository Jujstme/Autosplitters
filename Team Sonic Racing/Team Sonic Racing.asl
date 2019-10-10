// IGT timer autosplitter for Team Sonic Racing
// Coding: Jujstme
// Tester:  Nimputs
// Version: 1.4

state("GameApp_PcDx11_x64Final", "v1.1")
{
	byte teamadventurestart: 0x11325A0, 0x0;			// Stays 0 in the menu, becomes 1 as soon as you click on the team adventure mode
	byte runstart: 0x11456A8, 0x50, 0xD44;				// For other modes. Becomes 1 when you confirm the character selection
	float igt: 0x10B2FA4;								// starts at the start of every race and stops at the results screen
	float totalracetime: 0x10B18E8, 0x0, 0x110, 0x30;	// updates itself each time you complete a lap (final lap included)
	byte racecompleted: 0x10B1968;						// becomes 1 when a race or an event ends, regardless of anything
	byte requiredlaps : 0x10B18E8, 0x0, 0x110, 0x10;	// number of laps required to finish a race. It's set as 255 (FF) in special events where laps are irrelevant
	byte racestatus: 0x10B1920;							// 0 idle; 1 stage intro: 2 team intro; 5 ready; 6 racing; 7 race ended
	
	// Story mode variables
	byte stars1: 0x112DF98, 0x4A14;						// Nr. of stars in Team Adventure Chapter 1
	byte stars2: 0x112DF98, 0x4A18;						// Nr. of stars in Team Adventure Chapter 2
	byte stars3: 0x112DF98, 0x4A1C;						// Nr. of stars in Team Adventure Chapter 3
	byte stars4: 0x112DF98, 0x4A20;						// Nr. of stars in Team Adventure Chapter 4
	byte stars5: 0x112DF98, 0x4A24;						// Nr. of stars in Team Adventure Chapter 5
	byte stars6: 0x112DF98, 0x4A28;						// Nr. of stars in Team Adventure Chapter 6
	byte stars7: 0x112DF98, 0x4A2C;						// Nr. of stars in Team Adventure Chapter 7
	byte gamemode: 0x1135E6C;
	float totalracetimeadventure: 0x1132A98;	
}

state("GameApp_PcDx11_x64Final", "v1.0")
{
	byte teamadventurestart: 0x112B210, 0x0;			
	byte runstart: 0x113E368, 0x50, 0xD44;
	float igt : 0x10ABC14;								
	float totalracetime : 0x10AA550, 0x0, 0x110, 0x30;  
	byte racecompleted: 0x10AA690;                      
	byte requiredlaps : 0x10AA550, 0x0, 0x110, 0x10;    
	byte racestatus: 0x10AA588;							
	
	// Story mode variables	
	byte stars1: 0x1126B30, 0x4A14;
	byte stars2: 0x1126B30, 0x4A18;
	byte stars3: 0x1126B30, 0x4A1C;
	byte stars4: 0x1126B30, 0x4A20;
	byte stars5: 0x1126B30, 0x4A24;
	byte stars6: 0x1126B30, 0x4A28;
	byte stars7: 0x1126B30, 0x4A2C;
	byte gamemode: 0x112EBBC;
	float totalracetimeadventure: 0x112B708;
}

init
{
	if (modules.First().ModuleMemorySize == 367644672) version = "v1.1";
    if (modules.First().ModuleMemorySize == 388800512) version = "v1.0";
}

startup
{
   vars.totaligt = 0;
   vars.progressIGT = 0;
   refreshRate = 60;
}

start
{
   // Reset the IGT variables if you reset a run
   vars.totaligt = 0;
   vars.progressIGT = 0;
    
   // Autostart currently works only outside Team Adventure mode
	return(current.runstart == 1 || current.teamadventurestart == 1);
}


update
{
	// During a race, the IGT is added to the total
	if (current.racecompleted == 0)	{
	  vars.progressIGT = current.igt + vars.totaligt;
	  
	  // If you restart an event or a race, the IGT of the failed race is still considered
	  if (old.igt != 0 && current.igt == 0 && old.racestatus == 6) {
		vars.totaligt = old.igt + vars.totaligt;
		vars.progressIGT = vars.totaligt;
	  }
	}
	
	// How to behave the moment you complete a race:
	// The game truncates the time to the second decimal. We're going to do the same for consistency purposes
	if(current.racecompleted == 1 && old.racecompleted == 0)
	{
		vars.totaligt = (Math.Truncate(100 * current.totalracetime) / 100) + vars.totaligt;
		vars.progressIGT = vars.totaligt;
		
		// IF YOU ARE IN TEAM ADVENTURE AND YOU ARE DOING A SPECIAL CHALLENGE (eg. daredevil, eggpawn assault, etc.) THE ABOVE WON'T WORK
		if (current.gamemode == 0 && current.requiredlaps == 255) {
			vars.totaligt = (Math.Truncate(100 * current.totalracetimeadventure) / 100) + vars.totaligt;
			vars.progressIGT = vars.totaligt;
		}
	}
	
}

gameTime
{
	return TimeSpan.FromSeconds((double)vars.progressIGT);
}

split
{
	// If you are in adventure mode, split whenever the game gives you the stars at the end of the event
	if (current.gamemode == 0) {
	  return ((current.stars1 + current.stars2 + current.stars3 + current.stars4 + current.stars5 + current.stars6 + current.stars7) != (old.stars1 + old.stars2 + old.stars3 + old.stars4 + old.stars5 + old.stars6 + old.stars7));
	}
	else
	// else, split automatically once you reach the finish line
	{
	  return (current.racecompleted == 1 && old.racecompleted == 0);
	}
}

isLoading
{
	return true;
}