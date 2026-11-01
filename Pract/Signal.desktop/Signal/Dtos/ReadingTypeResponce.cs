using System.Collections.Generic;

namespace Signal.Dtos
{
    public class ReadingTypeResponce
    {
        public List<ReadingTypeDto> ReadingTypes { get; set; } = null!;
        public int TotalReadingTypes { get; set; }
    }
}
