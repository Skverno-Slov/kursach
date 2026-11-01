using System.Text.Json.Serialization;

namespace Signal.Server.Data.Dtos
{
    public record EquipmentDto(
        [property: JsonPropertyName("equipmentId")] int EquipmentId,
        [property: JsonPropertyName("serialNumber")] string SerialNumber,
        [property: JsonPropertyName("name")] string Name,
        [property: JsonPropertyName("model")] string Model,
        [property: JsonPropertyName("statusName")] string StatusName
);
}
