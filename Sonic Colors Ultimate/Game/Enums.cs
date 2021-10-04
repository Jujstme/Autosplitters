namespace LiveSplit.SonicColors
{
    internal static class Levels
    {
        internal const string TropicalResortAct1 = "stg110";
        internal const string TropicalResortAct2 = "stg130";
        internal const string TropicalResortAct3 = "stg120";
        internal const string TropicalResortAct4 = "stg140";
        internal const string TropicalResortAct5 = "stg150";
        internal const string TropicalResortAct6 = "stg160";
        internal const string TropicalResortBoss = "stg190";
        internal const string SweetMountainAct1 = "stg210";
        internal const string SweetMountainAct2 = "stg230";
        internal const string SweetMountainAct3 = "stg220";
        internal const string SweetMountainAct4 = "stg260";
        internal const string SweetMountainAct5 = "stg240";
        internal const string SweetMountainAct6 = "stg250";
        internal const string SweetMountainBoss = "stg290";
        internal const string StarlightCarnivalAct1 = "stg310";
        internal const string StarlightCarnivalAct2 = "stg330";
        internal const string StarlightCarnivalAct3 = "stg340";
        internal const string StarlightCarnivalAct4 = "stg350";
        internal const string StarlightCarnivalAct5 = "stg320";
        internal const string StarlightCarnivalAct6 = "stg360";
        internal const string StarlightCarnivalBoss = "stg390";
        internal const string PlanetWispAct1 = "stg410";
        internal const string PlanetWispAct2 = "stg440";
        internal const string PlanetWispAct3 = "stg450";
        internal const string PlanetWispAct4 = "stg430";
        internal const string PlanetWispAct5 = "stg460";
        internal const string PlanetWispAct6 = "stg420";
        internal const string PlanetWispBoss = "stg490";
        internal const string AquariumParkAct1 = "stg510";
        internal const string AquariumParkAct2 = "stg540";
        internal const string AquariumParkAct3 = "stg550";
        internal const string AquariumParkAct4 = "stg530";
        internal const string AquariumParkAct5 = "stg560";
        internal const string AquariumParkAct6 = "stg520";
        internal const string AquariumParkBoss = "stg590";
        internal const string AsteroidCoasterAct1 = "stg610";
        internal const string AsteroidCoasterAct2 = "stg630";
        internal const string AsteroidCoasterAct3 = "stg640";
        internal const string AsteroidCoasterAct4 = "stg650";
        internal const string AsteroidCoasterAct5 = "stg660";
        internal const string AsteroidCoasterAct6 = "stg620";
        internal const string AsteroidCoasterBoss = "stg690";
        internal const string TerminalVelocityAct1 = "stg710";
        internal const string TerminalVelocityBoss = "stg790";
        internal const string TerminalVelocityAct2 = "stg720";
        internal const string SonicSimulator1_1 = "stgD10";
        internal const string SonicSimulator1_2 = "stgB20";
        internal const string SonicSimulator1_3 = "stgE50";
        internal const string SonicSimulator2_1 = "stgD20";
        internal const string SonicSimulator2_2 = "stgB30";
        internal const string SonicSimulator2_3 = "stgF30";
        internal const string SonicSimulator3_1 = "stgG10";
        internal const string SonicSimulator3_2 = "stgG30";
        internal const string SonicSimulator3_3 = "stgA10";
        internal const string SonicSimulator4_1 = "stgD30";
        internal const string SonicSimulator4_2 = "stgG20";
        internal const string SonicSimulator4_3 = "stgC50";
        internal const string SonicSimulator5_1 = "stgE30";
        internal const string SonicSimulator5_2 = "stgB10";
        internal const string SonicSimulator5_3 = "stgE40";
        internal const string SonicSimulator6_1 = "stgG40";
        internal const string SonicSimulator6_2 = "stgC40";
        internal const string SonicSimulator6_3 = "stgF40";
        internal const string SonicSimulator7_1 = "stgA30";
        internal const string SonicSimulator7_2 = "stgE20";
        internal const string SonicSimulator7_3 = "stgC10";
    }

    partial class Component
    {
        private bool splitEnabled()
        {
            bool shouldsplitTR1 = (string)vars.watchers["levelID"].Old == Levels.TropicalResortAct1 && settings.tropicalResortAct1;
            bool shouldsplitTR2 = (string)vars.watchers["levelID"].Old == Levels.TropicalResortAct2 && settings.tropicalResortAct2;
            bool shouldsplitTR3 = (string)vars.watchers["levelID"].Old == Levels.TropicalResortAct3 && settings.tropicalResortAct3;
            bool shouldsplitTR4 = (string)vars.watchers["levelID"].Old == Levels.TropicalResortAct4 && settings.tropicalResortAct4;
            bool shouldsplitTR5 = (string)vars.watchers["levelID"].Old == Levels.TropicalResortAct5 && settings.tropicalResortAct5;
            bool shouldsplitTR6 = (string)vars.watchers["levelID"].Old == Levels.TropicalResortAct6 && settings.tropicalResortAct6;
            bool shouldsplitTRB = (string)vars.watchers["levelID"].Old == Levels.TropicalResortBoss && settings.tropicalResortBoss;
            bool shouldsplitSM1 = (string)vars.watchers["levelID"].Old == Levels.SweetMountainAct1 && settings.sweetMountainAct1;
            bool shouldsplitSM2 = (string)vars.watchers["levelID"].Old == Levels.SweetMountainAct2 && settings.sweetMountainAct2;
            bool shouldsplitSM3 = (string)vars.watchers["levelID"].Old == Levels.SweetMountainAct3 && settings.sweetMountainAct3;
            bool shouldsplitSM4 = (string)vars.watchers["levelID"].Old == Levels.SweetMountainAct4 && settings.sweetMountainAct4;
            bool shouldsplitSM5 = (string)vars.watchers["levelID"].Old == Levels.SweetMountainAct5 && settings.sweetMountainAct5;
            bool shouldsplitSM6 = (string)vars.watchers["levelID"].Old == Levels.SweetMountainAct6 && settings.sweetMountainAct6;
            bool shouldsplitSMB = (string)vars.watchers["levelID"].Old == Levels.SweetMountainBoss && settings.sweetMountainBoss;
            bool shouldsplitSC1 = (string)vars.watchers["levelID"].Old == Levels.StarlightCarnivalAct1 && settings.starlightCarnivalAct1;
            bool shouldsplitSC2 = (string)vars.watchers["levelID"].Old == Levels.StarlightCarnivalAct2 && settings.starlightCarnivalAct2;
            bool shouldsplitSC3 = (string)vars.watchers["levelID"].Old == Levels.StarlightCarnivalAct3 && settings.starlightCarnivalAct3;
            bool shouldsplitSC4 = (string)vars.watchers["levelID"].Old == Levels.StarlightCarnivalAct4 && settings.starlightCarnivalAct4;
            bool shouldsplitSC5 = (string)vars.watchers["levelID"].Old == Levels.StarlightCarnivalAct5 && settings.starlightCarnivalAct5;
            bool shouldsplitSC6 = (string)vars.watchers["levelID"].Old == Levels.StarlightCarnivalAct6 && settings.starlightCarnivalAct6;
            bool shouldsplitSCB = (string)vars.watchers["levelID"].Old == Levels.StarlightCarnivalBoss && settings.starlightCarnivalBoss;
            bool shouldsplitPW1 = (string)vars.watchers["levelID"].Old == Levels.PlanetWispAct1 && settings.planetWispAct1;
            bool shouldsplitPW2 = (string)vars.watchers["levelID"].Old == Levels.PlanetWispAct2 && settings.planetWispAct2;
            bool shouldsplitPW3 = (string)vars.watchers["levelID"].Old == Levels.PlanetWispAct3 && settings.planetWispAct3;
            bool shouldsplitPW4 = (string)vars.watchers["levelID"].Old == Levels.PlanetWispAct4 && settings.planetWispAct4;
            bool shouldsplitPW5 = (string)vars.watchers["levelID"].Old == Levels.PlanetWispAct5 && settings.planetWispAct5;
            bool shouldsplitPW6 = (string)vars.watchers["levelID"].Old == Levels.PlanetWispAct6 && settings.planetWispAct6;
            bool shouldsplitPWB = (string)vars.watchers["levelID"].Old == Levels.PlanetWispBoss && settings.planetWispBoss;
            bool shouldsplitAP1 = (string)vars.watchers["levelID"].Old == Levels.AquariumParkAct1 && settings.aquariumParkAct1;
            bool shouldsplitAP2 = (string)vars.watchers["levelID"].Old == Levels.AquariumParkAct2 && settings.aquariumParkAct2;
            bool shouldsplitAP3 = (string)vars.watchers["levelID"].Old == Levels.AquariumParkAct3 && settings.aquariumParkAct3;
            bool shouldsplitAP4 = (string)vars.watchers["levelID"].Old == Levels.AquariumParkAct4 && settings.aquariumParkAct4;
            bool shouldsplitAP5 = (string)vars.watchers["levelID"].Old == Levels.AquariumParkAct5 && settings.aquariumParkAct5;
            bool shouldsplitAP6 = (string)vars.watchers["levelID"].Old == Levels.AquariumParkAct6 && settings.aquariumParkAct6;
            bool shouldsplitAPB = (string)vars.watchers["levelID"].Old == Levels.AquariumParkBoss && settings.aquariumParkBoss;
            bool shouldsplitAC1 = (string)vars.watchers["levelID"].Old == Levels.AsteroidCoasterAct1 && settings.asteroidCoasterAct1;
            bool shouldsplitAC2 = (string)vars.watchers["levelID"].Old == Levels.AsteroidCoasterAct2 && settings.asteroidCoasterAct2;
            bool shouldsplitAC3 = (string)vars.watchers["levelID"].Old == Levels.AsteroidCoasterAct3 && settings.asteroidCoasterAct3;
            bool shouldsplitAC4 = (string)vars.watchers["levelID"].Old == Levels.AsteroidCoasterAct4 && settings.asteroidCoasterAct4;
            bool shouldsplitAC5 = (string)vars.watchers["levelID"].Old == Levels.AsteroidCoasterAct5 && settings.asteroidCoasterAct5;
            bool shouldsplitAC6 = (string)vars.watchers["levelID"].Old == Levels.AsteroidCoasterAct6 && settings.asteroidCoasterAct6;
            bool shouldsplitACB = (string)vars.watchers["levelID"].Old == Levels.AsteroidCoasterBoss && settings.asteroidCoasterBoss;
            bool shouldsplitTV1 = (string)vars.watchers["levelID"].Old == Levels.TerminalVelocityAct1 && settings.terminalVelocityAct1;
            bool shouldsplitTVB = (string)vars.watchers["levelID"].Old == Levels.TerminalVelocityBoss && settings.terminalVelocityBoss;
            bool shouldsplitTV2 = (string)vars.watchers["levelID"].Old == Levels.TerminalVelocityAct2 && settings.terminalVelocityAct2;
            bool shouldsplit1_1 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator1_1 && settings.sonicSim1_1;
            bool shouldsplit1_2 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator1_2 && settings.sonicSim1_2;
            bool shouldsplit1_3 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator1_3 && settings.sonicSim1_3;
            bool shouldsplit2_1 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator2_1 && settings.sonicSim2_1;
            bool shouldsplit2_2 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator2_2 && settings.sonicSim2_2;
            bool shouldsplit2_3 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator2_3 && settings.sonicSim2_3;
            bool shouldsplit3_1 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator3_1 && settings.sonicSim3_1;
            bool shouldsplit3_2 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator3_2 && settings.sonicSim3_2;
            bool shouldsplit3_3 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator3_3 && settings.sonicSim3_3;
            bool shouldsplit4_1 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator4_1 && settings.sonicSim4_1;
            bool shouldsplit4_2 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator4_2 && settings.sonicSim4_2;
            bool shouldsplit4_3 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator4_3 && settings.sonicSim4_3;
            bool shouldsplit5_1 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator5_1 && settings.sonicSim5_1;
            bool shouldsplit5_2 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator5_2 && settings.sonicSim5_2;
            bool shouldsplit5_3 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator5_3 && settings.sonicSim5_3;
            bool shouldsplit6_1 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator6_1 && settings.sonicSim6_1;
            bool shouldsplit6_2 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator6_2 && settings.sonicSim6_2;
            bool shouldsplit6_3 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator6_3 && settings.sonicSim6_3;
            bool shouldsplit7_1 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator7_1 && settings.sonicSim7_1;
            bool shouldsplit7_2 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator7_2 && settings.sonicSim7_2;
            bool shouldsplit7_3 = (string)vars.watchers["levelID"].Old == Levels.SonicSimulator7_3 && settings.sonicSim7_3;

            return shouldsplitTR1 || shouldsplitTR2 || shouldsplitTR3 || shouldsplitTR4 || shouldsplitTR5 || shouldsplitTR6 || shouldsplitTRB ||
                shouldsplitSM1 || shouldsplitSM2 || shouldsplitSM3 || shouldsplitSM4 || shouldsplitSM5 || shouldsplitSM6 || shouldsplitSMB ||
                shouldsplitSC1 || shouldsplitSC2 || shouldsplitSC3 || shouldsplitSC4 || shouldsplitSC5 || shouldsplitSC6 || shouldsplitSCB ||
                shouldsplitPW1 || shouldsplitPW2 || shouldsplitPW3 || shouldsplitPW4 || shouldsplitPW5 || shouldsplitPW6 || shouldsplitPWB ||
                shouldsplitAP1 || shouldsplitAP2 || shouldsplitAP3 || shouldsplitAP4 || shouldsplitAP5 || shouldsplitAP6 || shouldsplitAPB ||
                shouldsplitAC1 || shouldsplitAC2 || shouldsplitAC3 || shouldsplitAC4 || shouldsplitAC5 || shouldsplitAC6 || shouldsplitACB ||
                shouldsplitTV1 || shouldsplitTVB || shouldsplitTV2 ||
                shouldsplit1_1 || shouldsplit1_2 || shouldsplit1_3 || shouldsplit2_1 || shouldsplit2_2 || shouldsplit2_3 || shouldsplit3_1 ||
                shouldsplit3_2 || shouldsplit3_3 || shouldsplit4_1 || shouldsplit4_2 || shouldsplit4_3 || shouldsplit5_1 || shouldsplit5_2 ||
                shouldsplit5_3 || shouldsplit6_1 || shouldsplit6_2 || shouldsplit6_3 || shouldsplit7_1 || shouldsplit7_2 || shouldsplit7_3;
        }
    }

}
