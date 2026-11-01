using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Signal.Dtos;
using Signal.Models;
using Signal.Services;
using System;
using System.Collections.ObjectModel;
using System.Threading.Tasks;

namespace Signal.ViewModels
{
    public partial class UsersPageViewModel(ApiService apiService) : ViewModelBase
    {
        const int PageSize = 10;

        private readonly ApiService apiService = apiService;

        public ObservableCollection<UserDto> Users { get; set; } = new();

        [ObservableProperty]
        int currentPage = 1;
        [ObservableProperty]
        int totalPages = 1;
        [ObservableProperty]
        int totalUsers;

        [RelayCommand]
        public async Task LoadUsersAsync()
        {
            var response = await apiService.GetUsersAsync(CurrentPage);

            if (response is not null)
            {
                Users.Clear();
                foreach (var user in response.Users)
                    Users.Add(user);
                TotalUsers = response.TotalUsers;
                TotalPages = (int)Math.Ceiling((double)TotalUsers / PageSize);
            }
            NextPageCommand.NotifyCanExecuteChanged();
            PrevPageCommand.NotifyCanExecuteChanged();
        }

        [RelayCommand(CanExecute = nameof(CanGoNextPage))]
        async Task NextPageAsync()
        {
            CurrentPage++;
            await LoadUsersAsync();
        }

        [RelayCommand(CanExecute = nameof(CanGoPrewPage))]
        async Task PrevPageAsync()
        {
            CurrentPage--;
            await LoadUsersAsync();
        }

        [RelayCommand]
        async Task EditUserAsync(UserDto? user)
        {
            if (user is null) 
                return;
            MainViewModelHandler.Instance.CurrentPage = new UserRedactorPage(user);
            await LoadUsersAsync();
        }

        [RelayCommand]
        async Task DeleteUserAsync(UserDto? user)
        {
            if (user is null) return;
            var result = await apiService.DeleteUserAsync(user.UserId);
            if (result) await LoadUsersAsync();
        }

        [RelayCommand]
        async Task AddUserAsync()
        {
            MainViewModelHandler.Instance.CurrentPage = new UserRedactorPage();
            await LoadUsersAsync();
        }

        bool CanGoNextPage()
            => CurrentPage < TotalPages;

        bool CanGoPrewPage()
            => CurrentPage > 1;
    }
}
