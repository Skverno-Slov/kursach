using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Signal.Models;
using Signal.Services;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Threading.Tasks;

namespace Signal.ViewModels
{
    public partial class SettingsWindowViewModel : ViewModelBase
    {
        [ObservableProperty]
        string address = "";
        [ObservableProperty]
        string port = "";
        [ObservableProperty]
        [NotifyCanExecuteChangedFor(nameof(SaveSettingsCommand))]
        bool isConnected;
        [ObservableProperty]
        bool isSaved;
        [ObservableProperty]
        [NotifyCanExecuteChangedFor(nameof(TryConnectCommand))]
        bool isDataCorrect;
        public ObservableCollection<string> Errors { get; } = new();
        [ObservableProperty]
        string connectionState = "Проверить";

        string savedAddress;
        string savedPort;

        public SettingsWindowViewModel()
        {
            savedAddress = SettingsService.Load().Address;
            savedPort = SettingsService.Load().Port;
            Address = savedAddress;
            Port = savedPort;
            IsConnected = IsSaved = Address == savedAddress && Port == savedPort;
        }

        void ValidateInput()
        {
            Errors.Clear();
            if (string.IsNullOrWhiteSpace(Address))
            {
                Errors.Add("Адрес не может быть пустым");
                IsDataCorrect = false;
            }

            if (string.IsNullOrWhiteSpace(Port))
            {
                Errors.Add("Порт не может быть пустым");
                IsDataCorrect = false;
            }
            else if (!Int32.TryParse(Port, out int intPort) || intPort < 0 || intPort > 65535)
            {
                Errors.Add("Порт может быть только числом от 0 до 65535");
                IsDataCorrect = false;
            }

            IsSaved = IsConnected = Port == savedPort && Address == savedAddress;
        }

        [RelayCommand]
        async Task TryConnectAsync()
        {
            ConnectionState = "Подключение...";
            IsConnected = await ApiService.Instance.CheckConnectionAsync(new Uri($"https://{Address}:{Port}/api/ping"));
            ConnectionState = "Проверить";
        }

        [RelayCommand]
        void SaveSettings()
        {
            var settings = new NetworkSettings()
            {
                Address = Address,
                Port = Port
            };
            SettingsService.Save(settings);

            IsSaved = Address == SettingsService.Load().Address && Port == SettingsService.Load().Port;
        }

        partial void OnAddressChanged(string value) => ValidateInput();
        partial void OnPortChanged(string value) => ValidateInput();
    }
}
