namespace Signal.Server.Data.Dtos
{
    public class ReadingTypeResponce
    {
        public List<ReadingTypeDto> ReadingTypes { get; set; } = null!;
        public int TotalReadingTypes { get; set; }
    }
}
