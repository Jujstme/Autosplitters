using System.Reflection;
using LiveSplit.SonicColors;
using LiveSplit.UI.Components;
using System;
using LiveSplit.Model;

[assembly: ComponentFactory(typeof(SonicColorsFactory))]

namespace LiveSplit.SonicColors
{
    public class SonicColorsFactory : IComponentFactory
    {
        public string ComponentName => "Sonic Colors Ultimate";
        public string Description => "Automatic splitting and IGT calculation for Sonic Colors Ultimate";
        public ComponentCategory Category => ComponentCategory.Control;
        public string UpdateName => this.ComponentName;
        public string UpdateURL => "http://fatalis.pw/livesplit/update/";
        public Version Version => Assembly.GetExecutingAssembly().GetName().Version;
        public string XMLURL => this.UpdateURL + "Components/update.LiveSplit.Dishonored.xml";
        public IComponent Create(LiveSplitState state)
        {
            return new SonicColorsComponent(state);
        }

    }
}
