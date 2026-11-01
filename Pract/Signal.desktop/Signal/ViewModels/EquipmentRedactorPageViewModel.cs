using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Signal.Dtos;
using Signal.Models;
using Signal.Services;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace Signal.ViewModels
{
    public partial class EquipmentRedactorPageViewModel : ViewModelBase
    {
        private readonly ApiService apiService;
        private readonly EquipmentDto editingEquipment;

        [ObservableProperty]
        string name = string.Empty;
        [ObservableProperty]
        string serialNumber = string.Empty;
        [ObservableProperty] 
        string model = string.Empty;
        [ObservableProperty] 
        string statusName = string.Empty;

        public EquipmentRedactorPageViewModel(ApiService service, EquipmentDto item)
        {
            apiService = service;
            editingEquipment = item;

            Name = editingEquipment.Name;
            SerialNumber = editingEquipment.SerialNumber;
            Model = editingEquipment.Model;
            StatusName = editingEquipment.StatusName;
        }

        [RelayCommand]
        void Close()
        {
            MainViewModelHandler.Instance.CurrentPage = new EquipmentPage();
        }

        [RelayCommand]
        async Task SaveAsync()
        {
            if (Name != editingEquipment.Name ||
                SerialNumber != editingEquipment.SerialNumber ||
                Model != editingEquipment.Model ||
                StatusName != editingEquipment.StatusName)
            {
                var updateDto = new EquipmentDto(
                    editingEquipment.EquipmentId,
                    SerialNumber,
                    Name,
                    Model,
                    StatusName
                );

                await apiService.UpdateEquipmentAsync(editingEquipment.EquipmentId, updateDto);
            }

            Close();
        }
    }
}
