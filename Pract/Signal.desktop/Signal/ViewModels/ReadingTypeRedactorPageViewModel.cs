using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Signal.Dtos;
using Signal.Models;
using Signal.Services;
using System.Threading.Tasks;

namespace Signal.ViewModels
{
    public partial class ReadingTypeRedactorPageViewModel : ViewModelBase
    {
        private readonly ApiService apiService;
        private readonly ReadingTypeDto editingReadingType;

        [ObservableProperty] 
        string name = string.Empty;
        [ObservableProperty] 
        string identifier = string.Empty;
        [ObservableProperty] 
        string? unit;
        [ObservableProperty] 
        decimal? minValue;
        [ObservableProperty] 
        decimal? maxValue;

        public ReadingTypeRedactorPageViewModel(ApiService service, ReadingTypeDto item)
        {
            apiService = service;
            editingReadingType = item;

            Name = editingReadingType.Name;
            Identifier = editingReadingType.Identifier;
            Unit = editingReadingType.Unit;
            MinValue = editingReadingType.MinValue;
            MaxValue = editingReadingType.MaxValue;
        }

        [RelayCommand]
        void Close()
        {
            MainViewModelHandler.Instance.CurrentPage = new ReadingTypesPage();
        }

        [RelayCommand]
        async Task SaveAsync()
        {
            if (Name != editingReadingType.Name ||
                Identifier != editingReadingType.Identifier ||
                Unit != editingReadingType.Unit ||
                MinValue != editingReadingType.MinValue ||
                MaxValue != editingReadingType.MaxValue)
            {
                var updateDto = new ReadingTypeDto
                {
                    ReadingTypeId = editingReadingType.ReadingTypeId,
                    Name = Name,
                    Identifier = Identifier,
                    Unit = Unit,
                    MinValue = MinValue,
                    MaxValue = MaxValue
                };

                await apiService.UpdateReadingTypeAsync(editingReadingType.ReadingTypeId, updateDto);
            }

            Close();
        }
    }
}
