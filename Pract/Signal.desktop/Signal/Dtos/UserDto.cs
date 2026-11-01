using System.Collections.Generic;

namespace Signal.Dtos
{
    public class UserDto
    {

        public int UserId { get; set; }
        public string Login { get; set; } = null!;
        public string SecondName { get; set; } = null!;
        public string FirstName { get; set; } = null!;
        public string? LastName { get; set; }
        public List<string> RoleNames { get; set; } = null!;
    }
}

