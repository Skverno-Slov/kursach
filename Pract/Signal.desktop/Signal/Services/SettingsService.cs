using Signal.Models;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.Json;

namespace Signal.Services
{
    public static class SettingsService
    {
        private static readonly string AppFolderName = "signal";
        private static readonly string FileName = "network_settings.json";

        private static readonly string FolderPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            AppFolderName
        );

        private static readonly string FilePath = Path.Combine(FolderPath, FileName);

        public static void Save(NetworkSettings settings)
        {
            try
            {
                Directory.CreateDirectory(FolderPath);
                string json = JsonSerializer.Serialize(settings, new JsonSerializerOptions { WriteIndented = true });
                File.WriteAllText(FilePath, json);
            }
            catch (Exception ex)
            {
            }
        }
        public static NetworkSettings Load()
        {
            try
            {
                if (!File.Exists(FilePath))
                    return new NetworkSettings();

                string json = File.ReadAllText(FilePath);
                return JsonSerializer.Deserialize<NetworkSettings>(json) ?? new NetworkSettings();
            }
            catch (Exception ex)
            {
                return new NetworkSettings(); 
            }
        }
    }
}
