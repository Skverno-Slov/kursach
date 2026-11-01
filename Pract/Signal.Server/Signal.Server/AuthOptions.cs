using Microsoft.IdentityModel.Tokens;
using System.Text;

namespace Signal.Server
{
    public static class AuthOptions
    {
        public const string secretKey = "GkHdkhDHkdkHdkHKDhkDHkDHkhdkdhjF";
        public static byte[] keyBytes = Encoding.UTF8.GetBytes(secretKey);
        public const string validIssuer = "SignalTrack";
        public const string validAudience = "SignalTrack";
        public const string algorithm = SecurityAlgorithms.HmacSha256;
        public const int workFactor = 11;
    }
}
