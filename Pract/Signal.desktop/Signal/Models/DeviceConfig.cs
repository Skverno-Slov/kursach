using System.Collections.Generic;

namespace Signal.Models
{
    public class DeviceConfig
    {
        public string Ip { get; set; } = string.Empty;
        public string? Login { get; set; }
        public string? Password { get; set; }
        public List<ParamConfig> Params { get; set; } = new();
    }
}
