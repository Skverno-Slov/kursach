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
    public partial class ReadingTypesPageViewModel(ApiService apiService) : ViewModelBase
    {
        private const int PageSize = 10;
        private readonly ApiService apiService = apiService;

        public ObservableCollection<ReadingTypeDto> ReadingTypes { get; set; } = new();

        [ObservableProperty] 
        int currentPage = 1;
        [ObservableProperty] 
        int totalPages = 1;
        [ObservableProperty] 
        int totalReadingTypes;

        [RelayCommand]
        public async Task LoadReadingTypesAsync()
        {
            var response = await apiService.GetReadingTypesAsync(CurrentPage);
            if (response != null)
            {
                ReadingTypes.Clear();
                foreach (var item in response.ReadingTypes)
                {
                    ReadingTypes.Add(item);
                }
                TotalReadingTypes = response.TotalReadingTypes;
                TotalPages = (int)Math.Ceiling((double)TotalReadingTypes / PageSize);
            }
            NextPageCommand.NotifyCanExecuteChanged();
            PrevPageCommand.NotifyCanExecuteChanged();
        }

        [RelayCommand(CanExecute = nameof(CanGoNextPage))]
        async Task NextPageAsync()
        {
            CurrentPage++;
            await LoadReadingTypesAsync();
        }

        [RelayCommand(CanExecute = nameof(CanGoPrewPage))]
        async Task PrevPageAsync()
        {
            CurrentPage--;
            await LoadReadingTypesAsync();
        }

        [RelayCommand]
        async Task EditReadingTypeAsync(ReadingTypeDto? item)
        {
            if (item is null) 
                return;
            MainViewModelHandler.Instance.CurrentPage = new ReadingTypeRedactorPage(item);
            await LoadReadingTypesAsync();
        }

        [RelayCommand]
        async Task DeleteReadingTypeAsync(ReadingTypeDto? item)
        {
            if (item is null) return;
            var result = await apiService.DeleteReadingTypeAsync(item.ReadingTypeId);
            if (result) await LoadReadingTypesAsync();
        }

        bool CanGoNextPage() => CurrentPage < TotalPages;
        bool CanGoPrewPage() => CurrentPage > 1;
    }
}
