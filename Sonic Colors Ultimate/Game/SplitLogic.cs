using System;
using LiveSplit.ComponentUtil;
using LiveSplit.Model;

namespace LiveSplit.SonicColors
{
    internal class GameVariables
    {
        internal const string GameName = "Sonic Colors: Ultimate";
        internal static readonly string[] ExeName = { "Sonic Colors - Ultimate" };
        internal const byte RefreshRate = 60;
        internal MemoryWatcherList watchers;

        // Internal variables
        internal double AccumulatedIGT = 0;
        internal double OldIGT, CurrentIGT = 0;
        internal bool OldGoalRingReached, GoalRingReached = false;
        internal bool IsEggShuttle = false;
    }

    partial class Component
    {
        private bool Init()
        {
            var scanner = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);
            IntPtr ptr;
            vars.watchers = new MemoryWatcherList();

            // Basic checks
            if (!game.Is64Bit()) return false;
            ptr = scanner.Scan(new SigScanTarget("53 6F 6E 69 63 20 43 6F 6C 6F 72 73 3A 20 55 6C 74 69 6D 61 74 65"));   // Check if the exe is internally named "Sonic Colors: Ultimate"
            if (ptr == IntPtr.Zero) return false;

            // Run start (Any% and All Chaos Emeralds)
            // Corresponds to the "name" assigned to the internal savefile
            // New game = "########"
            // Otherwise = "no-name"
            // Can be used for signalling a reset
            ptr = scanner.Scan(new SigScanTarget(5,
                "74 2B",                 // je "Sonic Colors - Ultimate.exe"+16F3948
                "48 8B 0D ????????"));   // mov rcx,["Sonic Colors - Ultimate.exe"+52462A8]
            if (ptr == IntPtr.Zero) return false;
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x60, 0x120)) { Name = "runStart", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });
            vars.watchers.Add(new MemoryWatcher<sbyte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x60, 0x1CC)) { Name = "TR1rank", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });  // Must be FF in a new game

            // Current level data pointer
            // This region of memory contains basic data about the current level you're in, such as IGT, rings, score, etc. 
            // Also has a lot of flags (inside bitmasks) I didn't bother to investigate
            ptr = scanner.Scan(new SigScanTarget(5,
               "31 C0",                 // xor eax,eax
               "48 89 05 ????????"));   // mov ["Sonic Colors - Ultimate.exe"+52465C0],rax
            if (ptr == IntPtr.Zero) return false;
            vars.watchers.Add(new MemoryWatcher<float>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x0, 0x270)) { Name = "IGT", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x0, 0x110)) { Name = "goalRingReached", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull }); // Bit 5 gets flipped th emoment the stage is reported by the game as complete and all in-level events stop (eg. IGT stops)                                                                                                                                                                  // Level ID
            vars.watchers.Add(new StringWatcher(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x0, 0xE0), 6) { Name = "levelID" }); // It's a 6-character ID that uniquely reports the level you're in. The IDs are the same as in the Wii version of the game. Check Wii's actstgmission.lua for details
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x0, 0xE0)) { Name = "levelID_numeric", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull });

            // Egg Shuttle data pointer
            // This memory region becomes accessible only when you're inside Egg Shuttle
            ptr = scanner.Scan(new SigScanTarget(5,
            "76 0C",                 // jna "Sonic Colors - Ultimate.exe"+16DF25C
            "48 8B 0D ????????"));   // mov rcx,["Sonic colors - Ultimate.exe"+5245658]
            if (ptr == IntPtr.Zero) return false;
            // Egg Shuttle total levels (indicates the total number of stages included in Egg Shuttle mode)
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x8, 0x38, 0x68, 0x110, 0x0)) { Name = "eggShuttle_totalStages", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull }); // This value is always above 0 so it can be used to report whether you're in egg shuttle or not
            vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(ptr + 4 + game.ReadValue<int>(ptr), 0x8, 0x38, 0x68, 0x110, 0xB8)) { Name = "eggShuttle_progressiveID", FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull }); // Indicates level progression inside Egg Shuttle. Goes from 0 to 44 (44 = Terminal Velocity Act 2). It techically also goes to 45 at the final results screen after Terminal Velocity Act 

            vars.watchers.UpdateAll(game);
            return true;
        }

        private void UpdateGameMemory()
        {
            vars.watchers.UpdateAll(game);
            vars.OldIGT = vars.CurrentIGT;
            vars.OldGoalRingReached = vars.GoalRingReached;
            vars.GoalRingReached = ((byte)vars.watchers["goalRingReached"].Current & (1 << 5)) != 0;
        }

        private void UpdateScript()
        {
            // Assume the IGT is always zero if you are in the credits stage or outside a stage
            // This prevents a possible overflowException that sometimes occurs if you load the credits while the timer is running
            // This behaviour is caused by the IGT often reporting insanely huge IGT values inside the credits
            if ((byte)vars.watchers["levelID_numeric"].Current == 8 || (byte)vars.watchers["levelID_numeric"].Current == 0) vars.watchers["IGT"].Current = 0f;

            // The game calculates the IGT for each stage by simply truncating the float value to the second decimal.
            // In order to make the timer match the displayed IGT inside the game, we need to do the same.
            // This also implicitly converts the IGT from float to double (C# really doesn't like to work with floats).
            vars.CurrentIGT = Math.Truncate((float)vars.watchers["IGT"].Current * 100) / 100;

            // Another IGT logic: Use an internal totalIGT variable in which we will store the accumulated IGT every time the game IGT resets (eg. when exiting a level)
            if ((float)vars.watchers["IGT"].Old != 0 && (float)vars.watchers["IGT"].Current == 0) vars.AccumulatedIGT += vars.OldIGT;

            // These variables need to be managed when the run hasn't started yet
            // You can put these inside the start section of the autosplitter but you risk the code not being run if the user disables automatic start
            if (timer.CurrentState.CurrentPhase == TimerPhase.NotRunning) vars.IsEggShuttle = (byte)vars.watchers["eggShuttle_totalStages"].Current > 0; // Check whether you're in Egg Shuttle or not. This value must not change once the timer started to run.
        }

        private void StartTimer()
        {
            vars.AccumulatedIGT = 0;
            if (!settings.runStart) return;
            bool startTrigger = false;

            switch (vars.IsEggShuttle)
            {
                case true:
                    startTrigger = (string)vars.watchers["levelID"].Current == Levels.TropicalResortAct1 && (byte)vars.watchers["levelID_numeric"].Old == 0 && vars.watchers["levelID_numeric"].Changed;
                    break;
                case false:
                    startTrigger = (byte)vars.watchers["runStart"].Old == 35 && (byte)vars.watchers["runStart"].Current == 110 && (sbyte)vars.watchers["TR1rank"].Current == -1;
                    break;
            }

            if (startTrigger) timer.Start();
        }

        private void IsLoading()
        {
            if (!timer.CurrentState.IsGameTimePaused && settings.useIGT) timer.CurrentState.IsGameTimePaused = true;
        }

        private void GameTime()
        {
            if (settings.useIGT) timer.CurrentState.SetGameTime(TimeSpan.FromSeconds(vars.AccumulatedIGT + vars.CurrentIGT));
        }

        private void ResetLogic()
        {
            if (!settings.runReset) return;
            bool resetTrigger = false;

            switch (vars.IsEggShuttle)
            {
                case true:
                    resetTrigger = (float)vars.watchers["IGT"].Old != 0 && (float)vars.watchers["IGT"].Current == 0 && !vars.OldGoalRingReached;
                    break;
                case false:
                    resetTrigger = (byte)vars.watchers["runStart"].Old == 110 && (byte)vars.watchers["runStart"].Current == 35;
                    break;
            }

            if (resetTrigger) timer.Reset();
        }

        private void SplitLogic()
        {
            if (vars.watchers["levelID"].Current == null || (byte)vars.watchers["levelID_numeric"].Current == 8) return;
            bool splitTrigger = false;

            switch (vars.IsEggShuttle)
            {
                case true:
                    bool isLastLevel = (byte)vars.watchers["eggShuttle_progressiveID"].Old == (byte)vars.watchers["eggShuttle_totalStages"].Current - 1;
                    switch (isLastLevel)
                    {
                        case false:
                            splitTrigger = (byte)vars.watchers["eggShuttle_progressiveID"].Current == (byte)vars.watchers["eggShuttle_progressiveID"].Old + 1 && splitEnabled();
                            break;
                        case true:
                            splitTrigger = vars.GoalRingReached && !vars.OldGoalRingReached && splitEnabled();
                            break;
                    }
                    break;
                case false:
                    bool isTV2 = (string)vars.watchers["levelID"].Old == Levels.TerminalVelocityAct2;
                    switch (isTV2)
                    {
                        case true:
                            splitTrigger = vars.GoalRingReached && !vars.OldGoalRingReached && settings.terminalVelocityAct2;
                            break;
                        case false:
                            splitTrigger = !vars.GoalRingReached && vars.OldGoalRingReached && splitEnabled();
                            break;
                    }
                    break;
            }

            if (splitTrigger) timer.Split();
        }
    }
}



