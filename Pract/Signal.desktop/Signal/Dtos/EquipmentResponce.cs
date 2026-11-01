using System.Collections.Generic;

namespace Signal.Dtos
{
    public class EquipmentResponce
    {
        public List<EquipmentDto> Equipment { get; set; } = null!;
        public int TotalEquipment { get; set; }
    }
}
