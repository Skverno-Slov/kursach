using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Signal.Dtos;
using Signal.Models;
using Signal.Services;
using Signal.Views;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Signal.ViewModels
{
    public partial class UserRedactorPageViewModel : ViewModelBase
    {
        private readonly ApiService apiService;
        private readonly UserDto? editingUser;

        public ObservableCollection<RoleSelectionItem> Roles { get; } = new();

        [ObservableProperty] 
        string login = string.Empty;
        [ObservableProperty] 
        string secondName = string.Empty;
        [ObservableProperty] 
        string firstName = string.Empty;
        [ObservableProperty]
        string lastName = string.Empty;
        [ObservableProperty]
        string password = string.Empty;
        [ObservableProperty] 
        bool isEditMode;

        public UserRedactorPageViewModel(ApiService service, UserDto? user = null)
        {
            apiService = service;
            editingUser = user;
            IsEditMode = editingUser != null;
        }

        [RelayCommand]
        async Task InitializeAsync()
        {
            var allRoles = await apiService.GetRolesAsync() ?? new List<string>();

            if (IsEditMode && editingUser != null)
            {
                Login = editingUser.Login;
                SecondName = editingUser.SecondName;
                FirstName = editingUser.FirstName;
                LastName = editingUser.LastName ?? string.Empty;

                foreach (var role in allRoles)
                {
                    Roles.Add(new RoleSelectionItem
                    {
                        RoleName = role,
                        IsSelected = editingUser.RoleNames.Contains(role)
                    });
                }
            }
            else
            {
                foreach (var role in allRoles)
                {
                    Roles.Add(new RoleSelectionItem { RoleName = role, IsSelected = false });
                }
            }
        }

        [RelayCommand]
        void Close()
        {
            MainViewModelHandler.Instance.CurrentPage = new UsersPage();
        }

        [RelayCommand]
        async Task SaveAsync()
        {
            if (IsEditMode && editingUser != null)
            {
                if (Login != editingUser.Login || SecondName != editingUser.SecondName ||
                    FirstName != editingUser.FirstName || LastName != editingUser.LastName)
                {
                    var updateDto = new UserDto
                    {
                        UserId = editingUser.UserId,
                        Login = Login,
                        SecondName = SecondName,
                        FirstName = FirstName,
                        LastName = LastName,
                        RoleNames = new List<string>()
                    };
                    await apiService.UpdateUserAsync(editingUser.UserId, updateDto);
                }

                var currentRoles = Roles.Where(r => r.IsSelected).Select(r => r.RoleName).ToList();
                var oldRoles = editingUser.RoleNames;
                if (!currentRoles.SequenceEqual(oldRoles))
                {
                    var rolesDto = new UpdateUserRolesDto { Roles = currentRoles };
                    await apiService.UpdateUserRolesAsync(editingUser.UserId, rolesDto);
                }

                if (!string.IsNullOrWhiteSpace(Password))
                    await apiService.ResetUserPasswordAsync(editingUser.UserId, Password);
            }
            else
            {
                var registerDto = new RegisterRequest
                {
                    Login = Login,
                    HashedPassword = Password, 
                    FirstName = FirstName,
                    SecondName = SecondName, 
                    LastName = LastName,  
                    Role = Roles.FirstOrDefault(r => r.IsSelected)?.RoleName 
                };
                await apiService.AddUserAsync(registerDto);
            }

            Close();
        }
    }
}
