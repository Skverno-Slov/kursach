using System.Text.Json.Serialization;

namespace Signal.Server.Data.Dtos
{
    public record GraphPointResponse(
        [property: JsonPropertyName("param")] string Param,
        [property: JsonPropertyName("value")] string Value,
        [property: JsonPropertyName("dt")] DateTime Dt
    );
}
