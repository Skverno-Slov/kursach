using System.Text.Json.Serialization;

namespace Signal.Server.Data.Dtos
{
    public record RefreshRequest(
    [property: JsonPropertyName("refreshToken")] string RefreshToken
);
}
