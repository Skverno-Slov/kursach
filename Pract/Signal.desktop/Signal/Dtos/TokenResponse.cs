using System;
using System.Collections.Generic;
using System.Text;
using System.Text.Json.Serialization;

namespace Signal.Dtos
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
