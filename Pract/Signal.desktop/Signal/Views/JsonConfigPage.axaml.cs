using Avalonia;
using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Signal.ViewModels;

namespace Signal;

public partial class JsonConfigPage : UserControl
{
    public JsonConfigPage()
    {
        InitializeComponent();
    }

    private void JsonConfigPage_Loaded(object? sender, RoutedEventArgs e)
    {
        var topLevel = TopLevel.GetTopLevel(this);
        DataContext = new JsonConfigPageViewModel(topLevel);
    }
}