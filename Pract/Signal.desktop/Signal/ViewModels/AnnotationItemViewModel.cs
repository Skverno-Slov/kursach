using CommunityToolkit.Mvvm.ComponentModel;
using System;
using System.ComponentModel;

namespace Signal.ViewModels
{
    public partial class AnnotationItemViewModel : ObservableObject
    {
        private readonly Action onChanged;
        [ObservableProperty]
        string key;
        [ObservableProperty]
        string value;

        public AnnotationItemViewModel(string key, string value, Action onChanged)
        {
            this.key = key;
            this.value = value;
            this.onChanged = onChanged;
        }

        protected override void OnPropertyChanged(PropertyChangedEventArgs e)
        {
            base.OnPropertyChanged(e);
            if (e.PropertyName == nameof(Key) || e.PropertyName == nameof(Value))
                onChanged?.Invoke();
        }
    }
}
