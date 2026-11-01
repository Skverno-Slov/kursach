using System.Text.Json.Serialization;

namespace Signal.Server.Data.Dtos
{
    public record TokenResponse(
    [property: JsonPropertyName("accessToken")] string AccessToken,
    [property: JsonPropertyName("refreshToken")] string RefreshToken,
    [property: JsonPropertyName("firstName")] string? FirstName,
    [property: JsonPropertyName("lastName")] string? LastName,
    [property: JsonPropertyName("middleName")] string? MiddleName,
    [property: JsonPropertyName("role")] List<string>? Role
);
}
