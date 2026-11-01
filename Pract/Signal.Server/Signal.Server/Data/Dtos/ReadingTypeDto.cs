namespace Signal.Server.Data.Dtos
{
    public class ReadingTypeDto
    {
        public int ReadingTypeId { get; set; }
        public string Name { get; set; } = null!;
        public string Identifier { get; set; } = null!;
        public string? Unit { get; set; }
        public decimal? MinValue { get; set; }
        public decimal? MaxValue { get; set; }
    }
}
