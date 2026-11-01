using FluentAssertions;
using Signal.Server.Data.Dtos;
using Signal.Server.Data.Models;
using Signal.Server.Services;

namespace Signal.Test
{
    public class AuthServiceTests : DbTestBase
    {
        private readonly AuthService authService;

        public AuthServiceTests() => authService = new AuthService(Context);

        [Fact]
        public async Task GetUserAsync_UserExists_ReturnUserDto()
        {
            var user = new User
            {
                UserId = 1,
                Login = "test_user",
                FirstName = "Ivan",
                LastName = "Ivanov",
                SecondName = "Ivanovich", 
                HashedPassword = "pass" 
            };
            Context.Users.Add(user);
            await Context.SaveChangesAsync();

            var result = await authService.GetUserAsync(1);

            result.Should().NotBeNull();
            result!.UserId.Should().Be(user.UserId);
            result.Login.Should().Be(user.Login);
            result.FirstName.Should().Be(user.FirstName);
            result.SecondName.Should().Be(user.SecondName);
            result.LastName.Should().Be(user.LastName);
        }

        [Fact]
        public async Task GetUserAsync_UserDoesNotExist_ReturnNull()
        {
            var result = await authService.GetUserAsync(-1);

            result.Should().BeNull();
        }

        [Fact]
        public async Task UpdateUserAsync_LoginIsAlreadyTaken_ThrowException()
        {
            var existingLogin = "existing_login";
            var user1 = new User
            {
                UserId = 1,
                Login = existingLogin,
                FirstName = "Name1",
                LastName = "Last1",
                SecondName = "Sec1",
                HashedPassword = "pwd"
            };
            var user2 = new User
            {
                UserId = 2,
                Login = "other_login",
                FirstName = "Name2",
                LastName = "Last2",
                SecondName = "Sec2",
                HashedPassword = "pwd"
            };
            Context.Users.AddRange(user1, user2);
            await Context.SaveChangesAsync();

            var updateDto = new UserDto { UserId = 2, Login = existingLogin };

            Func<Task> act = async () => await authService.UpdateUserAsync(2, updateDto);

            await act.Should().ThrowAsync<InvalidOperationException>()
                .WithMessage("Логин уже занят");
        }

        [Fact]
        public void HashPassword_VerifyPassword_ShouldWorkInPair()
        {
            string rawPassword = "123123123";

            string hashedPassword = authService.HashRawPassword(rawPassword);
            bool isVerified = authService.VerifyPassword(rawPassword, hashedPassword);

            hashedPassword.Should().NotBe(rawPassword);
            isVerified.Should().BeTrue();
        }
    }
}