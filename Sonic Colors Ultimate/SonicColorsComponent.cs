using LiveSplit.Model;
using LiveSplit.UI.Components;
using LiveSplit.UI;
using System;
using System.Diagnostics;
using System.Linq;
using System.Xml;
using System.Windows.Forms;

namespace LiveSplit.SonicColors
{
    partial class Component : LogicComponent
    {
        public override string ComponentName => GameVariables.GameName;
        private GameVariables vars = new GameVariables();
        private Settings settings { get; set; }
        private Process game;
        private TimerModel timer;
        private Timer update_timer;

        public Component(LiveSplitState state)
        {
            timer = new TimerModel { CurrentState = state };
            update_timer = new Timer() { Interval = 1000 / GameVariables.RefreshRate, Enabled = true };
            settings = new Settings(state);
            update_timer.Tick += UpdateLogic;
        }

        public override void Dispose()
        {
            settings.Dispose();
            update_timer?.Dispose();
        }

        private void UpdateLogic(object sender, EventArgs eventArgs)
        {
            if (game == null || game.HasExited)
            {
                try
                {
                    if (!HookGameProcess()) return;
                }
                catch
                {
                    game = null;
                    return;
                }
            }
            UpdateGameMemory();
            UpdateScript();
            if (timer.CurrentState.CurrentPhase == TimerPhase.NotRunning) StartTimer();
            if (timer.CurrentState.CurrentPhase == TimerPhase.Running)
            {
                IsLoading();
                GameTime();
                ResetLogic();
                SplitLogic();
            }
        }

        private bool HookGameProcess()
        {
            foreach (var process in GameVariables.ExeName)
            {
                game = Process.GetProcessesByName(process).OrderByDescending(x => x.StartTime).FirstOrDefault(x => !x.HasExited);
                if (game == null) continue;
                if (Init())
                {
                    return true;
                }
                else
                {
                    game = null;
                    return false;
                }
            }
            return false;
        }

        public override XmlNode GetSettings(XmlDocument document) { return this.settings.GetSettings(document); }

        public override Control GetSettingsControl(LayoutMode mode) { return this.settings; }

        public override void SetSettings(XmlNode settings) { this.settings.SetSettings(settings); }

        public override void Update(IInvalidator invalidator, LiveSplitState state, float width, float height, LayoutMode mode) { }
    }
}
