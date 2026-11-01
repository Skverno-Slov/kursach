using Avalonia;
using Avalonia.Controls;
using Avalonia.Markup.Xaml;
using Signal.Dtos;
using Signal.Services;
using Signal.ViewModels;

namespace Signal;

public partial class ReadingTypeRedactorPage : UserControl
{
    public ReadingTypeRedactorPage(ReadingTypeDto item)
    {
        InitializeComponent();
        DataContext = new ReadingTypeRedactorPageViewModel(ApiService.Instance, item);
    }
}