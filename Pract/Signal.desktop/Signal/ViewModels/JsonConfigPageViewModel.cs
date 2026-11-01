using Avalonia.Controls;
using Avalonia.Platform.Storage;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Signal.Models;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Threading.Tasks;

namespace Signal.ViewModels
{
    public partial class JsonConfigPageViewModel : ViewModelBase
    {
        readonly TopLevel? topLevel;
        readonly string localConfigPath = Path.Combine("configs", "devices.json");
        readonly JsonSerializerOptions jsonOptions = new()
        {
            WriteIndented = true,
            Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
        };


        public ObservableCollection<DeviceConfig> Devices { get; set; } = new();
        public ObservableCollection<AnnotationItemViewModel> CurrentAnnotations { get; set; } = new();

        [ObservableProperty]
        DeviceConfig? selectedDevice;
        [ObservableProperty]
        ParamConfig? selectedParam;
        [ObservableProperty]
        AnnotationItemViewModel? selectedAnnotation;
        [ObservableProperty]
        string statusMessage = string.Empty;

        public JsonConfigPageViewModel(TopLevel? topLevel)
        {
            this.topLevel = topLevel;
            LoadConfig();
        }

        partial void OnSelectedDeviceChanged(DeviceConfig? value)
        {
            SelectedParam = null;
            CurrentAnnotations.Clear();
        }

        partial void OnSelectedParamChanged(ParamConfig? value)
        {
            CurrentAnnotations.Clear();
            if (value?.Annotations is null) return;

            foreach (var kvp in value.Annotations)
            {
                CurrentAnnotations.Add(new AnnotationItemViewModel(kvp.Key, kvp.Value, SyncAnnotationsToDictionary));
            }
        }

        private void SyncAnnotationsToDictionary()
        {
            if (SelectedParam is null) return;

            SelectedParam.Annotations ??= new Dictionary<string, string>();
            SelectedParam.Annotations.Clear();

            foreach (var item in CurrentAnnotations)
            {
                if (!string.IsNullOrWhiteSpace(item.Key))
                {
                    SelectedParam.Annotations[item.Key] = item.Value ?? string.Empty;
                }
            }

            if (SelectedParam.Annotations.Count == 0) SelectedParam.Annotations = null;
        }

        private void LoadConfig()
        {
            try
            {
                if (!File.Exists(localConfigPath))
                {
                    var dir = Path.GetDirectoryName(localConfigPath);
                    if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
                    File.WriteAllText(localConfigPath, "[]");
                }

                string json = File.ReadAllText(localConfigPath);
                var list = JsonSerializer.Deserialize<List<DeviceConfig>>(json, jsonOptions) ?? new List<DeviceConfig>();
                Devices = new ObservableCollection<DeviceConfig>(list);
                StatusMessage = "Конфигурация успешно загружена";
            }
            catch (Exception ex)
            {
                StatusMessage = $"Ошибка чтения файла: {ex.Message}";
            }
        }

        [RelayCommand]
        private void SaveConfig()
        {
            try
            {
                SyncAnnotationsToDictionary();

                var dir = Path.GetDirectoryName(localConfigPath);
                if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);

                string json = JsonSerializer.Serialize(Devices.ToList(), jsonOptions);
                File.WriteAllText(localConfigPath, json);
                StatusMessage = "Изменения сохранены";
            }
            catch (Exception ex)
            {
                StatusMessage = $"Ошибка сохранения: {ex.Message}";
            }
        }

        [RelayCommand]
        private async Task ExportConfigAsync()
        {
            if (topLevel is null)
                return;

            SyncAnnotationsToDictionary();

            var options = new FilePickerSaveOptions
            {
                Title = "Экспорт JSON-конфигурации",
                DefaultExtension = "json",
                SuggestedFileName = "devices.json",
                FileTypeChoices = new[]
                {
                new FilePickerFileType("JSON файлы (*.json)") { Patterns = new[] { "*.json" } },
                new FilePickerFileType("Все файлы (*.*)") { Patterns = new[] { "*.*" } }
            }
            };

            var file = await topLevel.StorageProvider.SaveFilePickerAsync(options);
            if (file is not null)
            {
                try
                {
                    string json = JsonSerializer.Serialize(Devices.ToList(), jsonOptions);
                    await using var stream = await file.OpenWriteAsync();
                    await using var writer = new StreamWriter(stream);
                    await writer.WriteAsync(json);
                    StatusMessage = "Файл успешно экспортирован";
                }
                catch (Exception ex)
                {
                    StatusMessage = $"Ошибка экспорта: {ex.Message}";
                }
            }
        }

        [RelayCommand]
        private void AddDevice()
        {
            var newDevice = new DeviceConfig { Ip = "0.0.0.0", Login = "new_login", Password = "pwd" };
            Devices.Add(newDevice);
            SelectedDevice = newDevice;
        }

        [RelayCommand]
        private void DeleteDevice()
        {
            if (SelectedDevice is not null)
            {
                Devices.Remove(SelectedDevice);
                SelectedDevice = null;
            }
        }

        [RelayCommand]
        private void AddParam()
        {
            if (SelectedDevice is null)
                return;

            var newParam = new ParamConfig { Command = "cmd?", Name = "new_param" };
            var updatedList = SelectedDevice.Params.ToList();
            updatedList.Add(newParam);
            SelectedDevice.Params = updatedList;

            var currentDevice = SelectedDevice;
            SelectedDevice = null;
            SelectedDevice = currentDevice;
            SelectedParam = newParam;
        }

        [RelayCommand]
        private void DeleteParam()
        {
            if (SelectedDevice is null || SelectedParam is null)
                return;

            var updatedList = SelectedDevice.Params.ToList();
            updatedList.Remove(SelectedParam);
            SelectedDevice.Params = updatedList;

            var currentDevice = SelectedDevice;
            SelectedDevice = null;
            SelectedDevice = currentDevice;
        }

        [RelayCommand]
        private void AddAnnotation()
        {
            if (SelectedParam is null) return;

            var newItem = new AnnotationItemViewModel("0", "Описание", SyncAnnotationsToDictionary);
            CurrentAnnotations.Add(newItem);
            SyncAnnotationsToDictionary();
            SelectedAnnotation = newItem;
        }

        [RelayCommand]
        private void DeleteAnnotation()
        {
            if (SelectedAnnotation is null) return;

            CurrentAnnotations.Remove(SelectedAnnotation);
            SyncAnnotationsToDictionary();
            SelectedAnnotation = null;
        }
    }
}
