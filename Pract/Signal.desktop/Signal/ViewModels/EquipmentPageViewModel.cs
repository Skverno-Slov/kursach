using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Signal.Dtos;
using Signal.Models;
using Signal.Services;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Text;
using System.Threading.Tasks;

namespace Signal.ViewModels
{
    public partial class EquipmentPageViewModel(ApiService apiService) : ViewModelBase
    {
        private const int PageSize = 10;
        private readonly ApiService apiService = apiService;

        public ObservableCollection<EquipmentDto> Equipment { get; set; } = new();

        [ObservableProperty] 
        int currentPage = 1;
        [ObservableProperty] 
        int totalPages = 1;
        [ObservableProperty] 
        int totalEquipment;

        [RelayCommand]
        public async Task LoadEquipmentAsync()
        {
            var response = await apiService.GetEquipmentAsync(CurrentPage);
            if (response != null)
            {
                Equipment.Clear();
                foreach (var item in response.Equipment)
                {
                    Equipment.Add(item);
                }
                TotalEquipment = response.TotalEquipment;
                TotalPages = (int)Math.Ceiling((double)TotalEquipment / PageSize);
            }
            NextPageCommand.NotifyCanExecuteChanged();
            PrevPageCommand.NotifyCanExecuteChanged();
        }

        [RelayCommand(CanExecute = nameof(CanGoNextPage))]
        async Task NextPageAsync()
        {
            CurrentPage++;
            await LoadEquipmentAsync();
        }

        [RelayCommand(CanExecute = nameof(CanGoPrewPage))]
        async Task PrevPageAsync()
        {
            CurrentPage--;
            await LoadEquipmentAsync();
        }

        [RelayCommand]
        async Task EditEquipmentAsync(EquipmentDto? item)
        {
            if (item is null) 
                return;
            MainViewModelHandler.Instance.CurrentPage = new EquipmentRedactorPage(item);
            await LoadEquipmentAsync();
        }

        [RelayCommand]
        async Task DeleteEquipmentAsync(EquipmentDto? item)
        {
            if (item is null) return;
            var result = await apiService.DeleteEquipmentAsync(item.EquipmentId);
            if (result) await LoadEquipmentAsync();
        }

        bool CanGoNextPage() => CurrentPage < TotalPages;
        bool CanGoPrewPage() => CurrentPage > 1;
    }
}
