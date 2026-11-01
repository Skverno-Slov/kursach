using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Signal.Dtos;
using Signal.Services;
using Signal.Views;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;

namespace Signal.ViewModels
{
    public partial class LoginWindowViewModel(LoginWindow window) : ViewModelBase
    {
        [ObservableProperty]
        private string login = string.Empty;

        [ObservableProperty]
        private string password = string.Empty;

        [ObservableProperty]
        private string errorMessage = string.Empty;

        [RelayCommand]
        private void OpenSettings()
        {
            var settingsWindow = new SettingsWindow();
            settingsWindow.ShowDialog(window);
        }

        [RelayCommand]
        private async Task LoginAsync()
        {
            if (string.IsNullOrWhiteSpace(Login) || string.IsNullOrWhiteSpace(Password))
            {
                ErrorMessage = "Заполните все поля";
                return;
            }

            ErrorMessage = string.Empty;

            try
            {
                if (await ApiService.Instance.LoginAsync(Login, Password))
                {
                    var mainWindow = new MainWindow();
                    mainWindow.Show();
                    window.Close();
                    return;
                }
                ErrorMessage = "Неверный логин или пароль";
            }
            catch (Exception ex)
            {
                ErrorMessage = $"Ошибка подключения \n{ex.Message}";
            }
        }

    }
}
