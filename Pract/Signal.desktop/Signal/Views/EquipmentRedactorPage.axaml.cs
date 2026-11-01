using Avalonia;
using Avalonia.Controls;
using Avalonia.Markup.Xaml;
using Signal.Dtos;
using Signal.Services;
using Signal.ViewModels;

namespace Signal;

public partial class EquipmentRedactorPage : UserControl
{
    public EquipmentRedactorPage(EquipmentDto item)
    {
        InitializeComponent();
        DataContext = new EquipmentRedactorPageViewModel(ApiService.Instance, item);
    }
}