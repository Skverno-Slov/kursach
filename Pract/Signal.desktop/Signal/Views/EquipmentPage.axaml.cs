using Avalonia;
using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Signal.Services;
using Signal.ViewModels;

namespace Signal;

public partial class EquipmentPage : UserControl
{
    public EquipmentPage()
    {
        InitializeComponent();
        DataContext = new EquipmentPageViewModel(ApiService.Instance);
    }

    private async void EquipmentPage_Loaded(object? sender, RoutedEventArgs e)
    {
        if (DataContext is EquipmentPageViewModel vm)
            await vm.LoadEquipmentCommand.ExecuteAsync(null);
    }
}