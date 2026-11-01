using Avalonia.Controls;
using Signal.Models;
using Signal.ViewModels;

namespace Signal.Views
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            var vm = new MainWindowViewModel(this);
            DataContext = vm;
            MainViewModelHandler.Instance = vm;
        }
    }
}