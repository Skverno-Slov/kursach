using Avalonia.Controls;
using Avalonia.Interactivity;
using Signal.Services;
using Signal.ViewModels;

namespace Signal.Views;

public partial class UsersPage : UserControl
{
    public UsersPage()
    {
        InitializeComponent();
        DataContext = new UsersPageViewModel(ApiService.Instance);
    }

    private async void UsersPage_Loaded(object? sender, RoutedEventArgs e)
    {
        if (DataContext is UsersPageViewModel vm)
            await vm.LoadUsersCommand.ExecuteAsync(null);
    }
}