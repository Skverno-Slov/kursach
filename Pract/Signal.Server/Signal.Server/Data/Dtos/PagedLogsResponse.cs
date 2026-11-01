using System.Text.Json.Serialization;

namespace Signal.Server.Data.Dtos
{
    public record PagedLogsResponse(
        [property: JsonPropertyName("logs")] List<ReadingLogResponse> Logs,
        [property: JsonPropertyName("availableIdentifiers")] List<string> AvailableIdentifiers,
        [property: JsonPropertyName("totalCount")] int TotalCount
    );
}
