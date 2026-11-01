using Avalonia;
using Avalonia.Controls;
using Avalonia.Markup.Xaml;
using Signal.ViewModels;

namespace Signal.Views
{

    public partial class LoginWindow : Window
    {
        public LoginWindow()
        {
            InitializeComponent();
            DataContext = new LoginWindowViewModel(this);
        }
    }
}