using Microsoft.EntityFrameworkCore;
using WebApp.Models;

namespace WebApp.Data
{
    public class WebAppContext : DbContext
    {
        public WebAppContext (DbContextOptions<WebAppContext> options, ILogger<WebAppContext> logger)
            : base(options)
        {
            var cs = Database.GetConnectionString();

            logger.Log(LogLevel.Information, cs);

            Database.EnsureCreated();

            Seed();
        }

        public DbSet<Product> Product { get; set; } = default!;

        private void Seed()
        {
            if (!Product.Any())
            {
                // The next two lines to the database
                var products = new List<Product>
                {
                    new Product { Name = "XBOX", Color = "Black"},
                    new Product { Name = "PS5", Color = "White"}
                };

                AddRange(products);

                SaveChanges();
            }
        }
    }
}
