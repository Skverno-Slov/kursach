using Avalonia;
using Avalonia.Controls;
using Avalonia.Markup.Xaml;
using Signal.ViewModels;

namespace Signal.Views;

public partial class SettingsWindow : Window
{
    public SettingsWindow()
    {
        InitializeComponent();
        DataContext = new SettingsWindowViewModel();
    }
}