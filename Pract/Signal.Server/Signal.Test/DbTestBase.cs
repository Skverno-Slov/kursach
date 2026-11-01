using Microsoft.EntityFrameworkCore;
using Signal.Server.Data;

namespace Signal.Test
{
    public abstract class DbTestBase : IDisposable
    {
        protected ApplicationDbContext Context { get; }

        protected DbTestBase()
        {
            var options = new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
                .Options;

            Context = new TestApplicationDbContext(options);
            Context.Database.EnsureCreated();
        }

        public void Dispose()
        {
            Context.Database.EnsureDeleted();
            Context.Dispose();
        }
    }
}
