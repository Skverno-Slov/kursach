using Avalonia;
using Avalonia.Controls;
using Avalonia.Controls.ApplicationLifetimes;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Signal.Models;
using Signal.Services;
using Signal.Views;
using System;
using System.Threading.Tasks;

namespace Signal.ViewModels
{
    public partial class MainWindowViewModel : ViewModelBase
    {
        [ObservableProperty]
        bool isMenuOpen;

        [ObservableProperty]
        object? currentPage;

        [ObservableProperty]
        string userFullName;

        MainWindow currentWindow;

        public MainWindowViewModel(MainWindow window)
        {
            NavigateToUsersPage();
            currentWindow = window;
            UserFullName = SessionContext.FullName ?? "-";
        }

        [RelayCommand]
        private void ToggleMenu() => IsMenuOpen = !IsMenuOpen;

        [RelayCommand]
        private void NavigateToUsersPage()
        {
            var pageType = new UsersPage().GetType();
            if (pageType != null)
                CurrentPage = Activator.CreateInstance(pageType);
            IsMenuOpen = false;
        }

        [RelayCommand]
        private async Task OpenSettingsAsync()
        {
            IsMenuOpen = false;

            var settingsWindow = new SettingsWindow();

            await settingsWindow.ShowDialog(currentWindow);
        }

        [RelayCommand]
        private void OpenUsersPage()
        {
            MainViewModelHandler.Instance.CurrentPage = new UsersPage();
        }

        [RelayCommand]
        private void OpenEquipmentPage()
        {
            MainViewModelHandler.Instance.CurrentPage = new EquipmentPage();
        }

        [RelayCommand]
        private void OpenReadingTypePage()
        {
            MainViewModelHandler.Instance.CurrentPage = new ReadingTypesPage();
        }

        [RelayCommand]
        private void OpenJsonConfigPage()
        {
            MainViewModelHandler.Instance.CurrentPage = new JsonConfigPage();
        }

        [RelayCommand]
        private void ExitApplication()
        {
            if (Application.Current?.ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
                desktop.Shutdown();
        }
    }
}
