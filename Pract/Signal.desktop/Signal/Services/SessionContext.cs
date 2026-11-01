using System;
using System.Collections.Generic;
using System.Text;

namespace Signal.Services
{
    public static class SessionContext
    {
        public static string? AccessToken { get; set; }
        public static string? RefreshToken { get; set; }
        public static string? FullName { get; set; }
    }
}
