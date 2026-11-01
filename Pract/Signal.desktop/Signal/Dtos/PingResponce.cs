using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Signal.Dtos
{
    public record PingResponce(
        [property: JsonPropertyName("service")] string Service
    );
}
