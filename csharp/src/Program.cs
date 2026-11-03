using Facturas.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// MVC: controllers + Razor views
builder.Services.AddControllersWithViews();

// Week 2 practice records are isolated per browser session, not stored with invoices.
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.Cookie.HttpOnly = true;
    options.Cookie.SameSite = SameSiteMode.Lax;
    options.Cookie.IsEssential = true;
});

// EF Core with SQL Server; the connection string comes from compose
// (environment variable ConnectionStrings__Facturas).
builder.Services.AddDbContext<FacturasDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("Facturas")));

var app = builder.Build();

// Apply pending migrations on startup. Migrate() is idempotent: it only runs
// migrations that are not yet in the database. PracticeOnly is a narrow opt-in
// for the database-independent Week 2 demos; normal compose behavior is unchanged.
if (!builder.Configuration.GetValue<bool>("PracticeOnly"))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<FacturasDbContext>();
    db.Database.Migrate();
}

app.UseSession();

// Default route: /Home/Index -> the invoice form
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
