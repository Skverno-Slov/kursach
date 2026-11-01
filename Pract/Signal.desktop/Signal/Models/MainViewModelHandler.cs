using Signal.ViewModels;

namespace Signal.Models
{
    public static class MainViewModelHandler
    {
        static MainWindowViewModel vm;
        
        public static MainWindowViewModel Instance
        {
            get => vm;
            set
            {
                if (vm is null)
                    vm = value;
            } 
        }
    }
}
