using Facturas.Models;
using Microsoft.EntityFrameworkCore;

namespace Facturas.Data;

// The EF Core context: maps Factura entities to the Facturas table.
public class FacturasDbContext : DbContext
{
    public FacturasDbContext(DbContextOptions<FacturasDbContext> options)
        : base(options)
    {
    }

    public DbSet<Factura> Facturas => Set<Factura>();
}
