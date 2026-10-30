using Facturas.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// MVC: controllers + Razor views
builder.Services.AddControllersWithViews();

// EF Core with SQL Server; the connection string comes from compose
// (environment variable ConnectionStrings__Facturas).
builder.Services.AddDbContext<FacturasDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("Facturas")));

var app = builder.Build();

// Apply pending migrations on startup. Migrate() is idempotent: it only runs
// migrations that are not yet in the database.
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<FacturasDbContext>();
    db.Database.Migrate();
}

// Default route: /Home/Index -> the invoice form
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
