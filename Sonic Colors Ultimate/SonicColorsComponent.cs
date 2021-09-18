using LiveSplit.Model;
using LiveSplit.UI.Components;
using LiveSplit.UI;
using System;
using System.Diagnostics;
using System.Reflection;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Xml;
using System.Windows.Forms;
using System.Collections.Generic;
using LiveSplit.ComponentUtil;
using System.Threading.Tasks;
using System.Threading;

namespace LiveSplit.SonicColors
{
    class SonicColorsComponent : LogicComponent
    {
        public Game vars = new Game();
        public override string ComponentName => vars.GameName;
        public SonicColorsSettings settings { get; set; }
        public Process game;
        public TimerModel _timer;
        private MemoryWatcherList memory = new MemoryWatcherList();

        public SonicColorsComponent(LiveSplitState state)
        {
            _timer = new TimerModel { CurrentState = state };
            _timer.CurrentState.OnStart += State_OnStart;
            _timer.CurrentState.OnReset += State_OnReset;
            settings = new SonicColorsSettings();
        }

        public override void Dispose()
        {
            _timer.CurrentState.OnStart -= State_OnStart;
            _timer.CurrentState.OnReset -= State_OnReset;
            settings.Dispose();
        }

        private void State_OnReset(object sender, TimerPhase value)
        {

        }

        private void State_OnStart(object sender, EventArgs e)
        {
            _timer.InitializeGameTime();
            if (settings.useIGT) _timer.CurrentState.IsGameTimePaused = true;
            vars.totalIGT = 0;
        }

        public override XmlNode GetSettings(XmlDocument document)
        {
            return this.settings.GetSettings(document);
        }

        public override Control GetSettingsControl(LayoutMode mode)
        {
            return this.settings;
        }

        public override void SetSettings(XmlNode settings)
        {
            this.settings.SetSettings(settings);
        }

        public override void Update(IInvalidator invalidator, LiveSplitState state, float width, float height, LayoutMode mode)
        {
            // Settings
            if (settings.setSplits)
            {
                Task.Run(() => setSplits());
                settings.setSplits = false;
            }

            // First, try opening the game process
            // If the game isn't running, return
            if (game == null || game.HasExited) if (!this.TryGetGameProcess()) return;

            // Update watchers variable
            memory.UpdateAll(game);
            vars.currentBools["goalRingReached"] = ((byte)memory["goalRingReached"].Current & (1 << 5)) != 0;
            vars.oldBools["goalRingReached"] = ((byte)memory["goalRingReached"].Old & (1 << 5)) != 0;
            vars.old_gameIGT = vars.gameIGT;

            // Assume the IGT is always zero if you are in the credits stage or outside a stage
            // This prevents a possible overflowException that sometimes occurs if you load the credits while the timer is running
            // This behaviour is caused by the IGT often reporting insanely huge IGT values inside the credits
            if ((byte)memory["levelID_numeric"].Current == 8 || (byte)memory["levelID_numeric"].Current == 0) memory["IGT"].Current = 0f;

            // The game calculates the IGT for each stage by simply truncating the float value to the second decimal.
            // In order to make the timer match the displayed IGT inside the game, we need to do the same.
            // This also implicitly converts the IGT from float to double (C# really doesn't like to work with floats).
            vars.gameIGT = Math.Truncate((float)memory["IGT"].Current * 100) / 100;

            // Another IGT logic: Use an internal totalIGT variable in which we will store the accumulated IGT every time the game IGT resets (eg. when exiting a level)
            if ((float)memory["IGT"].Old != 0 && (float)memory["IGT"].Current == 0) vars.totalIGT += vars.old_gameIGT;

            // These variables need to be managed when the run hasn't started yet
            // You can put these inside the start section of the autosplitter but you risk the code not being run if the user disables automatic start
            if (_timer.CurrentState.CurrentPhase == TimerPhase.NotRunning) vars.isEggShuttle = (byte)memory["eggShuttle_totalStages"].Current > 0; // Check whether you're in Egg Shuttle or not. This value must not change once the timer started to run.

            // Game Time
            if (settings.useIGT) _timer.CurrentState.SetGameTime(TimeSpan.FromSeconds(vars.totalIGT + vars.gameIGT));

            // Start trigger
            if (_timer.CurrentState.CurrentPhase == TimerPhase.NotRunning)
            {
                bool startTrigger;
                if (vars.isEggShuttle)
                {
                    startTrigger = (string)memory["levelID"].Current == vars.orderedLevelIDs[0] && (byte)memory["levelID_numeric"].Old == 0 && memory["levelID_numeric"].Changed;
                }
                else
                {
                    startTrigger = (byte)memory["runStart"].Old == 35 && (byte)memory["runStart"].Current == 110 && (sbyte)memory["TR1rank"].Current == -1;
                }
                if (startTrigger && settings.runStart) _timer.Start();
            }

            // Reset Trigger
            if (_timer.CurrentState.CurrentPhase == TimerPhase.Running)
            {
                bool resetTrigger;
                if (vars.isEggShuttle)
                {
                    // In Egg Shuttle, a reset is triggered when you exit an uncompleted stage
                    // which means you're giving up the run or restarting another one
                    resetTrigger = (float)memory["IGT"].Old != 0 && (float)memory["IGT"].Current == 0 && !vars.oldBools["goalRingReached"];
                }
                else
                {
                    // A reset must always be triggered whenever you delete your save file
                    resetTrigger = (byte)memory["runStart"].Old == 110 && (byte)memory["runStart"].Current == 35;
                }
                if (resetTrigger && settings.runReset) _timer.Reset();
            }

            // Split trigger
            if (_timer.CurrentState.CurrentPhase == TimerPhase.Running)
            {
                if (memory["levelID"].Current == null || (byte)memory["levelID_numeric"].Current == 8) return;
                bool splitTrigger = false;
                if (vars.isEggShuttle)
                {
                    bool isLastLevel = (byte)memory["eggShuttle_progressiveID"].Old == (byte)memory["eggShuttle_totalStages"].Current - 1;
                    if (!isLastLevel)
                    {
                        splitTrigger = (byte)memory["eggShuttle_progressiveID"].Current == (byte)memory["eggShuttle_progressiveID"].Old + 1 && splitEnabled();
                    }
                    else
                    {
                        splitTrigger = vars.currentBools["goalRingReached"] && !vars.oldBools["goalRingReached"] && splitEnabled();
                    }
                }
                else
                {
                    bool isTV2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[44];
                    if (!isTV2)
                    {
                        splitTrigger = !vars.currentBools["goalRingReached"] && vars.oldBools["goalRingReached"] && splitEnabled();
                    }
                    else
                    {
                        splitTrigger = vars.currentBools["goalRingReached"] && !vars.oldBools["goalRingReached"] && settings.terminalVelocityAct2;
                    }
                }
                if (splitTrigger) _timer.Split();
            }
        }

        private bool splitEnabled()
        {
            bool shouldsplitTR1 = (string)memory["levelID"].Old == vars.orderedLevelIDs[0] && settings.tropicalResortAct1;
            bool shouldsplitTR2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[1] && settings.tropicalResortAct2;
            bool shouldsplitTR3 = (string)memory["levelID"].Old == vars.orderedLevelIDs[2] && settings.tropicalResortAct3;
            bool shouldsplitTR4 = (string)memory["levelID"].Old == vars.orderedLevelIDs[3] && settings.tropicalResortAct4;
            bool shouldsplitTR5 = (string)memory["levelID"].Old == vars.orderedLevelIDs[4] && settings.tropicalResortAct5;
            bool shouldsplitTR6 = (string)memory["levelID"].Old == vars.orderedLevelIDs[5] && settings.tropicalResortAct6;
            bool shouldsplitTRB = (string)memory["levelID"].Old == vars.orderedLevelIDs[6] && settings.tropicalResortBoss;
            bool shouldsplitSM1 = (string)memory["levelID"].Old == vars.orderedLevelIDs[7] && settings.sweetMountainAct1;
            bool shouldsplitSM2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[8] && settings.sweetMountainAct2;
            bool shouldsplitSM3 = (string)memory["levelID"].Old == vars.orderedLevelIDs[9] && settings.sweetMountainAct3;
            bool shouldsplitSM4 = (string)memory["levelID"].Old == vars.orderedLevelIDs[10] && settings.sweetMountainAct4;
            bool shouldsplitSM5 = (string)memory["levelID"].Old == vars.orderedLevelIDs[11] && settings.sweetMountainAct5;
            bool shouldsplitSM6 = (string)memory["levelID"].Old == vars.orderedLevelIDs[12] && settings.sweetMountainAct6;
            bool shouldsplitSMB = (string)memory["levelID"].Old == vars.orderedLevelIDs[13] && settings.sweetMountainBoss;
            bool shouldsplitSC1 = (string)memory["levelID"].Old == vars.orderedLevelIDs[14] && settings.starlightCarnivalAct1;
            bool shouldsplitSC2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[15] && settings.starlightCarnivalAct2;
            bool shouldsplitSC3 = (string)memory["levelID"].Old == vars.orderedLevelIDs[16] && settings.starlightCarnivalAct3;
            bool shouldsplitSC4 = (string)memory["levelID"].Old == vars.orderedLevelIDs[17] && settings.starlightCarnivalAct4;
            bool shouldsplitSC5 = (string)memory["levelID"].Old == vars.orderedLevelIDs[18] && settings.starlightCarnivalAct5;
            bool shouldsplitSC6 = (string)memory["levelID"].Old == vars.orderedLevelIDs[19] && settings.starlightCarnivalAct6;
            bool shouldsplitSCB = (string)memory["levelID"].Old == vars.orderedLevelIDs[20] && settings.starlightCarnivalBoss;
            bool shouldsplitPW1 = (string)memory["levelID"].Old == vars.orderedLevelIDs[21] && settings.planetWispAct1;
            bool shouldsplitPW2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[22] && settings.planetWispAct2;
            bool shouldsplitPW3 = (string)memory["levelID"].Old == vars.orderedLevelIDs[23] && settings.planetWispAct3;
            bool shouldsplitPW4 = (string)memory["levelID"].Old == vars.orderedLevelIDs[24] && settings.planetWispAct4;
            bool shouldsplitPW5 = (string)memory["levelID"].Old == vars.orderedLevelIDs[25] && settings.planetWispAct5;
            bool shouldsplitPW6 = (string)memory["levelID"].Old == vars.orderedLevelIDs[26] && settings.planetWispAct6;
            bool shouldsplitPWB = (string)memory["levelID"].Old == vars.orderedLevelIDs[27] && settings.planetWispBoss;
            bool shouldsplitAP1 = (string)memory["levelID"].Old == vars.orderedLevelIDs[28] && settings.aquariumParkAct1;
            bool shouldsplitAP2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[29] && settings.aquariumParkAct2;
            bool shouldsplitAP3 = (string)memory["levelID"].Old == vars.orderedLevelIDs[30] && settings.aquariumParkAct3;
            bool shouldsplitAP4 = (string)memory["levelID"].Old == vars.orderedLevelIDs[31] && settings.aquariumParkAct4;
            bool shouldsplitAP5 = (string)memory["levelID"].Old == vars.orderedLevelIDs[32] && settings.aquariumParkAct5;
            bool shouldsplitAP6 = (string)memory["levelID"].Old == vars.orderedLevelIDs[33] && settings.aquariumParkAct6;
            bool shouldsplitAPB = (string)memory["levelID"].Old == vars.orderedLevelIDs[34] && settings.aquariumParkBoss;
            bool shouldsplitAC1 = (string)memory["levelID"].Old == vars.orderedLevelIDs[35] && settings.asteroidCoasterAct1;
            bool shouldsplitAC2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[36] && settings.asteroidCoasterAct2;
            bool shouldsplitAC3 = (string)memory["levelID"].Old == vars.orderedLevelIDs[37] && settings.asteroidCoasterAct3;
            bool shouldsplitAC4 = (string)memory["levelID"].Old == vars.orderedLevelIDs[38] && settings.asteroidCoasterAct4;
            bool shouldsplitAC5 = (string)memory["levelID"].Old == vars.orderedLevelIDs[39] && settings.asteroidCoasterAct5;
            bool shouldsplitAC6 = (string)memory["levelID"].Old == vars.orderedLevelIDs[40] && settings.asteroidCoasterAct6;
            bool shouldsplitACB = (string)memory["levelID"].Old == vars.orderedLevelIDs[41] && settings.asteroidCoasterBoss;
            bool shouldsplitTV1 = (string)memory["levelID"].Old == vars.orderedLevelIDs[42] && settings.terminalVelocityAct1;
            bool shouldsplitTVB = (string)memory["levelID"].Old == vars.orderedLevelIDs[43] && settings.terminalVelocityBoss;
            bool shouldsplitTV2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[44] && settings.terminalVelocityAct2;
            bool shouldsplit1_1 = (string)memory["levelID"].Old == vars.orderedLevelIDs[45] && settings.sonicSim1_1;
            bool shouldsplit1_2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[46] && settings.sonicSim1_2;
            bool shouldsplit1_3 = (string)memory["levelID"].Old == vars.orderedLevelIDs[47] && settings.sonicSim1_3;
            bool shouldsplit2_1 = (string)memory["levelID"].Old == vars.orderedLevelIDs[48] && settings.sonicSim2_1;
            bool shouldsplit2_2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[49] && settings.sonicSim2_2;
            bool shouldsplit2_3 = (string)memory["levelID"].Old == vars.orderedLevelIDs[50] && settings.sonicSim2_3;
            bool shouldsplit3_1 = (string)memory["levelID"].Old == vars.orderedLevelIDs[51] && settings.sonicSim3_1;
            bool shouldsplit3_2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[52] && settings.sonicSim3_2;
            bool shouldsplit3_3 = (string)memory["levelID"].Old == vars.orderedLevelIDs[53] && settings.sonicSim3_3;
            bool shouldsplit4_1 = (string)memory["levelID"].Old == vars.orderedLevelIDs[54] && settings.sonicSim4_1;
            bool shouldsplit4_2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[55] && settings.sonicSim4_2;
            bool shouldsplit4_3 = (string)memory["levelID"].Old == vars.orderedLevelIDs[56] && settings.sonicSim4_3;
            bool shouldsplit5_1 = (string)memory["levelID"].Old == vars.orderedLevelIDs[57] && settings.sonicSim5_1;
            bool shouldsplit5_2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[58] && settings.sonicSim5_2;
            bool shouldsplit5_3 = (string)memory["levelID"].Old == vars.orderedLevelIDs[59] && settings.sonicSim5_3;
            bool shouldsplit6_1 = (string)memory["levelID"].Old == vars.orderedLevelIDs[60] && settings.sonicSim6_1;
            bool shouldsplit6_2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[61] && settings.sonicSim6_2;
            bool shouldsplit6_3 = (string)memory["levelID"].Old == vars.orderedLevelIDs[62] && settings.sonicSim6_3;
            bool shouldsplit7_1 = (string)memory["levelID"].Old == vars.orderedLevelIDs[63] && settings.sonicSim7_1;
            bool shouldsplit7_2 = (string)memory["levelID"].Old == vars.orderedLevelIDs[64] && settings.sonicSim7_2;
            bool shouldsplit7_3 = (string)memory["levelID"].Old == vars.orderedLevelIDs[65] && settings.sonicSim7_3;

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

        private bool TryGetGameProcess()
        {
            game = Process.GetProcessesByName(vars.ExeName).FirstOrDefault(p => !p.HasExited);
            if (game == null) return false;

            IntPtr ptr = IntPtr.Zero;
            var scanner = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);
            memory = new MemoryWatcherList();

            // Run start (Any% and All Chaos Emeralds)
            // Corresponds to the "name" assigned to the internal savefile
            // New game = "########"
            // Otherwise = "no-name"
            // Can be used for signalling a reset
            ptr = scanner.Scan(new SigScanTarget(5,
                "74 2B",                 // je "Sonic Colors - Ultimate.exe"+16F3948
                "48 8B 0D ????????"));   // mov rcx,["Sonic Colors - Ultimate.exe"+52462A8]
            if (ptr == IntPtr.Zero) throw new Exception("Could not find address - stage completion pointers");
            memory.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x60, 0x120)) { Name = "runStart" });
            memory.Add(new MemoryWatcher<sbyte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x60, 0x1CC)) { Name = "TR1rank" });  // Must be FF in a new game

            // Current level data pointer
            // This region of memory contains basic data about the current level you're in, such as IGT, rings, score, etc. 
            // Also has a lot of flags (inside bitmasks) I didn't bother to investigate
            ptr = scanner.Scan(new SigScanTarget(5,
               "31 C0",                 // xor eax,eax
               "48 89 05 ????????"));   // mov ["Sonic Colors - Ultimate.exe"+52465C0],rax
            if (ptr == IntPtr.Zero) throw new Exception("Could not find address - level data pointer!");
            memory.Add(new MemoryWatcher<float>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x0, 0x270)) { Name = "IGT", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });
            memory.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x0, 0x110))  { Name = "goalRingReached", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull }); // Bit 5 gets flipped th emoment the stage is reported by the game as complete and all in-level events stop (eg. IGT stops)                                                                                                                                                                  // Level ID
            memory.Add(new StringWatcher(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x0, 0xE0), 6)      { Name = "levelID" }); // It's a 6-character ID that uniquely reports the level you're in. The IDs are the same as in the Wii version of the game. Check Wii's actstgmission.lua for details
            memory.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x0, 0xE0))   { Name = "levelID_numeric", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });

            // Egg Shuttle data pointer
            // This memory region becomes accessible only when you're inside Egg Shuttle
            ptr = scanner.Scan(new SigScanTarget(5,
            "76 0C",                 // jna "Sonic Colors - Ultimate.exe"+16DF25C
            "48 8B 0D ????????"));   // mov rcx,["Sonic colors - Ultimate.exe"+5245658]
            if (ptr == IntPtr.Zero) throw new Exception("Could not find address - Egg Shuttle data!");
            // Egg Shuttle total levels (indicates the total number of stages included in Egg Shuttle mode)
            memory.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x8, 0x38, 0x68, 0x110, 0x0)) { Name = "eggShuttle_totalStages", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull }); // This value is always above 0 so it can be used to report whether you're in egg shuttle or not
            memory.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x8, 0x38, 0x68, 0x110, 0xB8)) { Name = "eggShuttle_progressiveID", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull }); // Indicates level progression inside Egg Shuttle. Goes from 0 to 44 (44 = Terminal Velocity Act 2). It techically also goes to 45 at the final results screen after Terminal Velocity Act 

            return true;
        }

        void setSplits()
        {
            var question = MessageBox.Show("This will set up your splits according to your selected autosplitting options.\n" +
                            "WARNING: Any existing PB recorded for the current layout will be deleted.\n\n" +
                            "Do you want to continue?", "Livesplit - Sonic Colors: Ultimate", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
            if (question == DialogResult.No) return;
            _timer.CurrentState.Run.Clear();
            if (settings.tropicalResortAct1) _timer.CurrentState.Run.AddSegment("Tropical Resort 1");
            if (settings.tropicalResortAct2) _timer.CurrentState.Run.AddSegment("Tropical Resort 2");
            if (settings.tropicalResortAct3) _timer.CurrentState.Run.AddSegment("Tropical Resort 3");
            if (settings.tropicalResortAct4) _timer.CurrentState.Run.AddSegment("Tropical Resort 4");
            if (settings.tropicalResortAct5) _timer.CurrentState.Run.AddSegment("Tropical Resort 5");
            if (settings.tropicalResortAct6) _timer.CurrentState.Run.AddSegment("Tropical Resort 6");
            if (settings.tropicalResortBoss) _timer.CurrentState.Run.AddSegment("Tropical Resort Boss");
            if (settings.sweetMountainAct1) _timer.CurrentState.Run.AddSegment("Sweet Mountain 1");
            if (settings.sweetMountainAct2) _timer.CurrentState.Run.AddSegment("Sweet Mountain 2");
            if (settings.sweetMountainAct3) _timer.CurrentState.Run.AddSegment("Sweet Mountain 3");
            if (settings.sweetMountainAct4) _timer.CurrentState.Run.AddSegment("Sweet Mountain 4");
            if (settings.sweetMountainAct5) _timer.CurrentState.Run.AddSegment("Sweet Mountain 5");
            if (settings.sweetMountainAct6) _timer.CurrentState.Run.AddSegment("Sweet Mountain 6");
            if (settings.sweetMountainBoss) _timer.CurrentState.Run.AddSegment("Sweet Mountain Boss");
            if (settings.starlightCarnivalAct1) _timer.CurrentState.Run.AddSegment("Starlight Carnival 1");
            if (settings.starlightCarnivalAct2) _timer.CurrentState.Run.AddSegment("Starlight Carnival 2");
            if (settings.starlightCarnivalAct3) _timer.CurrentState.Run.AddSegment("Starlight Carnival 3");
            if (settings.starlightCarnivalAct4) _timer.CurrentState.Run.AddSegment("Starlight Carnival 4");
            if (settings.starlightCarnivalAct5) _timer.CurrentState.Run.AddSegment("Starlight Carnival 5");
            if (settings.starlightCarnivalAct6) _timer.CurrentState.Run.AddSegment("Starlight Carnival 6");
            if (settings.starlightCarnivalBoss) _timer.CurrentState.Run.AddSegment("Starlight Carnival Boss");
            if (settings.planetWispAct1) _timer.CurrentState.Run.AddSegment("Planet Wisp 1");
            if (settings.planetWispAct2) _timer.CurrentState.Run.AddSegment("Planet Wisp 2");
            if (settings.planetWispAct3) _timer.CurrentState.Run.AddSegment("Planet Wisp 3");
            if (settings.planetWispAct4) _timer.CurrentState.Run.AddSegment("Planet Wisp 4");
            if (settings.planetWispAct5) _timer.CurrentState.Run.AddSegment("Planet Wisp 5");
            if (settings.planetWispAct6) _timer.CurrentState.Run.AddSegment("Planet Wisp 6");
            if (settings.planetWispBoss) _timer.CurrentState.Run.AddSegment("Planet Wisp Boss");
            if (settings.aquariumParkAct1) _timer.CurrentState.Run.AddSegment("Aquarium Park 1");
            if (settings.aquariumParkAct2) _timer.CurrentState.Run.AddSegment("Aquarium Park 2");
            if (settings.aquariumParkAct3) _timer.CurrentState.Run.AddSegment("Aquarium Park 3");
            if (settings.aquariumParkAct4) _timer.CurrentState.Run.AddSegment("Aquarium Park 4");
            if (settings.aquariumParkAct5) _timer.CurrentState.Run.AddSegment("Aquarium Park 5");
            if (settings.aquariumParkAct6) _timer.CurrentState.Run.AddSegment("Aquarium Park 6");
            if (settings.aquariumParkBoss) _timer.CurrentState.Run.AddSegment("Aquarium Park Boss");
            if (settings.asteroidCoasterAct1) _timer.CurrentState.Run.AddSegment("Asteroid Coaster 1");
            if (settings.asteroidCoasterAct2) _timer.CurrentState.Run.AddSegment("Asteroid Coaster 2");
            if (settings.asteroidCoasterAct3) _timer.CurrentState.Run.AddSegment("Asteroid Coaster 3");
            if (settings.asteroidCoasterAct4) _timer.CurrentState.Run.AddSegment("Asteroid Coaster 4");
            if (settings.asteroidCoasterAct5) _timer.CurrentState.Run.AddSegment("Asteroid Coaster 5");
            if (settings.asteroidCoasterAct6) _timer.CurrentState.Run.AddSegment("Asteroid Coaster 6");
            if (settings.asteroidCoasterBoss) _timer.CurrentState.Run.AddSegment("Asteroid Coaster Boss");
            if (settings.terminalVelocityAct1) _timer.CurrentState.Run.AddSegment("Terminal Velocity 1");
            if (settings.terminalVelocityBoss) _timer.CurrentState.Run.AddSegment("Terminal Velocity Boss");
            if (settings.terminalVelocityAct2) _timer.CurrentState.Run.AddSegment("Terminal Velocity 2");
        }
    }
    class Game
    {
        public readonly string GameName = "Sonic Colors Ultimate";
        public readonly string ExeName = "Sonic Colors - Ultimate";
        public Dictionary<string, bool> oldBools = new Dictionary<string, bool>();
        public Dictionary<string, bool> currentBools = new Dictionary<string, bool>();
        public double totalIGT = 0;
        public double gameIGT = 0;
        public double old_gameIGT = 0;
        public bool isEggShuttle = true;

        // Define an array with the internal codename for easy reference/access
        // The order is the same in which the stages are run in Egg Shuttle
        public readonly string[] orderedLevels = new string[]
        {
        "tropicalResortAct1",    "tropicalResortAct2",    "tropicalResortAct3",    "tropicalResortAct4",    "tropicalResortAct5",    "tropicalResortAct6",    "tropicalResortBoss",
        "sweetMountainAct1",     "sweetMountainAct2",     "sweetMountainAct3",     "sweetMountainAct4",     "sweetMountainAct5",     "sweetMountainAct6",     "sweetMountainBoss",
        "starlightCarnivalAct1", "starlightCarnivalAct2", "starlightCarnivalAct3", "starlightCarnivalAct4", "starlightCarnivalAct5", "starlightCarnivalAct6", "starlightCarnivalBoss",
        "planetWispAct1",        "planetWispAct2",        "planetWispAct3",        "planetWispAct4",        "planetWispAct5",        "planetWispAct6",        "planetWispBoss",
        "aquariumParkAct1",      "aquariumParkAct2",      "aquariumParkAct3",      "aquariumParkAct4",      "aquariumParkAct5",      "aquariumParkAct6",      "aquariumParkBoss",
        "asteroidCoasterAct1",   "asteroidCoasterAct2",   "asteroidCoasterAct3",   "asteroidCoasterAct4",   "asteroidCoasterAct5",   "asteroidCoasterAct6",   "asteroidCoasterBoss",
        "terminalVelocityAct1",  "terminalVelocityBoss",  "terminalVelocityAct2",
        "sonicSim1-1",           "sonicSim1-2",           "sonicSim1-3",
        "sonicSim2-1",           "sonicSim2-2",           "sonicSim2-3",
        "sonicSim3-1",           "sonicSim3-2",           "sonicSim3-3",
        "sonicSim4-1",           "sonicSim4-2",           "sonicSim4-3",
        "sonicSim5-1",           "sonicSim5-2",           "sonicSim5-3",
        "sonicSim6-1",           "sonicSim6-2",           "sonicSim6-3",
        "sonicSim7-1",           "sonicSim7-2",           "sonicSim7-3"
        };

        // Define another array with the internal IDs used by the game to define stage you're currently in
        // The order has to match the same order used for vars.orderedLevels
        public readonly string[] orderedLevelIDs = new string[]
        {
        "stg110", "stg130", "stg120", "stg140", "stg150", "stg160", "stg190", // Tropical Resort
		"stg210", "stg230", "stg220", "stg260", "stg240", "stg250", "stg290", // Sweet Mountain
		"stg310", "stg330", "stg340", "stg350", "stg320", "stg360", "stg390", // Starlight Carnival
		"stg410", "stg440", "stg450", "stg430", "stg460", "stg420", "stg490", // Planet Wisp
		"stg510", "stg540", "stg550", "stg530", "stg560", "stg520", "stg590", // Aquarium Park
		"stg610", "stg630", "stg640", "stg650", "stg660", "stg620", "stg690", // Asteroid Coaster
		"stg710", "stg790", "stg720",                                         // Terminal Velocity
		"stgD10", "stgB20", "stgE50",                                         // Sonic simulator 1
		"stgD20", "stgB30", "stgF30",                                         // Sonic simulator 2
		"stgG10", "stgG30", "stgA10",                                         // Sonic simulator 3
		"stgD30", "stgG20", "stgC50",                                         // Sonic simulator 4
		"stgE30", "stgB10", "stgE40",                                         // Sonic simulator 5
		"stgG40", "stgC40", "stgF40",                                         // Sonic simulator 6
		"stgA30", "stgE20", "stgC10"                                          // Sonic simulator 7
	    };
    }
}
