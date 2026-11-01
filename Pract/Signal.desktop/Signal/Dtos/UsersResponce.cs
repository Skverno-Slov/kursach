using System.Collections.Generic;

namespace Signal.Dtos
{
    public class UsersResponce
    {
        public List<UserDto> Users { get; set; } = null!;
        public int TotalUsers { get; set; }
    }
}
