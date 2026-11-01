namespace Signal.Server.Data.Dtos
{
    public class EquipmentResponce
    {
        public List<EquipmentDto> Equipment { get; set; } = null!;
        public int TotalEquipment { get; set; }
    }
}
