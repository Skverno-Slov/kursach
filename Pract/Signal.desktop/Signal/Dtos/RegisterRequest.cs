namespace Signal.Dtos
{
    public class RegisterRequest
    {
        public string Login { get; set; } = null!;
        public string HashedPassword { get; set; } = null!;
        public string FirstName { get; set; } = null!;
        public string SecondName { get; set; } = null!;
        public string? LastName { get; set; }
        public string? Role { get; set; }
    }
}
