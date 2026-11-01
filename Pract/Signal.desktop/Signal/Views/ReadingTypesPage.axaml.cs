using Avalonia;
using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Signal.Services;
using Signal.ViewModels;

namespace Signal;

public partial class ReadingTypesPage : UserControl
{
    public ReadingTypesPage()
    {
        InitializeComponent();
        DataContext = new ReadingTypesPageViewModel(ApiService.Instance);
    }

    private async void ReadingTypesPage_Loaded(object? sender, RoutedEventArgs e)
    {
        if (DataContext is ReadingTypesPageViewModel vm)
            await vm.LoadReadingTypesCommand.ExecuteAsync(null);
    }
}