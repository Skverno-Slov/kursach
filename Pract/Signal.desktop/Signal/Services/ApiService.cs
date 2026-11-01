using Avalonia.Controls;
using Signal.Dtos;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;

namespace Signal.Services
{
    public class ApiService
    {
        const int ClientTimeoutSeconds = 15;
        const string ApiName = "SignalTrack.Api";
        HttpClient client;

        private static readonly Lazy<ApiService> instance =
        new Lazy<ApiService>(() => new ApiService());

        public static ApiService Instance => instance.Value;

        private ApiService()
        {
            ConfigureClient();
        }

        public async Task<bool> CheckConnectionAsync(Uri testUri)
        {
            try
            {
                var responce = await client.GetAsync(testUri);
                var content = await responce.Content.ReadFromJsonAsync<PingResponce>();
                return content.Service == ApiName;
            }
            catch
            {
                return false;
            }
        }

        public async Task LogutAsync()
        {
            try
            {
                await client.PostAsJsonAsync("api/auth/logout", SessionContext.RefreshToken);
            }
            catch { }
        }

        public async Task<bool> LoginAsync(string loign, string password)
        {
            try
            {
                var request = new LoginRequest()
                {
                    Login = loign,
                    Password = password
                };
                var responce = await client.PostAsJsonAsync("api/auth/login", request);
                var content = await responce.Content.ReadFromJsonAsync<TokenResponse>();
                var result = responce.IsSuccessStatusCode;
                if (result)
                {
                    SessionContext.AccessToken = content.AccessToken;
                    SessionContext.RefreshToken = content.RefreshToken;
                    SessionContext.FullName = $"{content.LastName} {content.FirstName} {content.MiddleName}";
                }
                return result;
            }
            catch
            {
                return false;
            }
        }

        public async Task<bool> RefreshTokensAsync()
        {
            try
            {
                var responce = await client.PostAsJsonAsync("api/auth/refresh", SessionContext.RefreshToken);
                var content = await responce.Content.ReadFromJsonAsync<TokenResponse>();
                var result = responce.IsSuccessStatusCode;
                if (result)
                {
                    SessionContext.AccessToken = content.AccessToken;
                    SessionContext.RefreshToken = content.RefreshToken;
                }
                return result;
            }
            catch
            {
                return false;
            }
        }

        public async Task<UsersResponce?> GetUsersAsync(int page)
        {
            try
            {
                return await client.GetFromJsonAsync<UsersResponce>($"api/auth?page={page}");
            }
            catch
            {
                return null;
            }
        }

        public async Task<UserDto?> GetUserAsync(int id)
        {
            try
            {
                return await client.GetFromJsonAsync<UserDto>($"api/auth/{id}");
            }
            catch
            {
                return null;
            }
        }

        public async Task<bool> DeleteUserAsync(int id)
        {
            try
            {
                var result = await client.DeleteAsync($"api/auth/{id}");
                return result.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        public async Task<bool> UpdateUserAsync(int id, UserDto dto)
        {
            try
            {
                var result = await client.PutAsJsonAsync($"api/auth/{id}", dto);
                return result.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        public async Task<bool> UpdateUserRolesAsync(int id, UpdateUserRolesDto dto)
        {
            try
            {
                var result = await client.PutAsJsonAsync($"api/auth/{id}/roles", dto);
                return result.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        public async Task<bool> ResetUserPasswordAsync(int id, string newPassword)
        {
            try
            {
                var result = await client.PostAsJsonAsync($"api/auth/{id}/reset-password", newPassword);
                return result.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        public async Task<List<string>?> GetRolesAsync()
        {
            try
            {
                return await client.GetFromJsonAsync<List<string>>($"api/auth/roles");
            }
            catch
            {
                return new List<string>();
            }
        }

        public async Task<bool> AddUserAsync(RegisterRequest dto)
        {
            try
            {
                var result = await client.PostAsJsonAsync($"api/auth/register", dto);
                return result.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        void ConfigureClient()
        {
            var address = SettingsService.Load().Address;
            var port = SettingsService.Load().Port;

            var rootHandler = new HttpClientHandler();

            var authHandler = new AuthTokenHandler(this);

            authHandler.InnerHandler = rootHandler;

            client = new HttpClient(authHandler);

            client.BaseAddress = new Uri($"https://{address}:{port}/");
            client.Timeout = TimeSpan.FromSeconds(ClientTimeoutSeconds);
        }

        public async Task<EquipmentResponce?> GetEquipmentAsync(int page)
        {
            try
            {
                return await client.GetFromJsonAsync<EquipmentResponce>($"api/equipment/admin-panel?page={page}");
            }
            catch
            {
                return null;
            }
        }

        public async Task<bool> DeleteEquipmentAsync(int id)
        {
            try
            {
                var result = await client.DeleteAsync($"api/equipment/{id}");
                return result.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        public async Task<bool> UpdateEquipmentAsync(int id, EquipmentDto dto)
        {
            try
            {
                var result = await client.PutAsJsonAsync($"api/equipment/{id}", dto);
                return result.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        public async Task<ReadingTypeResponce?> GetReadingTypesAsync(int page)
        {
            try
            {
                return await client.GetFromJsonAsync<ReadingTypeResponce>($"api/equipment/reading-types?page={page}");
            }
            catch
            {
                return null;
            }
        }

        public async Task<bool> DeleteReadingTypeAsync(int id)
        {
            try
            {
                var result = await client.DeleteAsync($"api/equipment/reading-types/{id}");
                return result.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        public async Task<bool> UpdateReadingTypeAsync(int id, ReadingTypeDto dto)
        {
            try
            {
                var result = await client.PutAsJsonAsync($"api/equipment/reading-types/{id}", dto);
                return result.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }
    }
}
