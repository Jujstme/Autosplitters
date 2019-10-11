// IGT timer autosplitter
// Coding: Jujstme
// Version: 1.0

state("ASN_App_PcDx9_Final")
{
	byte runstart: 0x852918;
	float igt : 0x7CE980;								// starts at the start of every race amd stops at the results screen
	float totalracetime : 0x7CE920, 0x0, 0xC1B8, 0x28;        // updates itself each time you complete a lap (final lap included)
	byte racecompleted: 0x7CE930;                       // becomes 1 when a race or an event ends, regardless of anything
	byte racestatus: 0x7CE944;							// 0 idle; 1 stage intro; 4 racing; 5 race ended
	
	/// byte modeselect: 0x856890;
	/// byte totalstars: 0x7D07A0, 0xF74;
	byte endcredits: 0x9FD48C;
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
   return (current.runstart == 1);
}


update
{
	// During a race, the IGT is added to the total
	if (current.racecompleted == 0)	{
	  vars.progressIGT = current.igt + vars.totaligt;
	  
	  // If you restart an event or a race, the IGT of the failed race is still considered
	  if (old.igt != 0 && current.igt == 0 && old.racestatus == 4) {
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
	}
}

gameTime
{
	return TimeSpan.FromSeconds((double)vars.progressIGT);
}

split
{
  	return ((current.racecompleted == 1 && old.racecompleted == 0) || (current.endcredits == 1 && old.endcredits == 0));
}

isLoading
{
	return true ;
}