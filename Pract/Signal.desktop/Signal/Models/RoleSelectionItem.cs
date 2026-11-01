using CommunityToolkit.Mvvm.ComponentModel;
using System;
using System.Collections.Generic;
using System.Text;

namespace Signal.Models
{
    public partial class RoleSelectionItem : ObservableObject
    {
        [ObservableProperty] private bool _isSelected;
        public string RoleName { get; set; } = null!;
    }
}
