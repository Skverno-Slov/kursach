using Avalonia;
using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Signal.Dtos;
using Signal.Services;
using Signal.ViewModels;

namespace Signal;

public partial class UserRedactorPage : UserControl
{
    public UserRedactorPage(UserDto? user = null)
    {
        InitializeComponent();
        DataContext = new UserRedactorPageViewModel(ApiService.Instance, user);
    }

    private async void UsersRedactorPage_Loaded(object? sender, RoutedEventArgs e)
    {
        if (DataContext is UserRedactorPageViewModel vm)
            await vm.InitializeCommand.ExecuteAsync(null);
    }
}