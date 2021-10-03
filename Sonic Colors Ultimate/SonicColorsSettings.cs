using LiveSplit.Model;
using System;
using System.Windows.Forms;
using System.Xml;

namespace LiveSplit.SonicColors
{
    public partial class Settings : UserControl
    {
        public bool runStart { get; set; }
        public bool runReset { get; set; }
        public bool useIGT { get; set; }
        public bool tropicalResortAct1 { get; set; }
        public bool tropicalResortAct2 { get; set; }
        public bool tropicalResortAct3 { get; set; }
        public bool tropicalResortAct4 { get; set; }
        public bool tropicalResortAct5 { get; set; }
        public bool tropicalResortAct6 { get; set; }
        public bool tropicalResortBoss { get; set; }
        public bool sweetMountainAct1 { get; set; }
        public bool sweetMountainAct2 { get; set; }
        public bool sweetMountainAct3 { get; set; }
        public bool sweetMountainAct4 { get; set; }
        public bool sweetMountainAct5 { get; set; }
        public bool sweetMountainAct6 { get; set; }
        public bool sweetMountainBoss { get; set; }
        public bool starlightCarnivalAct1 { get; set; }
        public bool starlightCarnivalAct2 { get; set; }
        public bool starlightCarnivalAct3 { get; set; }
        public bool starlightCarnivalAct4 { get; set; }
        public bool starlightCarnivalAct5 { get; set; }
        public bool starlightCarnivalAct6 { get; set; }
        public bool starlightCarnivalBoss { get; set; }
        public bool planetWispAct1 { get; set; }
        public bool planetWispAct2 { get; set; }
        public bool planetWispAct3 { get; set; }
        public bool planetWispAct4 { get; set; }
        public bool planetWispAct5 { get; set; }
        public bool planetWispAct6 { get; set; }
        public bool planetWispBoss { get; set; }
        public bool aquariumParkAct1 { get; set; }
        public bool aquariumParkAct2 { get; set; }
        public bool aquariumParkAct3 { get; set; }
        public bool aquariumParkAct4 { get; set; }
        public bool aquariumParkAct5 { get; set; }
        public bool aquariumParkAct6 { get; set; }
        public bool aquariumParkBoss { get; set; }
        public bool asteroidCoasterAct1 { get; set; }
        public bool asteroidCoasterAct2 { get; set; }
        public bool asteroidCoasterAct3 { get; set; }
        public bool asteroidCoasterAct4 { get; set; }
        public bool asteroidCoasterAct5 { get; set; }
        public bool asteroidCoasterAct6 { get; set; }
        public bool asteroidCoasterBoss { get; set; }
        public bool terminalVelocityAct1 { get; set; }
        public bool terminalVelocityBoss { get; set; }
        public bool terminalVelocityAct2 { get; set; }
        public bool sonicSim1_1 { get; set; }
        public bool sonicSim1_2 { get; set; }
        public bool sonicSim1_3 { get; set; }
        public bool sonicSim2_1 { get; set; }
        public bool sonicSim2_2 { get; set; }
        public bool sonicSim2_3 { get; set; }
        public bool sonicSim3_1 { get; set; }
        public bool sonicSim3_2 { get; set; }
        public bool sonicSim3_3 { get; set; }
        public bool sonicSim4_1 { get; set; }
        public bool sonicSim4_2 { get; set; }
        public bool sonicSim4_3 { get; set; }
        public bool sonicSim5_1 { get; set; }
        public bool sonicSim5_2 { get; set; }
        public bool sonicSim5_3 { get; set; }
        public bool sonicSim6_1 { get; set; }
        public bool sonicSim6_2 { get; set; }
        public bool sonicSim6_3 { get; set; }
        public bool sonicSim7_1 { get; set; }
        public bool sonicSim7_2 { get; set; }
        public bool sonicSim7_3 { get; set; }

        public bool setSplits = false;
        private LiveSplitState _state;

        public Settings(LiveSplitState state)
        {
            InitializeComponent();
            _state = state;

            // General settings
            this.chkrunStart.DataBindings.Add("Checked", this, "runStart", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkrunReset.DataBindings.Add("Checked", this, "runReset", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkIGT.DataBindings.Add("Checked", this, "useIGT", false, DataSourceUpdateMode.OnPropertyChanged);

            // Tropical Resort
            this.chkTR1.DataBindings.Add("Checked", this, "tropicalResortAct1", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkTR2.DataBindings.Add("Checked", this, "tropicalResortAct2", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkTR3.DataBindings.Add("Checked", this, "tropicalResortAct3", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkTR4.DataBindings.Add("Checked", this, "tropicalResortAct4", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkTR5.DataBindings.Add("Checked", this, "tropicalResortAct5", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkTR6.DataBindings.Add("Checked", this, "tropicalResortAct6", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkTRB.DataBindings.Add("Checked", this, "tropicalResortBoss", false, DataSourceUpdateMode.OnPropertyChanged);

            // Sweet Mountain
            this.chkSM1.DataBindings.Add("Checked", this, "sweetMountainAct1", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkSM2.DataBindings.Add("Checked", this, "sweetMountainAct2", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkSM3.DataBindings.Add("Checked", this, "sweetMountainAct3", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkSM4.DataBindings.Add("Checked", this, "sweetMountainAct4", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkSM5.DataBindings.Add("Checked", this, "sweetMountainAct5", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkSM6.DataBindings.Add("Checked", this, "sweetMountainAct6", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkSMB.DataBindings.Add("Checked", this, "sweetMountainBoss", false, DataSourceUpdateMode.OnPropertyChanged);

            // Starlight Carnival
            this.chkSC1.DataBindings.Add("Checked", this, "starlightCarnivalAct1", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkSC2.DataBindings.Add("Checked", this, "starlightCarnivalAct2", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkSC3.DataBindings.Add("Checked", this, "starlightCarnivalAct3", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkSC4.DataBindings.Add("Checked", this, "starlightCarnivalAct4", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkSC5.DataBindings.Add("Checked", this, "starlightCarnivalAct5", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkSC6.DataBindings.Add("Checked", this, "starlightCarnivalAct6", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkSCB.DataBindings.Add("Checked", this, "starlightCarnivalBoss", false, DataSourceUpdateMode.OnPropertyChanged);

            // Planet Wisp
            this.chkPW1.DataBindings.Add("Checked", this, "planetWispAct1", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkPW2.DataBindings.Add("Checked", this, "planetWispAct2", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkPW3.DataBindings.Add("Checked", this, "planetWispAct3", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkPW4.DataBindings.Add("Checked", this, "planetWispAct4", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkPW5.DataBindings.Add("Checked", this, "planetWispAct5", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkPW6.DataBindings.Add("Checked", this, "planetWispAct6", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkPWB.DataBindings.Add("Checked", this, "planetWispBoss", false, DataSourceUpdateMode.OnPropertyChanged);

            // Aquarium Park
            this.chkAP1.DataBindings.Add("Checked", this, "aquariumParkAct1", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkAP2.DataBindings.Add("Checked", this, "aquariumParkAct2", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkAP3.DataBindings.Add("Checked", this, "aquariumParkAct3", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkAP4.DataBindings.Add("Checked", this, "aquariumParkAct4", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkAP5.DataBindings.Add("Checked", this, "aquariumParkAct5", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkAP6.DataBindings.Add("Checked", this, "aquariumParkAct6", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkAPB.DataBindings.Add("Checked", this, "aquariumParkBoss", false, DataSourceUpdateMode.OnPropertyChanged);

            // Asteroid Coaster
            this.chkAC1.DataBindings.Add("Checked", this, "asteroidCoasterAct1", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkAC2.DataBindings.Add("Checked", this, "asteroidCoasterAct2", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkAC3.DataBindings.Add("Checked", this, "asteroidCoasterAct3", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkAC4.DataBindings.Add("Checked", this, "asteroidCoasterAct4", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkAC5.DataBindings.Add("Checked", this, "asteroidCoasterAct5", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkAC6.DataBindings.Add("Checked", this, "asteroidCoasterAct6", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkACB.DataBindings.Add("Checked", this, "asteroidCoasterBoss", false, DataSourceUpdateMode.OnPropertyChanged);

            // Terminal Velocity
            this.chkTV1.DataBindings.Add("Checked", this, "terminalVelocityAct1", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkTVB.DataBindings.Add("Checked", this, "terminalVelocityBoss", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chkTV2.DataBindings.Add("Checked", this, "terminalVelocityAct2", false, DataSourceUpdateMode.OnPropertyChanged);

            // Sonic Simulator
            this.chk1_1.DataBindings.Add("Checked", this, "sonicSim1_1", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk1_2.DataBindings.Add("Checked", this, "sonicSim1_2", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk1_3.DataBindings.Add("Checked", this, "sonicSim1_3", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk2_1.DataBindings.Add("Checked", this, "sonicSim2_1", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk2_2.DataBindings.Add("Checked", this, "sonicSim2_2", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk2_3.DataBindings.Add("Checked", this, "sonicSim2_3", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk3_1.DataBindings.Add("Checked", this, "sonicSim3_1", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk3_2.DataBindings.Add("Checked", this, "sonicSim3_2", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk3_3.DataBindings.Add("Checked", this, "sonicSim3_3", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk4_1.DataBindings.Add("Checked", this, "sonicSim4_1", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk4_2.DataBindings.Add("Checked", this, "sonicSim4_2", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk4_3.DataBindings.Add("Checked", this, "sonicSim4_3", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk5_1.DataBindings.Add("Checked", this, "sonicSim5_1", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk5_2.DataBindings.Add("Checked", this, "sonicSim5_2", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk5_3.DataBindings.Add("Checked", this, "sonicSim5_3", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk6_1.DataBindings.Add("Checked", this, "sonicSim6_1", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk6_2.DataBindings.Add("Checked", this, "sonicSim6_2", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk6_3.DataBindings.Add("Checked", this, "sonicSim6_3", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk7_1.DataBindings.Add("Checked", this, "sonicSim7_1", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk7_2.DataBindings.Add("Checked", this, "sonicSim7_2", false, DataSourceUpdateMode.OnPropertyChanged);
            this.chk7_3.DataBindings.Add("Checked", this, "sonicSim7_3", false, DataSourceUpdateMode.OnPropertyChanged);

            //
            // Default Values
            //
            this.runStart = true;
            this.runReset = true;
            this.useIGT = true;
            this.tropicalResortAct1 = true;
            this.tropicalResortAct2 = true;
            this.tropicalResortAct3 = true;
            this.tropicalResortAct4 = true;
            this.tropicalResortAct5 = true;
            this.tropicalResortAct6 = true;
            this.tropicalResortBoss = true;
            this.sweetMountainAct1 = true;
            this.sweetMountainAct2 = true;
            this.sweetMountainAct3 = true;
            this.sweetMountainAct4 = true;
            this.sweetMountainAct5 = true;
            this.sweetMountainAct6 = true;
            this.sweetMountainBoss = true;
            this.starlightCarnivalAct1 = true;
            this.starlightCarnivalAct2 = true;
            this.starlightCarnivalAct3 = true;
            this.starlightCarnivalAct4 = true;
            this.starlightCarnivalAct5 = true;
            this.starlightCarnivalAct6 = true;
            this.starlightCarnivalBoss = true;
            this.planetWispAct1 = true;
            this.planetWispAct2 = true;
            this.planetWispAct3 = true;
            this.planetWispAct4 = true;
            this.planetWispAct5 = true;
            this.planetWispAct6 = true;
            this.planetWispBoss = true;
            this.aquariumParkAct1 = true;
            this.aquariumParkAct2 = true;
            this.aquariumParkAct3 = true;
            this.aquariumParkAct4 = true;
            this.aquariumParkAct5 = true;
            this.aquariumParkAct6 = true;
            this.aquariumParkBoss = true;
            this.asteroidCoasterAct1 = true;
            this.asteroidCoasterAct2 = true;
            this.asteroidCoasterAct3 = true;
            this.asteroidCoasterAct4 = true;
            this.asteroidCoasterAct5 = true;
            this.asteroidCoasterAct6 = true;
            this.asteroidCoasterBoss = true;
            this.terminalVelocityAct1 = true;
            this.terminalVelocityBoss = true;
            this.terminalVelocityAct2 = true;
            this.sonicSim1_1 = true;
            this.sonicSim1_2 = true;
            this.sonicSim1_3 = true;
            this.sonicSim2_1 = true;
            this.sonicSim2_2 = true;
            this.sonicSim2_3 = true;
            this.sonicSim3_1 = true;
            this.sonicSim3_2 = true;
            this.sonicSim3_3 = true;
            this.sonicSim4_1 = true;
            this.sonicSim4_2 = true;
            this.sonicSim4_3 = true;
            this.sonicSim5_1 = true;
            this.sonicSim5_2 = true;
            this.sonicSim5_3 = true;
            this.sonicSim6_1 = true;
            this.sonicSim6_2 = true;
            this.sonicSim6_3 = true;
            this.sonicSim7_1 = true;
            this.sonicSim7_2 = true;
            this.sonicSim7_3 = true;
        }

        public XmlNode GetSettings(XmlDocument doc)
        {
            XmlElement settingsNode = doc.CreateElement("settings");
            settingsNode.AppendChild(ToElement(doc, "runStart", this.runStart));
            settingsNode.AppendChild(ToElement(doc, "runReset", this.runReset));
            settingsNode.AppendChild(ToElement(doc, "useIGT", this.useIGT));
            settingsNode.AppendChild(ToElement(doc, "tropicalResortAct1", this.tropicalResortAct1));
            settingsNode.AppendChild(ToElement(doc, "tropicalResortAct2", this.tropicalResortAct2));
            settingsNode.AppendChild(ToElement(doc, "tropicalResortAct3", this.tropicalResortAct3));
            settingsNode.AppendChild(ToElement(doc, "tropicalResortAct4", this.tropicalResortAct4));
            settingsNode.AppendChild(ToElement(doc, "tropicalResortAct5", this.tropicalResortAct5));
            settingsNode.AppendChild(ToElement(doc, "tropicalResortAct6", this.tropicalResortAct6));
            settingsNode.AppendChild(ToElement(doc, "tropicalResortBoss", this.tropicalResortBoss));
            settingsNode.AppendChild(ToElement(doc, "sweetMountainAct1", this.sweetMountainAct1));
            settingsNode.AppendChild(ToElement(doc, "sweetMountainAct2", this.sweetMountainAct2));
            settingsNode.AppendChild(ToElement(doc, "sweetMountainAct3", this.sweetMountainAct3));
            settingsNode.AppendChild(ToElement(doc, "sweetMountainAct4", this.sweetMountainAct4));
            settingsNode.AppendChild(ToElement(doc, "sweetMountainAct5", this.sweetMountainAct5));
            settingsNode.AppendChild(ToElement(doc, "sweetMountainAct6", this.sweetMountainAct6));
            settingsNode.AppendChild(ToElement(doc, "sweetMountainBoss", this.sweetMountainBoss));
            settingsNode.AppendChild(ToElement(doc, "starlightCarnivalAct1", this.starlightCarnivalAct1));
            settingsNode.AppendChild(ToElement(doc, "starlightCarnivalAct2", this.starlightCarnivalAct2));
            settingsNode.AppendChild(ToElement(doc, "starlightCarnivalAct3", this.starlightCarnivalAct3));
            settingsNode.AppendChild(ToElement(doc, "starlightCarnivalAct4", this.starlightCarnivalAct4));
            settingsNode.AppendChild(ToElement(doc, "starlightCarnivalAct5", this.starlightCarnivalAct5));
            settingsNode.AppendChild(ToElement(doc, "starlightCarnivalAct6", this.starlightCarnivalAct6));
            settingsNode.AppendChild(ToElement(doc, "starlightCarnivalBoss", this.starlightCarnivalBoss));
            settingsNode.AppendChild(ToElement(doc, "planetWispAct1", this.planetWispAct1));
            settingsNode.AppendChild(ToElement(doc, "planetWispAct2", this.planetWispAct2));
            settingsNode.AppendChild(ToElement(doc, "planetWispAct3", this.planetWispAct3));
            settingsNode.AppendChild(ToElement(doc, "planetWispAct4", this.planetWispAct4));
            settingsNode.AppendChild(ToElement(doc, "planetWispAct5", this.planetWispAct5));
            settingsNode.AppendChild(ToElement(doc, "planetWispAct6", this.planetWispAct6));
            settingsNode.AppendChild(ToElement(doc, "planetWispBoss", this.planetWispBoss));
            settingsNode.AppendChild(ToElement(doc, "aquariumParkAct1", this.aquariumParkAct1));
            settingsNode.AppendChild(ToElement(doc, "aquariumParkAct2", this.aquariumParkAct2));
            settingsNode.AppendChild(ToElement(doc, "aquariumParkAct3", this.aquariumParkAct3));
            settingsNode.AppendChild(ToElement(doc, "aquariumParkAct4", this.aquariumParkAct4));
            settingsNode.AppendChild(ToElement(doc, "aquariumParkAct5", this.aquariumParkAct5));
            settingsNode.AppendChild(ToElement(doc, "aquariumParkAct6", this.aquariumParkAct6));
            settingsNode.AppendChild(ToElement(doc, "aquariumParkBoss", this.aquariumParkBoss));
            settingsNode.AppendChild(ToElement(doc, "asteroidCoasterAct1", this.asteroidCoasterAct1));
            settingsNode.AppendChild(ToElement(doc, "asteroidCoasterAct2", this.asteroidCoasterAct2));
            settingsNode.AppendChild(ToElement(doc, "asteroidCoasterAct3", this.asteroidCoasterAct3));
            settingsNode.AppendChild(ToElement(doc, "asteroidCoasterAct4", this.asteroidCoasterAct4));
            settingsNode.AppendChild(ToElement(doc, "asteroidCoasterAct5", this.asteroidCoasterAct5));
            settingsNode.AppendChild(ToElement(doc, "asteroidCoasterAct6", this.asteroidCoasterAct6));
            settingsNode.AppendChild(ToElement(doc, "asteroidCoasterBoss", this.asteroidCoasterBoss));
            settingsNode.AppendChild(ToElement(doc, "terminalVelocityAct1", this.terminalVelocityAct1));
            settingsNode.AppendChild(ToElement(doc, "terminalVelocityBoss", this.terminalVelocityBoss));
            settingsNode.AppendChild(ToElement(doc, "terminalVelocityAct2", this.terminalVelocityAct2));
            settingsNode.AppendChild(ToElement(doc, "sonicSim1_1", this.sonicSim1_1));
            settingsNode.AppendChild(ToElement(doc, "sonicSim1_2", this.sonicSim1_2));
            settingsNode.AppendChild(ToElement(doc, "sonicSim1_3", this.sonicSim1_3));
            settingsNode.AppendChild(ToElement(doc, "sonicSim2_1", this.sonicSim2_1));
            settingsNode.AppendChild(ToElement(doc, "sonicSim2_2", this.sonicSim2_2));
            settingsNode.AppendChild(ToElement(doc, "sonicSim2_3", this.sonicSim2_3));
            settingsNode.AppendChild(ToElement(doc, "sonicSim3_1", this.sonicSim3_1));
            settingsNode.AppendChild(ToElement(doc, "sonicSim3_2", this.sonicSim3_2));
            settingsNode.AppendChild(ToElement(doc, "sonicSim3_3", this.sonicSim3_3));
            settingsNode.AppendChild(ToElement(doc, "sonicSim4_1", this.sonicSim4_1));
            settingsNode.AppendChild(ToElement(doc, "sonicSim4_2", this.sonicSim4_2));
            settingsNode.AppendChild(ToElement(doc, "sonicSim4_3", this.sonicSim4_3));
            settingsNode.AppendChild(ToElement(doc, "sonicSim5_1", this.sonicSim5_1));
            settingsNode.AppendChild(ToElement(doc, "sonicSim5_2", this.sonicSim5_2));
            settingsNode.AppendChild(ToElement(doc, "sonicSim5_3", this.sonicSim5_3));
            settingsNode.AppendChild(ToElement(doc, "sonicSim6_1", this.sonicSim6_1));
            settingsNode.AppendChild(ToElement(doc, "sonicSim6_2", this.sonicSim6_2));
            settingsNode.AppendChild(ToElement(doc, "sonicSim6_3", this.sonicSim6_3));
            settingsNode.AppendChild(ToElement(doc, "sonicSim7_1", this.sonicSim7_1));
            settingsNode.AppendChild(ToElement(doc, "sonicSim7_2", this.sonicSim7_2));
            settingsNode.AppendChild(ToElement(doc, "sonicSim7_3", this.sonicSim7_3));

            return settingsNode;
        }

        public void SetSettings(XmlNode settings)
        {
            this.runStart = ParseBool(settings, "runStart", true);
            this.runReset = ParseBool(settings, "runReset", true);
            this.useIGT = ParseBool(settings, "useIGT", true);
            this.tropicalResortAct1 = ParseBool(settings, "tropicalResortAct1", true);
            this.tropicalResortAct2 = ParseBool(settings, "tropicalResortAct2", true);
            this.tropicalResortAct3 = ParseBool(settings, "tropicalResortAct3", true);
            this.tropicalResortAct4 = ParseBool(settings, "tropicalResortAct4", true);
            this.tropicalResortAct5 = ParseBool(settings, "tropicalResortAct5", true);
            this.tropicalResortAct6 = ParseBool(settings, "tropicalResortAct6", true);
            this.tropicalResortBoss = ParseBool(settings, "tropicalResortBoss", true);
            this.sweetMountainAct1 = ParseBool(settings, "sweetMountainAct1", true);
            this.sweetMountainAct2 = ParseBool(settings, "sweetMountainAct2", true);
            this.sweetMountainAct3 = ParseBool(settings, "sweetMountainAct3", true);
            this.sweetMountainAct4 = ParseBool(settings, "sweetMountainAct4", true);
            this.sweetMountainAct5 = ParseBool(settings, "sweetMountainAct5", true);
            this.sweetMountainAct6 = ParseBool(settings, "sweetMountainAct6", true);
            this.sweetMountainBoss = ParseBool(settings, "sweetMountainBoss", true);
            this.starlightCarnivalAct1 = ParseBool(settings, "starlightCarnivalAct1", true);
            this.starlightCarnivalAct2 = ParseBool(settings, "starlightCarnivalAct2", true);
            this.starlightCarnivalAct3 = ParseBool(settings, "starlightCarnivalAct3", true);
            this.starlightCarnivalAct4 = ParseBool(settings, "starlightCarnivalAct4", true);
            this.starlightCarnivalAct5 = ParseBool(settings, "starlightCarnivalAct5", true);
            this.starlightCarnivalAct6 = ParseBool(settings, "starlightCarnivalAct6", true);
            this.starlightCarnivalBoss = ParseBool(settings, "starlightCarnivalBoss", true);
            this.planetWispAct1 = ParseBool(settings, "planetWispAct1", true);
            this.planetWispAct2 = ParseBool(settings, "planetWispAct2", true);
            this.planetWispAct3 = ParseBool(settings, "planetWispAct3", true);
            this.planetWispAct4 = ParseBool(settings, "planetWispAct4", true);
            this.planetWispAct5 = ParseBool(settings, "planetWispAct5", true);
            this.planetWispAct6 = ParseBool(settings, "planetWispAct6", true);
            this.planetWispBoss = ParseBool(settings, "planetWispBoss", true);
            this.aquariumParkAct1 = ParseBool(settings, "aquariumParkAct1", true);
            this.aquariumParkAct2 = ParseBool(settings, "aquariumParkAct2", true);
            this.aquariumParkAct3 = ParseBool(settings, "aquariumParkAct3", true);
            this.aquariumParkAct4 = ParseBool(settings, "aquariumParkAct4", true);
            this.aquariumParkAct5 = ParseBool(settings, "aquariumParkAct5", true);
            this.aquariumParkAct6 = ParseBool(settings, "aquariumParkAct6", true);
            this.aquariumParkBoss = ParseBool(settings, "aquariumParkBoss", true);
            this.asteroidCoasterAct1 = ParseBool(settings, "asteroidCoasterAct1", true);
            this.asteroidCoasterAct2 = ParseBool(settings, "asteroidCoasterAct2", true);
            this.asteroidCoasterAct3 = ParseBool(settings, "asteroidCoasterAct3", true);
            this.asteroidCoasterAct4 = ParseBool(settings, "asteroidCoasterAct4", true);
            this.asteroidCoasterAct5 = ParseBool(settings, "asteroidCoasterAct5", true);
            this.asteroidCoasterAct6 = ParseBool(settings, "asteroidCoasterAct6", true);
            this.asteroidCoasterBoss = ParseBool(settings, "asteroidCoasterBoss", true);
            this.terminalVelocityAct1 = ParseBool(settings, "terminalVelocityAct1", true);
            this.terminalVelocityBoss = ParseBool(settings, "terminalVelocityBoss", true);
            this.terminalVelocityAct2 = ParseBool(settings, "terminalVelocityAct2", true);
            this.sonicSim1_1 = ParseBool(settings, "sonicSim1_1", true);
            this.sonicSim1_2 = ParseBool(settings, "sonicSim1_2", true);
            this.sonicSim1_3 = ParseBool(settings, "sonicSim1_3", true);
            this.sonicSim2_1 = ParseBool(settings, "sonicSim2_1", true);
            this.sonicSim2_2 = ParseBool(settings, "sonicSim2_2", true);
            this.sonicSim2_3 = ParseBool(settings, "sonicSim2_3", true);
            this.sonicSim3_1 = ParseBool(settings, "sonicSim3_1", true);
            this.sonicSim3_2 = ParseBool(settings, "sonicSim3_2", true);
            this.sonicSim3_3 = ParseBool(settings, "sonicSim3_3", true);
            this.sonicSim4_1 = ParseBool(settings, "sonicSim4_1", true);
            this.sonicSim4_2 = ParseBool(settings, "sonicSim4_2", true);
            this.sonicSim4_3 = ParseBool(settings, "sonicSim4_3", true);
            this.sonicSim5_1 = ParseBool(settings, "sonicSim5_1", true);
            this.sonicSim5_2 = ParseBool(settings, "sonicSim5_2", true);
            this.sonicSim5_3 = ParseBool(settings, "sonicSim5_3", true);
            this.sonicSim6_1 = ParseBool(settings, "sonicSim6_1", true);
            this.sonicSim6_2 = ParseBool(settings, "sonicSim6_2", true);
            this.sonicSim6_3 = ParseBool(settings, "sonicSim6_3", true);
            this.sonicSim7_1 = ParseBool(settings, "sonicSim7_1", true);
            this.sonicSim7_2 = ParseBool(settings, "sonicSim7_2", true);
            this.sonicSim7_3 = ParseBool(settings, "sonicSim7_3", true);
        }

        static bool ParseBool(XmlNode settings, string setting, bool default_ = false)
        {
            bool val;
            return settings[setting] != null ? (Boolean.TryParse(settings[setting].InnerText, out val) ? val : default_) : default_;
        }

        static XmlElement ToElement<T>(XmlDocument document, string name, T value)
        {
            XmlElement str = document.CreateElement(name);
            str.InnerText = value.ToString();
            return str;
        }

        private void button1_Click(object sender, EventArgs e)
        {
            var question = MessageBox.Show("This will set up your splits according to your selected autosplitting options.\n" +
                            "WARNING: Any existing PB recorded for the current layout will be deleted.\n\n" +
                            "Do you want to continue?", "Livesplit - Sonic Colors: Ultimate", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
            if (question == DialogResult.No) return;
            _state.Run.Clear();
            if (tropicalResortAct1) _state.Run.AddSegment("Tropical Resort 1");
            if (tropicalResortAct2) _state.Run.AddSegment("Tropical Resort 2");
            if (tropicalResortAct3) _state.Run.AddSegment("Tropical Resort 3");
            if (tropicalResortAct4) _state.Run.AddSegment("Tropical Resort 4");
            if (tropicalResortAct5) _state.Run.AddSegment("Tropical Resort 5");
            if (tropicalResortAct6) _state.Run.AddSegment("Tropical Resort 6");
            if (tropicalResortBoss) _state.Run.AddSegment("Tropical Resort Boss");
            if (sweetMountainAct1) _state.Run.AddSegment("Sweet Mountain 1");
            if (sweetMountainAct2) _state.Run.AddSegment("Sweet Mountain 2");
            if (sweetMountainAct3) _state.Run.AddSegment("Sweet Mountain 3");
            if (sweetMountainAct4) _state.Run.AddSegment("Sweet Mountain 4");
            if (sweetMountainAct5) _state.Run.AddSegment("Sweet Mountain 5");
            if (sweetMountainAct6) _state.Run.AddSegment("Sweet Mountain 6");
            if (sweetMountainBoss) _state.Run.AddSegment("Sweet Mountain Boss");
            if (starlightCarnivalAct1) _state.Run.AddSegment("Starlight Carnival 1");
            if (starlightCarnivalAct2) _state.Run.AddSegment("Starlight Carnival 2");
            if (starlightCarnivalAct3) _state.Run.AddSegment("Starlight Carnival 3");
            if (starlightCarnivalAct4) _state.Run.AddSegment("Starlight Carnival 4");
            if (starlightCarnivalAct5) _state.Run.AddSegment("Starlight Carnival 5");
            if (starlightCarnivalAct6) _state.Run.AddSegment("Starlight Carnival 6");
            if (starlightCarnivalBoss) _state.Run.AddSegment("Starlight Carnival Boss");
            if (planetWispAct1) _state.Run.AddSegment("Planet Wisp 1");
            if (planetWispAct2) _state.Run.AddSegment("Planet Wisp 2");
            if (planetWispAct3) _state.Run.AddSegment("Planet Wisp 3");
            if (planetWispAct4) _state.Run.AddSegment("Planet Wisp 4");
            if (planetWispAct5) _state.Run.AddSegment("Planet Wisp 5");
            if (planetWispAct6) _state.Run.AddSegment("Planet Wisp 6");
            if (planetWispBoss) _state.Run.AddSegment("Planet Wisp Boss");
            if (aquariumParkAct1) _state.Run.AddSegment("Aquarium Park 1");
            if (aquariumParkAct2) _state.Run.AddSegment("Aquarium Park 2");
            if (aquariumParkAct3) _state.Run.AddSegment("Aquarium Park 3");
            if (aquariumParkAct4) _state.Run.AddSegment("Aquarium Park 4");
            if (aquariumParkAct5) _state.Run.AddSegment("Aquarium Park 5");
            if (aquariumParkAct6) _state.Run.AddSegment("Aquarium Park 6");
            if (aquariumParkBoss) _state.Run.AddSegment("Aquarium Park Boss");
            if (asteroidCoasterAct1) _state.Run.AddSegment("Asteroid Coaster 1");
            if (asteroidCoasterAct2) _state.Run.AddSegment("Asteroid Coaster 2");
            if (asteroidCoasterAct3) _state.Run.AddSegment("Asteroid Coaster 3");
            if (asteroidCoasterAct4) _state.Run.AddSegment("Asteroid Coaster 4");
            if (asteroidCoasterAct5) _state.Run.AddSegment("Asteroid Coaster 5");
            if (asteroidCoasterAct6) _state.Run.AddSegment("Asteroid Coaster 6");
            if (asteroidCoasterBoss) _state.Run.AddSegment("Asteroid Coaster Boss");
            if (terminalVelocityAct1) _state.Run.AddSegment("Terminal Velocity 1");
            if (terminalVelocityBoss) _state.Run.AddSegment("Terminal Velocity Boss");
            if (terminalVelocityAct2) _state.Run.AddSegment("Terminal Velocity 2");
            if (_state.Run.Count == 0)
            {
                _state.Run.AddSegment("");
            }
        }
    }
}
