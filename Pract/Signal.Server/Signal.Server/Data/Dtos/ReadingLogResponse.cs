using System.Text.Json.Serialization;

namespace Signal.Server.Data.Dtos
{
    public record ReadingLogResponse(
        [property: JsonPropertyName("readingName")] string ReadingName,
        [property: JsonPropertyName("readingValue")] string ReadingValue,
        [property: JsonPropertyName("readingUnit")] string? ReadingUnit,
        [property: JsonPropertyName("readingStatus")] string ReadingStatus,
        [property: JsonPropertyName("writeDateTime")] DateTime WriteDateTime
);
}
