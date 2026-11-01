using System.Text.Json.Serialization;

namespace Signal.Server.Data.Dtos
{
    public record LatestReadingResponse(
    [property: JsonPropertyName("serialNumber")] string? SerialNumber,
    [property: JsonPropertyName("metricKey")] string MetricKey,
    [property: JsonPropertyName("label")] string Label,
    [property: JsonPropertyName("value")] string Value,
    [property: JsonPropertyName("unit")] string? Unit,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("datetime")] DateTime? Datetime,
    [property: JsonPropertyName("minValue")] decimal? MinValue, 
    [property: JsonPropertyName("maxValue")] decimal? MaxValue  
);
}
