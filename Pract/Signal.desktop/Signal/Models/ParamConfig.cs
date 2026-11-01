using System.Collections.Generic;

namespace Signal.Models
{
    public class ParamConfig
    {
        public string Command { get; set; } = string.Empty;
        public string Name { get; set; } = null!;
        public string? Uncorrect { get; set; }
        public Dictionary<string, string>? Annotations { get; set; }
    }
}
