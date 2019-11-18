using System.Windows.Input;

namespace CastReporting.UI.WPF.Core.Commands
{
    public static class SettingsCommand
    {
        public static RoutedCommand SaveSettings { get; set; }

        static SettingsCommand()
        {
            SaveSettings = new RoutedCommand();
        }
    }
}
