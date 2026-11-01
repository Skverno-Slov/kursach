namespace Signal.Server.Data.Dtos
{
    public class CreateReadingLogDto
    {
        public string IpAddress { get; set; } = null!;
        public string ReadingTypeIdentifier { get; set; } = null!;
        public string Value { get; set; } = null!;
    }
}
