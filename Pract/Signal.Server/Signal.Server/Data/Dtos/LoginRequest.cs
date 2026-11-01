using System.Text.Json.Serialization;

namespace Signal.Server.Data.Dtos
{
    public record LoginRequest(
    [property: JsonPropertyName("login")] string Login,
    [property: JsonPropertyName("password")] string Password
);
}
